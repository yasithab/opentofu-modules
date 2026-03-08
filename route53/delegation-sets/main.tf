locals {
  enabled = var.enabled
}

resource "aws_route53_delegation_set" "default" {
  for_each = local.enabled ? var.delegation_sets : tomap({})

  reference_name = lookup(each.value, "reference_name", null)
}
