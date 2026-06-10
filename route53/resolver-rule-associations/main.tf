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
  name                 = each.value.name
  rule_type            = each.value.rule_type
  resolver_endpoint_id = each.value.resolver_endpoint_id

  dynamic "target_ip" {
    for_each = each.value.target_ips

    content {
      ip       = target_ip.value.ip
      ipv6     = target_ip.value.ipv6
      port     = target_ip.value.port
      protocol = target_ip.value.protocol
    }
  }

  tags = merge(local.tags, { Name = coalesce(each.value.name, each.key) })
}

################################################################################
# Resolver Rule Association(s)
################################################################################

resource "aws_route53_resolver_rule_association" "default" {
  for_each = { for k, v in var.resolver_rule_associations : k => v if local.enabled }

  name             = each.value.name
  vpc_id           = coalesce(each.value.vpc_id, var.vpc_id)
  resolver_rule_id = each.value.resolver_rule_id != null ? each.value.resolver_rule_id : aws_route53_resolver_rule.default[each.key].id
}
