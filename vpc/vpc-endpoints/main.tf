################################################################################
# Endpoint(s)
################################################################################

locals {
  enabled            = var.enabled
  endpoints          = { for k, v in var.endpoints : k => v if local.enabled && v.create }
  security_group_ids = local.enabled && var.create_security_group ? concat(var.security_group_ids, [aws_security_group.this.id]) : var.security_group_ids

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

data "aws_vpc_endpoint_service" "this" {
  for_each = { for k, v in local.endpoints : k => v if !contains(["Resource", "ServiceNetwork"], v.service_type) }

  service         = each.value.service
  service_name    = each.value.service_name
  service_regions = each.value.service_region != null ? [each.value.service_region] : null

  filter {
    name   = "service-type"
    values = [each.value.service_type]
  }
}

resource "aws_vpc_endpoint" "this" {
  for_each = local.endpoints

  vpc_id                     = var.vpc_id
  service_name               = contains(["Resource", "ServiceNetwork"], each.value.service_type) ? null : (each.value.service_endpoint != null ? each.value.service_endpoint : data.aws_vpc_endpoint_service.this[each.key].service_name)
  service_region             = each.value.service_region
  vpc_endpoint_type          = each.value.service_type
  auto_accept                = each.value.auto_accept
  resource_configuration_arn = each.value.resource_configuration_arn
  service_network_arn        = each.value.service_network_arn

  security_group_ids  = each.value.service_type == "Interface" ? (length(distinct(concat(local.security_group_ids, each.value.security_group_ids))) > 0 ? distinct(concat(local.security_group_ids, each.value.security_group_ids)) : null) : null
  subnet_ids          = each.value.service_type == "Interface" ? distinct(concat(var.subnet_ids, each.value.subnet_ids)) : null
  route_table_ids     = each.value.service_type == "Gateway" ? each.value.route_table_ids : null
  policy              = each.value.policy
  private_dns_enabled = each.value.service_type == "Interface" ? each.value.private_dns_enabled : null
  ip_address_type     = each.value.ip_address_type

  dynamic "dns_options" {
    for_each = each.value.dns_options != null ? [each.value.dns_options] : []

    content {
      dns_record_ip_type                             = dns_options.value.dns_record_ip_type
      private_dns_only_for_inbound_resolver_endpoint = dns_options.value.private_dns_only_for_inbound_resolver_endpoint
      private_dns_preference                         = dns_options.value.private_dns_preference
      private_dns_specified_domains                  = dns_options.value.private_dns_specified_domains
    }
  }

  dynamic "subnet_configuration" {
    for_each = each.value.subnet_configuration

    content {
      ipv4      = subnet_configuration.value.ipv4
      ipv6      = subnet_configuration.value.ipv6
      subnet_id = subnet_configuration.value.subnet_id
    }
  }

  tags = merge(local.tags, { "Name" = replace(each.key, ".", "-") }, each.value.tags)

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
    if local.enabled && var.create_security_group && v.type == "ingress"
  }

  security_group_id = aws_security_group.this.id

  ip_protocol                  = each.value.ip_protocol
  from_port                    = each.value.ip_protocol == "-1" ? null : coalesce(each.value.from_port, 443)
  to_port                      = each.value.ip_protocol == "-1" ? null : coalesce(each.value.to_port, 443)
  description                  = each.value.description
  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.referenced_security_group_id

  tags = merge(local.tags, each.value.tags)
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = {
    for k, v in var.security_group_rules : k => v
    if local.enabled && var.create_security_group && v.type == "egress"
  }

  security_group_id = aws_security_group.this.id

  ip_protocol                  = each.value.ip_protocol
  from_port                    = each.value.ip_protocol == "-1" ? null : coalesce(each.value.from_port, 443)
  to_port                      = each.value.ip_protocol == "-1" ? null : coalesce(each.value.to_port, 443)
  description                  = each.value.description
  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.referenced_security_group_id

  tags = merge(local.tags, each.value.tags)
}
