locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  artifact_s3_location = var.create_artifact_bucket ? "s3://${aws_s3_bucket.artifacts.id}" : "s3://${var.artifact_s3_bucket_name}"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

################################################################################
# Canary
################################################################################

resource "aws_synthetics_canary" "this" {
  for_each = local.enabled ? var.canaries : {}

  name                 = each.value.name
  artifact_s3_location = try(each.value.artifact_s3_location, "${local.artifact_s3_location}/${each.value.name}")
  execution_role_arn   = var.create_iam_role ? aws_iam_role.this.arn : each.value.execution_role_arn
  handler              = each.value.handler
  runtime_version      = each.value.runtime_version
  zip_file             = try(each.value.zip_file, null)
  s3_bucket            = try(each.value.s3_bucket, null)
  s3_key               = try(each.value.s3_key, null)
  s3_version           = try(each.value.s3_version, null)
  start_canary         = try(each.value.start_canary, true)
  delete_lambda        = try(each.value.delete_lambda, true)

  success_retention_period = try(each.value.success_retention_period, var.default_success_retention_period)
  failure_retention_period = try(each.value.failure_retention_period, var.default_failure_retention_period)

  schedule {
    expression          = each.value.schedule_expression
    duration_in_seconds = try(each.value.schedule_duration_in_seconds, null)
  }

  dynamic "run_config" {
    for_each = try(each.value.run_config, null) != null ? [each.value.run_config] : []

    content {
      timeout_in_seconds    = try(run_config.value.timeout_in_seconds, 60)
      memory_in_mb          = try(run_config.value.memory_in_mb, null)
      active_tracing        = try(run_config.value.active_tracing, false)
      environment_variables = try(run_config.value.environment_variables, null)
    }
  }

  dynamic "vpc_config" {
    for_each = try(each.value.vpc_config, null) != null ? [each.value.vpc_config] : []

    content {
      security_group_ids = vpc_config.value.security_group_ids
      subnet_ids         = vpc_config.value.subnet_ids
    }
  }

  dynamic "artifact_config" {
    for_each = try(each.value.artifact_config, null) != null ? [each.value.artifact_config] : []

    content {
      s3_encryption {
        encryption_mode = try(artifact_config.value.encryption_mode, "SSE_S3")
        kms_key_arn     = try(artifact_config.value.kms_key_arn, null)
      }
    }
  }

  tags = local.tags
}

################################################################################
# Canary Groups
################################################################################

resource "aws_synthetics_group" "this" {
  for_each = local.enabled ? var.canary_groups : {}

  name = each.key

  tags = local.tags
}

resource "aws_synthetics_group_association" "this" {
  for_each = local.enabled ? {
    for pair in flatten([
      for group_name, group_config in var.canary_groups : [
        for canary_key in try(group_config.canary_keys, []) : {
          key        = "${group_name}-${canary_key}"
          group_name = group_name
          canary_arn = aws_synthetics_canary.this[canary_key].arn
        }
      ]
    ]) : pair.key => pair
  } : {}

  group_name = aws_synthetics_group.this[each.value.group_name].name
  canary_arn = each.value.canary_arn
}

################################################################################
# S3 Artifact Bucket
################################################################################

resource "aws_s3_bucket" "artifacts" {
  bucket        = var.artifact_s3_bucket_use_name_prefix ? null : coalesce(var.artifact_s3_bucket_name, "synthetics-artifacts-${var.name}")
  bucket_prefix = var.artifact_s3_bucket_use_name_prefix ? "${coalesce(var.artifact_s3_bucket_name, "synthetics-artifacts-${var.name}")}-" : null
  force_destroy = var.artifact_s3_bucket_force_destroy

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_artifact_bucket
  }
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }

  lifecycle {
    enabled = local.enabled && var.create_artifact_bucket
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.artifact_s3_kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.artifact_s3_kms_key_arn
    }
    bucket_key_enabled = var.artifact_s3_kms_key_arn != null
  }

  lifecycle {
    enabled = local.enabled && var.create_artifact_bucket
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  lifecycle {
    enabled = local.enabled && var.create_artifact_bucket
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    id     = "artifact-expiration"
    status = "Enabled"

    expiration {
      days = var.artifact_s3_expiration_days
    }
  }

  lifecycle {
    enabled = local.enabled && var.create_artifact_bucket && var.artifact_s3_expiration_days > 0
  }
}

################################################################################
# IAM Role
################################################################################

resource "aws_iam_role" "this" {
  name        = var.iam_role_use_name_prefix ? null : coalesce(var.iam_role_name, "synthetics-${var.name}")
  name_prefix = var.iam_role_use_name_prefix ? "${coalesce(var.iam_role_name, "synthetics-${var.name}")}-" : null
  path        = var.iam_role_path
  description = "IAM role for CloudWatch Synthetics canaries"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_iam_role
  }
}

resource "aws_iam_role_policy" "canary" {
  name = "synthetics-canary-execution"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
        ]
        Resource = "${var.create_artifact_bucket ? aws_s3_bucket.artifacts.arn : "arn:${data.aws_partition.current.partition}:s3:::${var.artifact_s3_bucket_name}"}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
        ]
        Resource = var.create_artifact_bucket ? aws_s3_bucket.artifacts.arn : "arn:${data.aws_partition.current.partition}:s3:::${var.artifact_s3_bucket_name}"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
        ]
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/cwsyn-*"
      },
      {
        Effect   = "Allow"
        Action   = "xray:PutTraceSegments"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "CloudWatchSynthetics"
          }
        }
      }
    ]
  })

  lifecycle {
    enabled = local.enabled && var.create_iam_role
  }
}

resource "aws_iam_role_policy" "vpc" {
  name = "synthetics-vpc-access"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
        ]
        Resource = "*"
      }
    ]
  })

  lifecycle {
    enabled = local.enabled && var.create_iam_role && var.enable_vpc_policy
  }
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = local.enabled && var.create_iam_role ? var.iam_role_policy_arns : {}

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

################################################################################
# CloudWatch Alarms
################################################################################

resource "aws_cloudwatch_metric_alarm" "canary" {
  for_each = local.enabled ? {
    for k, v in var.canaries : k => v if try(v.create_alarm, var.create_canary_alarms)
  } : {}

  alarm_name          = try(each.value.alarm_name, "synthetics-${each.value.name}-failed")
  alarm_description   = try(each.value.alarm_description, "Synthetics canary ${each.value.name} is failing")
  comparison_operator = try(each.value.alarm_comparison_operator, "LessThanThreshold")
  evaluation_periods  = try(each.value.alarm_evaluation_periods, 1)
  metric_name         = "SuccessPercent"
  namespace           = "CloudWatchSynthetics"
  period              = try(each.value.alarm_period, 300)
  statistic           = "Average"
  threshold           = try(each.value.alarm_threshold, 100)
  treat_missing_data  = try(each.value.alarm_treat_missing_data, "breaching")

  dimensions = {
    CanaryName = each.value.name
  }

  alarm_actions             = try(each.value.alarm_actions, var.default_alarm_actions)
  ok_actions                = try(each.value.ok_actions, var.default_ok_actions)
  insufficient_data_actions = try(each.value.insufficient_data_actions, [])

  tags = local.tags
}

################################################################################
