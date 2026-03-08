################################################################################
# Endpoint(s)
################################################################################

locals {
  enabled            = var.enabled
  endpoints          = { for k, v in var.endpoints : k => v if local.enabled && try(v.create, true) }
  security_group_ids = local.enabled && var.create_security_group ? concat(var.security_group_ids, [aws_security_group.this.id]) : var.security_group_ids

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

data "aws_vpc_endpoint_service" "this" {
  for_each = { for k, v in local.endpoints : k => v if !contains(["Resource", "ServiceNetwork"], try(v.service_type, "Interface")) }

  service         = try(each.value.service, null)
  service_name    = try(each.value.service_name, null)
  service_regions = try(coalescelist(compact([each.value.service_region])), null)

  filter {
    name   = "service-type"
    values = [try(each.value.service_type, "Interface")]
  }
}

resource "aws_vpc_endpoint" "this" {
  for_each = local.endpoints

  vpc_id                     = var.vpc_id
  service_name               = contains(["Resource", "ServiceNetwork"], try(each.value.service_type, "Interface")) ? null : try(each.value.service_endpoint, data.aws_vpc_endpoint_service.this[each.key].service_name)
  service_region             = try(each.value.service_region, null)
  vpc_endpoint_type          = try(each.value.service_type, "Interface")
  auto_accept                = try(each.value.auto_accept, null)
  resource_configuration_arn = try(each.value.resource_configuration_arn, null)
  service_network_arn        = try(each.value.service_network_arn, null)

  security_group_ids  = try(each.value.service_type, "Interface") == "Interface" ? length(distinct(concat(local.security_group_ids, lookup(each.value, "security_group_ids", [])))) > 0 ? distinct(concat(local.security_group_ids, lookup(each.value, "security_group_ids", []))) : null : null
  subnet_ids          = try(each.value.service_type, "Interface") == "Interface" ? distinct(concat(var.subnet_ids, lookup(each.value, "subnet_ids", []))) : null
  route_table_ids     = try(each.value.service_type, "Interface") == "Gateway" ? lookup(each.value, "route_table_ids", null) : null
  policy              = try(each.value.policy, null)
  private_dns_enabled = try(each.value.service_type, "Interface") == "Interface" ? try(each.value.private_dns_enabled, null) : null
  ip_address_type     = try(each.value.ip_address_type, null)

  dynamic "dns_options" {
    for_each = try([each.value.dns_options], [])

    content {
      dns_record_ip_type                             = try(dns_options.value.dns_record_ip_type, null)
      private_dns_only_for_inbound_resolver_endpoint = try(dns_options.value.private_dns_only_for_inbound_resolver_endpoint, null)
      private_dns_preference                         = try(dns_options.value.private_dns_preference, null)
      private_dns_specified_domains                  = try(dns_options.value.private_dns_specified_domains, null)
    }
  }

  dynamic "subnet_configuration" {
    for_each = try(each.value.subnet_configuration, [])

    content {
      ipv4      = try(subnet_configuration.value.ipv4, null)
      ipv6      = try(subnet_configuration.value.ipv6, null)
      subnet_id = subnet_configuration.value.subnet_id
    }
  }

  tags = merge(local.tags, { "Name" = replace(each.key, ".", "-") }, try(each.value.tags, {}))

  timeouts {
    create = try(var.timeouts.create, "10m")
    update = try(var.timeouts.update, "10m")
    delete = try(var.timeouts.delete, "10m")
  }
}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "this" {
  name        = var.security_group_name
  name_prefix = var.security_group_name_prefix != null ? "${var.security_group_name_prefix}-" : null
  description = var.security_group_description
  vpc_id      = var.vpc_id

  tags = merge(local.tags, var.security_group_tags, { "Name" = try(coalesce(var.security_group_name, var.security_group_name_prefix), "") })

  timeouts {
    delete = "5m"
  }

  lifecycle {
    enabled               = local.enabled && var.create_security_group
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = {
    for k, v in var.security_group_rules : k => v
    if local.enabled && var.create_security_group && try(v.type, "ingress") == "ingress"
  }

  security_group_id = aws_security_group.this.id

  ip_protocol                  = try(each.value.protocol, "tcp")
  from_port                    = try(each.value.protocol, "tcp") == "-1" ? null : try(each.value.from_port, 443)
  to_port                      = try(each.value.protocol, "tcp") == "-1" ? null : try(each.value.to_port, 443)
  description                  = try(each.value.description, null)
  cidr_ipv4                    = try(each.value.cidr_blocks, null)
  cidr_ipv6                    = try(each.value.ipv6_cidr_blocks, null)
  prefix_list_id               = try(each.value.prefix_list_ids[0], null)
  referenced_security_group_id = try(each.value.source_security_group_id, null)

  tags = local.tags
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = {
    for k, v in var.security_group_rules : k => v
    if local.enabled && var.create_security_group && try(v.type, "ingress") == "egress"
  }

  security_group_id = aws_security_group.this.id

  ip_protocol                  = try(each.value.protocol, "tcp")
  from_port                    = try(each.value.protocol, "tcp") == "-1" ? null : try(each.value.from_port, 443)
  to_port                      = try(each.value.protocol, "tcp") == "-1" ? null : try(each.value.to_port, 443)
  description                  = try(each.value.description, null)
  cidr_ipv4                    = try(each.value.cidr_blocks, null)
  cidr_ipv6                    = try(each.value.ipv6_cidr_blocks, null)
  prefix_list_id               = try(each.value.prefix_list_ids[0], null)
  referenced_security_group_id = try(each.value.source_security_group_id, null)

  tags = local.tags
}
