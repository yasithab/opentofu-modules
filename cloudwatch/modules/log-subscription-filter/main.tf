################################################################################
# Log Subscription Filter
################################################################################

locals {
  enabled = var.enabled
}

resource "aws_cloudwatch_log_subscription_filter" "this" {
  name            = var.name
  destination_arn = var.destination_arn
  filter_pattern  = var.filter_pattern
  log_group_name  = var.log_group_name
  role_arn        = var.role_arn
  distribution    = var.distribution

  lifecycle {
    enabled = local.enabled
  }
}
