################################################################################
# Transit Gateway
################################################################################

locals {
  tgw_tags = merge(
    var.tags,
    { Name = var.name },
    { ManagedBy = "opentofu" },
    var.tgw_tags,
  )

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

resource "aws_ec2_transit_gateway" "this" {
  amazon_side_asn                    = var.amazon_side_asn
  auto_accept_shared_attachments     = var.auto_accept_shared_attachments ? "enable" : "disable"
  default_route_table_association    = var.default_route_table_association ? "enable" : "disable"
  default_route_table_propagation    = var.default_route_table_propagation ? "enable" : "disable"
  description                        = var.description
  dns_support                        = var.dns_support ? "enable" : "disable"
  encryption_support                 = var.encryption_support ? "enable" : "disable"
  multicast_support                  = var.multicast_support ? "enable" : "disable"
  security_group_referencing_support = var.security_group_referencing_support ? "enable" : "disable"
  transit_gateway_cidr_blocks        = var.transit_gateway_cidr_blocks
  vpn_ecmp_support                   = var.vpn_ecmp_support ? "enable" : "disable"

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    delete = try(var.timeouts.delete, null)
  }

  tags = local.tgw_tags

  lifecycle {
    enabled = var.enabled
  }
}

resource "aws_ec2_tag" "this" {
  for_each = { for k, v in local.tgw_tags : k => v if var.enabled && var.default_route_table_association }

  resource_id = aws_ec2_transit_gateway.this.association_default_route_table_id
  key         = each.key
  value       = each.value
}

################################################################################
# VPC Attachment
################################################################################

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each = { for k, v in var.vpc_attachments : k => v if var.enabled }

  appliance_mode_support                          = each.value.appliance_mode_support ? "enable" : "disable"
  dns_support                                     = each.value.dns_support ? "enable" : "disable"
  ipv6_support                                    = each.value.ipv6_support ? "enable" : "disable"
  security_group_referencing_support              = each.value.security_group_referencing_support ? "enable" : "disable"
  subnet_ids                                      = each.value.subnet_ids
  transit_gateway_default_route_table_association = each.value.transit_gateway_default_route_table_association
  transit_gateway_default_route_table_propagation = each.value.transit_gateway_default_route_table_propagation
  transit_gateway_id                              = aws_ec2_transit_gateway.this.id
  vpc_id                                          = each.value.vpc_id

  tags = merge(local.tags, { Name = "${var.name}-${each.key}" }, each.value.tags)
}

resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "this" {
  for_each = { for k, v in var.vpc_attachments : k => v if var.enabled && v.accept_peering_attachment }

  transit_gateway_attachment_id                   = aws_ec2_transit_gateway_vpc_attachment.this[each.key].id
  transit_gateway_default_route_table_association = each.value.transit_gateway_default_route_table_association
  transit_gateway_default_route_table_propagation = each.value.transit_gateway_default_route_table_propagation

  tags = merge(local.tags, each.value.tags)
}

################################################################################
# TGW Peering Attachment
################################################################################

resource "aws_ec2_transit_gateway_peering_attachment" "this" {
  for_each = { for k, v in var.peering_attachments : k => v if var.enabled }

  peer_account_id         = each.value.peer_account_id
  peer_region             = each.value.peer_region
  peer_transit_gateway_id = each.value.peer_transit_gateway_id
  transit_gateway_id      = aws_ec2_transit_gateway.this.id

  dynamic "options" {
    for_each = each.value.dynamic_routing != null ? [each.value.dynamic_routing] : []
    content {
      dynamic_routing = options.value
    }
  }

  tags = merge(local.tags, { Name = "${var.name}-${each.key}" }, each.value.tags)
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "this" {
  for_each = { for k, v in var.peering_attachments : k => v if var.enabled && v.accept_peering_attachment }

  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.this[each.key].id

  tags = merge(local.tags, each.value.tags)
}

################################################################################
# Resource Access Manager
################################################################################

locals {
  ram_name = try(coalesce(var.ram_name, var.name), "")
}

resource "aws_ram_resource_share" "this" {
  name                      = local.ram_name
  allow_external_principals = var.ram_allow_external_principals

  tags = merge(local.tags, { Name = local.ram_name }, var.ram_tags)

  lifecycle {
    enabled = var.enabled && var.enable_ram_share
  }
}

resource "aws_ram_resource_association" "this" {
  resource_arn       = aws_ec2_transit_gateway.this.arn
  resource_share_arn = aws_ram_resource_share.this.id

  lifecycle {
    enabled = var.enabled && var.enable_ram_share
  }
}

resource "aws_ram_principal_association" "this" {
  for_each = { for k, v in var.ram_principals : k => v if var.enabled && var.enable_ram_share }

  principal          = each.value
  resource_share_arn = aws_ram_resource_share.this.arn
}

################################################################################
# Flow Log(s)
################################################################################

resource "aws_flow_log" "this" {
  for_each = { for k, v in var.flow_logs : k => v if var.enabled && var.create_flow_log }

  deliver_cross_account_role = each.value.deliver_cross_account_role

  dynamic "destination_options" {
    for_each = each.value.destination_options != null ? [each.value.destination_options] : []

    content {
      file_format                = destination_options.value.file_format
      hive_compatible_partitions = destination_options.value.hive_compatible_partitions
      per_hour_partition         = destination_options.value.per_hour_partition
    }
  }

  eni_id                   = each.value.eni_id
  iam_role_arn             = each.value.iam_role_arn
  log_destination          = each.value.log_destination
  log_destination_type     = each.value.log_destination_type
  log_format               = each.value.log_format
  max_aggregation_interval = max(each.value.max_aggregation_interval, 60)
  regional_nat_gateway_id  = each.value.regional_nat_gateway_id
  subnet_id                = each.value.subnet_id

  traffic_type       = each.value.traffic_type
  transit_gateway_id = each.value.enable_transit_gateway ? aws_ec2_transit_gateway.this.id : null
  transit_gateway_attachment_id = each.value.enable_transit_gateway ? null : try(
    aws_ec2_transit_gateway_vpc_attachment.this[each.value.vpc_attachment_key].id,
    aws_ec2_transit_gateway_peering_attachment.this[each.value.peering_attachment_key].id,
    null
  )

  tags = merge(local.tags, each.value.tags)
}
