locals {
  enabled = var.enabled
  name    = var.name
}

################################################################################
# Dashboard
################################################################################

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = local.name
  dashboard_body = var.dashboard_body

  lifecycle {
    enabled = local.enabled
  }
}
