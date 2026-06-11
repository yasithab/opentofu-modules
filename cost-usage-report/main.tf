data "aws_partition" "current" {}

data "aws_region" "current" {}

locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
    Region    = data.aws_region.current.region
  })

  # Fall back to "" (not null): when the module is disabled the bucket
  # resource doesn't exist, and a null here breaks string interpolation in
  # the bucket-policy document during plan.
  s3_bucket_name = var.create_s3_bucket ? try(aws_s3_bucket.this.id, "") : var.s3_bucket_name

  # Defaults to the previous single hardcoded rule (Glacier transition + expiration)
  s3_lifecycle_rules = var.s3_lifecycle_rules != null ? var.s3_lifecycle_rules : [
    {
      id     = "cur-lifecycle"
      status = "Enabled"
      prefix = null
      transitions = [
        {
          days          = var.s3_lifecycle_glacier_transition_days
          storage_class = "GLACIER"
        }
      ]
      expiration_days = var.s3_lifecycle_expiration_days
    }
  ]
}

################################################################################
# S3 Bucket for Report Delivery
################################################################################

resource "aws_s3_bucket" "this" {
  bucket        = var.s3_bucket_name
  force_destroy = var.s3_bucket_force_destroy

  tags = merge(local.tags, { Name = var.s3_bucket_name })

  lifecycle {
    enabled = local.enabled && var.create_s3_bucket
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }

  lifecycle {
    enabled = local.enabled && var.create_s3_bucket
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.s3_sse_algorithm
      kms_master_key_id = var.s3_kms_key_id
    }
    bucket_key_enabled = var.s3_bucket_key_enabled
  }

  lifecycle {
    enabled = local.enabled && var.create_s3_bucket
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  lifecycle {
    enabled = local.enabled && var.create_s3_bucket
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = local.s3_lifecycle_rules

    content {
      id     = rule.value.id
      status = rule.value.status

      dynamic "filter" {
        for_each = rule.value.prefix != null ? [rule.value.prefix] : []

        content {
          prefix = filter.value
        }
      }

      dynamic "transition" {
        for_each = rule.value.transitions

        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration_days != null ? [rule.value.expiration_days] : []

        content {
          days = expiration.value
        }
      }
    }
  }

  lifecycle {
    enabled = local.enabled && var.create_s3_bucket && var.enable_s3_lifecycle
  }
}

################################################################################
# S3 Bucket Policy for CUR
################################################################################

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "cur_s3" {
  statement {
    sid    = "AllowCURGetBucketAcl"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["billingreports.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl", "s3:GetBucketPolicy"]
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${local.s3_bucket_name}"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cur:us-east-1:${data.aws_caller_identity.current.account_id}:definition/*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "AllowCURPutObject"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["billingreports.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${local.s3_bucket_name}/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cur:us-east-1:${data.aws_caller_identity.current.account_id}:definition/*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = local.s3_bucket_name
  policy = data.aws_iam_policy_document.cur_s3.json

  lifecycle {
    enabled = local.enabled && var.create_s3_bucket_policy
  }

  depends_on = [aws_s3_bucket_public_access_block.this]
}

################################################################################
# Cost and Usage Report Definition
################################################################################

resource "aws_cur_report_definition" "this" {
  report_name                = var.report_name != null ? var.report_name : var.name
  time_unit                  = var.time_unit
  format                     = var.format
  compression                = var.compression
  additional_schema_elements = var.additional_schema_elements
  s3_bucket                  = local.s3_bucket_name
  s3_region                  = var.s3_region
  s3_prefix                  = var.s3_prefix
  additional_artifacts       = var.additional_artifacts
  refresh_closed_reports     = var.refresh_closed_reports
  report_versioning          = var.report_versioning

  tags = local.tags

  lifecycle {
    enabled = local.enabled

    precondition {
      condition     = data.aws_region.current.region == "us-east-1"
      error_message = "aws_cur_report_definition is only supported in us-east-1; configure the AWS provider for this module to use the us-east-1 region. Current region: ${data.aws_region.current.region}."
    }
  }

  depends_on = [aws_s3_bucket_policy.this]
}
