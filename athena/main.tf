locals {
  enabled = var.enabled
  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# Workgroup
################################################################################

resource "aws_athena_workgroup" "this" {
  name          = var.name
  description   = var.workgroup_description
  state         = var.workgroup_state
  force_destroy = var.force_destroy

  configuration {
    enforce_workgroup_configuration    = var.enforce_workgroup_configuration
    publish_cloudwatch_metrics_enabled = var.publish_cloudwatch_metrics_enabled
    bytes_scanned_cutoff_per_query     = var.bytes_scanned_cutoff_per_query
    requester_pays_enabled             = var.requester_pays_enabled
    execution_role                     = var.execution_role

    dynamic "engine_version" {
      for_each = var.engine_version != null ? [var.engine_version] : []

      content {
        selected_engine_version = engine_version.value
      }
    }

    result_configuration {
      output_location = var.result_output_location

      dynamic "encryption_configuration" {
        for_each = var.result_encryption_option != null ? [1] : []

        content {
          encryption_option = var.result_encryption_option
          kms_key_arn       = var.result_encryption_kms_key_arn
        }
      }

      dynamic "acl_configuration" {
        for_each = var.result_acl_s3_owner != null ? [1] : []

        content {
          s3_acl_option = var.result_acl_s3_owner
        }
      }

      expected_bucket_owner = var.result_expected_bucket_owner
    }
  }

  tags = merge(local.tags, { Name = var.name })

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# Named Queries
################################################################################

resource "aws_athena_named_query" "this" {
  for_each = local.enabled ? var.named_queries : {}

  name        = each.key
  workgroup   = aws_athena_workgroup.this.id
  database    = each.value.database
  query       = each.value.query
  description = try(each.value.description, null)
}

################################################################################
# Data Catalog
################################################################################

resource "aws_athena_data_catalog" "this" {
  for_each = local.enabled ? var.data_catalogs : {}

  name        = each.key
  description = try(each.value.description, "Athena data catalog")
  type        = each.value.type
  parameters  = each.value.parameters

  tags = merge(local.tags, { Name = each.key })
}

################################################################################
# Database
################################################################################

resource "aws_athena_database" "this" {
  for_each = local.enabled ? var.databases : {}

  name    = each.key
  bucket  = try(each.value.bucket, null)
  comment = try(each.value.comment, null)

  dynamic "acl_configuration" {
    for_each = try([each.value.acl_configuration], [])

    content {
      s3_acl_option = acl_configuration.value.s3_acl_option
    }
  }

  dynamic "encryption_configuration" {
    for_each = try([each.value.encryption_configuration], [])

    content {
      encryption_option = encryption_configuration.value.encryption_option
      kms_key           = try(encryption_configuration.value.kms_key, null)
    }
  }

  expected_bucket_owner = try(each.value.expected_bucket_owner, null)
  force_destroy         = try(each.value.force_destroy, false)
  properties            = try(each.value.properties, null)
}
