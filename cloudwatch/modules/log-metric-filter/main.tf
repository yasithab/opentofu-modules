################################################################################
# Log Metric Filter
################################################################################

locals {
  enabled = var.enabled
}

resource "aws_cloudwatch_log_metric_filter" "this" {
  name           = var.name
  pattern        = var.pattern
  log_group_name = var.log_group_name

  metric_transformation {
    name          = var.metric_transformation_name
    namespace     = var.metric_transformation_namespace
    value         = var.metric_transformation_value
    default_value = var.metric_transformation_default_value
    unit          = var.metric_transformation_unit
    dimensions    = var.metric_transformation_dimensions
  }

  lifecycle {
    enabled = local.enabled
  }
}
