locals {
  enabled = var.enabled
  name    = var.name

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# Database
################################################################################

resource "aws_timestreamwrite_database" "this" {
  database_name = local.name
  kms_key_id    = var.kms_key_id

  tags = merge(local.tags, { Name = local.name })

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# Tables
################################################################################

resource "aws_timestreamwrite_table" "this" {
  for_each = { for k, v in var.tables : k => v if local.enabled }

  database_name = aws_timestreamwrite_database.this.database_name
  table_name    = each.value.table_name

  retention_properties {
    memory_store_retention_period_in_hours  = coalesce(each.value.memory_store_retention_hours, var.default_memory_store_retention_hours)
    magnetic_store_retention_period_in_days = coalesce(each.value.magnetic_store_retention_days, var.default_magnetic_store_retention_days)
  }

  dynamic "magnetic_store_write_properties" {
    for_each = each.value.magnetic_store_write_properties != null ? [each.value.magnetic_store_write_properties] : (var.enable_magnetic_store_writes ? [{ enable_magnetic_store_writes = true, magnetic_store_rejected_data_location = null }] : [])

    content {
      enable_magnetic_store_writes = magnetic_store_write_properties.value.enable_magnetic_store_writes

      dynamic "magnetic_store_rejected_data_location" {
        for_each = magnetic_store_write_properties.value.magnetic_store_rejected_data_location != null ? [magnetic_store_write_properties.value.magnetic_store_rejected_data_location] : []

        content {
          s3_configuration {
            bucket_name       = magnetic_store_rejected_data_location.value.s3_bucket_name
            encryption_option = magnetic_store_rejected_data_location.value.s3_encryption_option
            kms_key_id        = magnetic_store_rejected_data_location.value.s3_kms_key_id
            object_key_prefix = magnetic_store_rejected_data_location.value.s3_object_key_prefix
          }
        }
      }
    }
  }

  dynamic "schema" {
    for_each = each.value.schema != null ? [each.value.schema] : []

    content {
      dynamic "composite_partition_key" {
        for_each = schema.value.composite_partition_key != null ? [schema.value.composite_partition_key] : []

        content {
          enforcement_in_record = composite_partition_key.value.enforcement_in_record
          name                  = composite_partition_key.value.name
          type                  = composite_partition_key.value.type
        }
      }
    }
  }

  tags = merge(local.tags, each.value.tags)
}
