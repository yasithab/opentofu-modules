################################################################################
# Log Group
################################################################################

locals {
  enabled = var.enabled
  name    = var.name

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  create_log_streams            = local.enabled && var.create_log_streams
  create_data_protection_policy = local.enabled && var.data_protection_policy_document != null
  create_anomaly_detector       = local.enabled && var.anomaly_detector != null
}

resource "aws_cloudwatch_log_group" "this" {
  name              = var.use_name_prefix ? null : local.name
  name_prefix       = var.use_name_prefix ? "${local.name}-" : null
  retention_in_days = var.retention_in_days
  kms_key_id        = var.kms_key_id
  log_group_class   = var.log_group_class
  skip_destroy      = var.skip_destroy

  deletion_protection_enabled = var.deletion_protection_enabled

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# Log Stream(s)
################################################################################

resource "aws_cloudwatch_log_stream" "this" {
  for_each = { for k, v in var.log_streams : k => v if local.create_log_streams }

  name           = each.value.name != null ? each.value.name : each.key
  log_group_name = aws_cloudwatch_log_group.this.name
}

################################################################################
# Data Protection Policy
################################################################################

resource "aws_cloudwatch_log_data_protection_policy" "this" {
  log_group_name  = aws_cloudwatch_log_group.this.name
  policy_document = var.data_protection_policy_document

  lifecycle {
    enabled = local.create_data_protection_policy
  }
}

################################################################################
# Log Anomaly Detector
################################################################################

resource "aws_cloudwatch_log_anomaly_detector" "this" {
  detector_name           = try(coalesce(var.anomaly_detector.detector_name, "${local.name}-anomaly-detector"), null)
  log_group_arn_list      = [aws_cloudwatch_log_group.this.arn]
  evaluation_frequency    = try(var.anomaly_detector.evaluation_frequency, null)
  filter_pattern          = try(var.anomaly_detector.filter_pattern, null)
  anomaly_visibility_time = try(var.anomaly_detector.anomaly_visibility_time, null)
  kms_key_id              = try(var.anomaly_detector.kms_key_id, null)
  enabled                 = try(var.anomaly_detector.enabled, true)

  tags = local.tags

  lifecycle {
    enabled = local.create_anomaly_detector
  }
}
