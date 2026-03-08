################################################################################
# Metric Stream
################################################################################

locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

resource "aws_cloudwatch_metric_stream" "this" {
  name          = var.name_prefix != null ? null : var.name
  name_prefix   = var.name_prefix
  firehose_arn  = var.firehose_arn
  role_arn      = var.role_arn
  output_format = var.output_format

  precondition {
    condition     = var.name != null || var.name_prefix != null
    error_message = "At least one of name or name_prefix must be specified."
  }

  precondition {
    condition     = length(var.include_filter) == 0 || length(var.exclude_filter) == 0
    error_message = "Only one of include_filter or exclude_filter can be specified, not both."
  }

  dynamic "exclude_filter" {
    for_each = var.exclude_filter

    content {
      namespace    = exclude_filter.key
      metric_names = try(exclude_filter.value.metric_names, [])
    }
  }

  dynamic "include_filter" {
    for_each = var.include_filter

    content {
      namespace    = include_filter.key
      metric_names = try(include_filter.value.metric_names, [])
    }
  }

  dynamic "statistics_configuration" {
    for_each = var.statistics_configuration

    content {
      additional_statistics = statistics_configuration.value.additional_statistics

      dynamic "include_metric" {
        for_each = try(statistics_configuration.value.include_metric, [])

        content {
          metric_name = include_metric.value.metric_name
          namespace   = include_metric.value.namespace
        }
      }
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}
