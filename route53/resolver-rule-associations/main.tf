locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# Resolver Rule(s)
################################################################################

resource "aws_route53_resolver_rule" "default" {
  for_each = { for k, v in var.resolver_rules : k => v if local.enabled }

  domain_name          = each.value.domain_name
  name                 = try(each.value.name, null)
  rule_type            = each.value.rule_type
  resolver_endpoint_id = try(each.value.resolver_endpoint_id, null)

  dynamic "target_ip" {
    for_each = try(each.value.target_ips, [])

    content {
      ip       = try(target_ip.value.ip, null)
      ipv6     = try(target_ip.value.ipv6, null)
      port     = try(target_ip.value.port, 53)
      protocol = try(target_ip.value.protocol, "Do53")
    }
  }

  tags = merge(local.tags, { Name = try(each.value.name, each.key) })
}

################################################################################
# Resolver Rule Association(s)
################################################################################

resource "aws_route53_resolver_rule_association" "default" {
  for_each = { for k, v in var.resolver_rule_associations : k => v if local.enabled }

  name             = try(each.value.name, null)
  vpc_id           = try(each.value.vpc_id, var.vpc_id)
  resolver_rule_id = try(each.value.resolver_rule_id, aws_route53_resolver_rule.default[each.key].id)
}
