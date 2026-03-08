locals {
  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# Route Table
################################################################################

resource "aws_ec2_transit_gateway_route_table" "this" {
  transit_gateway_id = var.transit_gateway_id

  tags = merge(local.tags, { Name = var.name })

  lifecycle {
    enabled = var.enabled
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each = { for k, v in var.associations : k => v if var.enabled }

  transit_gateway_attachment_id  = each.value.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
  replace_existing_association   = try(each.value.replace_existing_association, null)
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each = { for k, v in var.associations : k => v if var.enabled && try(v.propagate_route_table, false) }

  transit_gateway_attachment_id  = each.value.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
}

################################################################################
# Route(s)
################################################################################

resource "aws_ec2_transit_gateway_route" "this" {
  for_each = { for k, v in var.routes : k => v if var.enabled }

  destination_cidr_block = each.value.destination_cidr_block
  blackhole              = each.value.blackhole

  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
  transit_gateway_attachment_id  = each.value.transit_gateway_attachment_id
}

resource "aws_route" "this" {
  for_each = { for k, v in var.vpc_routes : k => v if var.enabled }

  route_table_id              = each.value.route_table_id
  destination_cidr_block      = each.value.destination_cidr_block
  destination_ipv6_cidr_block = each.value.destination_ipv6_cidr_block
  transit_gateway_id          = var.transit_gateway_id
}
