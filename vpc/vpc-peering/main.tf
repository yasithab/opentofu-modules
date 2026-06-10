locals {
  enabled = var.enabled

  acceptor_cidr_blocks = var.acceptor_cidr_blocks

  create_peering  = local.enabled && var.requestor_vpc_id != null && var.acceptor_vpc_id != null
  create_accepter = local.create_peering && var.create_accepter

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
    Region    = data.aws_region.current.region
  })
}

resource "aws_vpc_peering_connection" "default" {
  vpc_id = var.requestor_vpc_id

  peer_owner_id = var.acceptor_aws_account_id
  peer_region   = var.acceptor_aws_region
  peer_vpc_id   = var.acceptor_vpc_id
  auto_accept   = var.auto_accept

  tags = local.tags

  timeouts {
    create = var.create_timeout
    update = var.update_timeout
    delete = var.delete_timeout
  }

  lifecycle {
    enabled = local.create_peering
  }
}

resource "aws_vpc_peering_connection_accepter" "default" {
  vpc_peering_connection_id = aws_vpc_peering_connection.default.id
  auto_accept               = true

  tags = local.tags

  lifecycle {
    enabled = local.create_accepter
  }
}

resource "aws_vpc_peering_connection_options" "requestor_dns" {
  vpc_peering_connection_id = aws_vpc_peering_connection.default.id

  requester {
    allow_remote_vpc_dns_resolution = var.requestor_allow_remote_vpc_dns_resolution
  }

  accepter {
    allow_remote_vpc_dns_resolution = var.acceptor_allow_remote_vpc_dns_resolution
  }

  depends_on = [
    aws_vpc_peering_connection.default,
    aws_vpc_peering_connection_accepter.default,
  ]

  lifecycle {
    # Peering connection options can only be set once the connection is active,
    # which requires the connection to be accepted (auto-accept or accepter).
    enabled = local.create_peering && (var.auto_accept || var.create_accepter)
  }
}

data "aws_route_tables" "requestor" {
  count  = local.enabled && var.requestor_vpc_id != null ? 1 : 0
  vpc_id = var.requestor_vpc_id
  tags   = var.requestor_route_table_tags
}

locals {
  requestor_route_table_ids = local.enabled && var.requestor_vpc_id != null ? distinct(sort(data.aws_route_tables.requestor[0].ids)) : []

  requestor_routes = {
    for pair in setproduct(local.requestor_route_table_ids, local.acceptor_cidr_blocks) :
    "${pair[0]}-${pair[1]}" => {
      route_table_id         = pair[0]
      destination_cidr_block = pair[1]
    } if local.enabled
  }
}

# Create routes from requestor to acceptor
resource "aws_route" "requestor" {
  for_each = local.requestor_routes

  route_table_id            = each.value.route_table_id
  destination_cidr_block    = each.value.destination_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.default.id

  depends_on = [data.aws_route_tables.requestor, aws_vpc_peering_connection.default]
}

data "aws_region" "current" {}
