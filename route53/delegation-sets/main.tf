locals {
  enabled = var.enabled
}

resource "aws_route53_delegation_set" "default" {
  for_each = { for k, v in var.delegation_sets : k => v if local.enabled }

  reference_name = each.value.reference_name
}
