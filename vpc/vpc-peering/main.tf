locals {
  acceptor_cidr_blocks = var.acceptor_cidr_blocks

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

resource "aws_vpc_peering_connection" "default" {
  vpc_id = var.requestor_vpc_id

  peer_owner_id = var.acceptor_aws_account_id
  peer_region   = var.acceptor_aws_region
  peer_vpc_id   = var.acceptor_vpc_id

  tags = local.tags

  timeouts {
    create = var.create_timeout
    update = var.update_timeout
    delete = var.delete_timeout
  }

  lifecycle {
    enabled = var.enabled && var.requestor_vpc_id != null && var.acceptor_vpc_id != null
  }
}

resource "aws_vpc_peering_connection_options" "requestor_dns" {
  vpc_peering_connection_id = try(aws_vpc_peering_connection.default.id, "")

  requester {
    allow_remote_vpc_dns_resolution = var.requestor_allow_remote_vpc_dns_resolution
  }

  accepter {
    allow_remote_vpc_dns_resolution = var.acceptor_allow_remote_vpc_dns_resolution
  }

  depends_on = [
    aws_vpc_peering_connection.default
  ]

  lifecycle {
    enabled = var.enabled && var.requestor_vpc_id != null && var.acceptor_vpc_id != null
  }
}

# Lookup requestor VPC so that we can reference the CIDR
data "aws_vpc" "requestor" {
  count = var.enabled && var.requestor_vpc_id != null ? 1 : 0
  id    = var.requestor_vpc_id
  tags  = var.requestor_vpc_tags
}

data "aws_route_tables" "requestor" {
  count  = var.enabled && var.requestor_vpc_id != null ? 1 : 0
  vpc_id = var.requestor_vpc_id
  tags   = var.requestor_route_table_tags
}

# Create routes from requestor to acceptor
resource "aws_route" "requestor" {
  count                     = var.enabled && length(data.aws_route_tables.requestor) > 0 ? length(distinct(sort(data.aws_route_tables.requestor[0].ids))) * length(local.acceptor_cidr_blocks) : 0
  route_table_id            = length(data.aws_route_tables.requestor) > 0 ? element(distinct(sort(data.aws_route_tables.requestor[0].ids)), ceil(count.index / length(local.acceptor_cidr_blocks))) : null
  destination_cidr_block    = local.acceptor_cidr_blocks[count.index % length(local.acceptor_cidr_blocks)]
  vpc_peering_connection_id = try(aws_vpc_peering_connection.default.id, "")
  depends_on                = [data.aws_route_tables.requestor, aws_vpc_peering_connection.default]
}
