locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

resource "aws_route53_zone" "default" {
  for_each = { for k, v in var.zones : k => v if local.enabled }

  name                        = lookup(each.value, "domain_name", each.key)
  comment                     = lookup(each.value, "comment", null)
  force_destroy               = lookup(each.value, "force_destroy", false)
  enable_accelerated_recovery = lookup(each.value, "enable_accelerated_recovery", null)

  delegation_set_id = lookup(each.value, "delegation_set_id", null)

  dynamic "vpc" {
    for_each = try(tolist(lookup(each.value, "vpc", [])), [lookup(each.value, "vpc", {})])

    content {
      vpc_id     = vpc.value.vpc_id
      vpc_region = lookup(vpc.value, "vpc_region", null)
    }
  }

  # Prevent the deletion of associated VPCs after the initial creation. See documentation on aws_route53_zone_association for details
  lifecycle {
    ignore_changes = [vpc]
  }

  tags = merge(local.tags, lookup(each.value, "tags", {}))
}
