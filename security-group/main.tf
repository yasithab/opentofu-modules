###############################################################################################################
# Locals
###############################################################################################################

locals {
  enabled = var.enabled
  name    = var.name

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
    Region    = data.aws_region.current.region
  })

  # Create a security group only when we are not managing rules on an existing one
  create_sg             = local.enabled && var.security_group_id == null
  create_sg_name        = local.create_sg && !var.use_name_prefix
  create_sg_name_prefix = local.create_sg && var.use_name_prefix

  this_sg_id = var.security_group_id != null ? var.security_group_id : (
    local.enabled ? coalesce(try(aws_security_group.this.id, null), try(aws_security_group.this_name_prefix.id, null), "") : ""
  )
}

###############################################################################################################
# Security group with name
###############################################################################################################

resource "aws_security_group" "this" {
  name                   = local.name
  description            = var.description
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = var.revoke_rules_on_delete

  tags = merge(local.tags, {
    "Name" = format("%s", local.name)
  })

  timeouts {
    create = var.create_timeout
    delete = var.delete_timeout
  }

  lifecycle {
    enabled = local.create_sg_name
  }
}

###############################################################################################################
# Security group with name_prefix
###############################################################################################################

resource "aws_security_group" "this_name_prefix" {
  name_prefix            = "${local.name}-"
  description            = var.description
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = var.revoke_rules_on_delete

  tags = merge(local.tags, {
    "Name" = format("%s", local.name)
  })

  lifecycle {
    enabled               = local.create_sg_name_prefix
    create_before_destroy = true
  }

  timeouts {
    create = var.create_timeout
    delete = var.delete_timeout
  }
}

###############################################################################################################
# Rules
#
# aws_vpc_security_group_ingress_rule / aws_vpc_security_group_egress_rule accept exactly one of
# cidr_ipv4 / cidr_ipv6 / prefix_list_id / referenced_security_group_id, so every rule entry fans
# out to one resource instance per source, with stable composite keys:
#   "<rule key>/ipv4/<cidr>"  - one per IPv4 CIDR
#   "<rule key>/ipv6/<cidr>"  - one per IPv6 CIDR
#   "<rule key>/pl/<id>"      - one per prefix list ID
#   "<rule key>/sg"           - referenced security group
#   "<rule key>/self"         - self-referencing rule
###############################################################################################################

locals {
  rules_expanded = {
    for direction, rules in {
      ingress = var.ingress_rules
      egress  = var.egress_rules
    } :
    direction => merge({}, [
      for name, rule in rules : {
        for key, source in merge(
          { for cidr in rule.cidr_ipv4 : "${name}/ipv4/${cidr}" => { cidr_ipv4 = cidr } },
          { for cidr in rule.cidr_ipv6 : "${name}/ipv6/${cidr}" => { cidr_ipv6 = cidr } },
          { for pl_id in rule.prefix_list_ids : "${name}/pl/${pl_id}" => { prefix_list_id = pl_id } },
          rule.referenced_security_group_id != null ? { "${name}/sg" = { referenced_security_group_id = rule.referenced_security_group_id } } : {},
          rule.self ? { "${name}/self" = { self = true } } : {},
        ) :
        key => merge(
          {
            # Protocol "-1" (all traffic) does not allow ports
            from_port   = tostring(rule.ip_protocol) == "-1" ? null : rule.from_port
            to_port     = tostring(rule.ip_protocol) == "-1" ? null : rule.to_port
            ip_protocol = rule.ip_protocol
            description = rule.description

            cidr_ipv4                    = null
            cidr_ipv6                    = null
            prefix_list_id               = null
            referenced_security_group_id = null
            self                         = false
          },
          source,
        )
      }
    ]...)
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = { for k, v in local.rules_expanded.ingress : k => v if local.enabled }

  security_group_id = local.this_sg_id
  ip_protocol       = each.value.ip_protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  description       = each.value.description

  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.self ? local.this_sg_id : each.value.referenced_security_group_id

  tags = local.tags
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = { for k, v in local.rules_expanded.egress : k => v if local.enabled }

  security_group_id = local.this_sg_id
  ip_protocol       = each.value.ip_protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  description       = each.value.description

  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.self ? local.this_sg_id : each.value.referenced_security_group_id

  tags = local.tags
}

data "aws_region" "current" {}
