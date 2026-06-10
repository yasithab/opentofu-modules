locals {
  enabled = var.enabled
  name    = var.name

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
    Region    = data.aws_region.current.region
  })
}

################################################################################
# VPC Attachment
################################################################################

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each = { for k, v in var.vpc_attachments : k => v if local.enabled }

  transit_gateway_id = each.value.transit_gateway_id
  vpc_id             = each.value.vpc_id
  subnet_ids         = each.value.subnet_ids

  dns_support                                     = each.value.dns_support ? "enable" : "disable"
  ipv6_support                                    = each.value.ipv6_support ? "enable" : "disable"
  appliance_mode_support                          = each.value.appliance_mode_support ? "enable" : "disable"
  security_group_referencing_support              = each.value.security_group_referencing_support ? "enable" : "disable"
  transit_gateway_default_route_table_association = each.value.transit_gateway_default_route_table_association
  transit_gateway_default_route_table_propagation = each.value.transit_gateway_default_route_table_propagation

  tags = merge(local.tags, { Name = "${coalesce(local.name, "tgw")}-${each.key}" }, each.value.tags)
}

################################################################################

data "aws_region" "current" {}
