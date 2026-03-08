################################################################################
# Query Definition
################################################################################

locals {
  enabled = var.enabled
}

resource "aws_cloudwatch_query_definition" "this" {
  name            = var.name
  query_string    = var.query_string
  log_group_names = var.log_group_names

  lifecycle {
    enabled = local.enabled
  }
}
