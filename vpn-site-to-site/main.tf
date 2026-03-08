locals {
  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

resource "aws_cloudwatch_log_group" "this" {
  name                        = var.vpn_connection_cloudwatch_log_group_name
  name_prefix                 = var.vpn_connection_cloudwatch_log_group_name_prefix
  skip_destroy                = var.vpn_connection_cloudwatch_log_group_skip_destroy
  kms_key_id                  = var.vpn_connection_cloudwatch_log_group_kms_key_id
  retention_in_days           = var.vpn_connection_cloudwatch_log_retention_in_days
  log_group_class             = var.vpn_connection_cloudwatch_log_group_class
  deletion_protection_enabled = var.vpn_connection_cloudwatch_log_group_deletion_protection_enabled
  tags                        = local.tags

  lifecycle {
    enabled = var.enabled
  }
}

resource "aws_customer_gateway" "this" {
  bgp_asn          = var.customer_gateway_bgp_asn_extended == null ? var.customer_gateway_bgp_asn : null
  bgp_asn_extended = var.customer_gateway_bgp_asn_extended
  ip_address       = var.customer_gateway_ip_address
  type             = var.customer_gateway_type
  device_name      = var.customer_gateway_device_name
  certificate_arn  = var.customer_gateway_certificate_arn
  tags             = local.tags

  lifecycle {
    enabled = var.enabled
  }
}

resource "aws_vpn_gateway" "this" {
  vpc_id            = var.virtual_private_gateway_vpc_id
  amazon_side_asn   = var.virtual_private_gateway_amazon_side_asn
  availability_zone = var.virtual_private_gateway_availability_zone
  tags              = local.tags

  lifecycle {
    enabled = var.enabled
  }
}

resource "aws_vpn_gateway_route_propagation" "this" {
  count          = var.enabled ? length(var.route_propagation_route_table_ids) : 0
  vpn_gateway_id = try(aws_vpn_gateway.this.id, "")
  route_table_id = element(var.route_propagation_route_table_ids, count.index)
}

resource "aws_vpn_connection" "this" {
  customer_gateway_id                     = try(aws_customer_gateway.this.id, "")
  vpn_gateway_id                          = var.vpn_connection_transit_gateway_id != null ? null : try(aws_vpn_gateway.this.id, "")
  type                                    = var.customer_gateway_type
  static_routes_only                      = var.vpn_connection_static_routes_only
  local_ipv4_network_cidr                 = var.vpn_connection_local_ipv4_network_cidr
  outside_ip_address_type                 = var.vpn_connection_outside_ip_address_type
  preshared_key_storage                   = var.vpn_connection_preshared_key_storage
  remote_ipv4_network_cidr                = var.vpn_connection_remote_ipv4_network_cidr
  transport_transit_gateway_attachment_id = var.vpn_connection_transport_transit_gateway_attachment_id
  transit_gateway_id                      = var.vpn_connection_transit_gateway_id != null ? var.vpn_connection_transit_gateway_id : null
  tunnel_bandwidth                        = var.vpn_connection_tunnel_bandwidth
  enable_acceleration                     = var.vpn_connection_transit_gateway_id != null ? var.vpn_connection_enable_acceleration : null
  local_ipv6_network_cidr                 = var.vpn_connection_transit_gateway_id != null ? var.vpn_connection_local_ipv6_network_cidr : null
  remote_ipv6_network_cidr                = var.vpn_connection_transit_gateway_id != null ? var.vpn_connection_remote_ipv6_network_cidr : null
  tunnel1_inside_ipv6_cidr                = var.vpn_connection_transit_gateway_id != null ? var.vpn_connection_tunnel1_inside_ipv6_cidr : null
  tunnel2_inside_ipv6_cidr                = var.vpn_connection_transit_gateway_id != null ? var.vpn_connection_tunnel2_inside_ipv6_cidr : null
  tunnel_inside_ip_version                = var.vpn_connection_tunnel_inside_ip_version
  tunnel1_inside_cidr                     = var.vpn_connection_tunnel1_inside_cidr
  tunnel1_preshared_key                   = var.vpn_connection_tunnel1_preshared_key
  tunnel1_dpd_timeout_action              = var.vpn_connection_tunnel1_dpd_timeout_action
  tunnel1_dpd_timeout_seconds             = var.vpn_connection_tunnel1_dpd_timeout_seconds
  tunnel1_enable_tunnel_lifecycle_control = var.vpn_connection_tunnel1_enable_tunnel_lifecycle_control
  tunnel1_ike_versions                    = var.vpn_connection_tunnel1_ike_versions
  tunnel1_phase1_dh_group_numbers         = var.vpn_connection_tunnel1_phase1_dh_group_numbers
  tunnel1_phase1_encryption_algorithms    = var.vpn_connection_tunnel1_phase1_encryption_algorithms
  tunnel1_phase1_integrity_algorithms     = var.vpn_connection_tunnel1_phase1_integrity_algorithms
  tunnel1_phase1_lifetime_seconds         = var.vpn_connection_tunnel1_phase1_lifetime_seconds
  tunnel1_phase2_dh_group_numbers         = var.vpn_connection_tunnel1_phase2_dh_group_numbers
  tunnel1_phase2_encryption_algorithms    = var.vpn_connection_tunnel1_phase2_encryption_algorithms
  tunnel1_phase2_integrity_algorithms     = var.vpn_connection_tunnel1_phase2_integrity_algorithms
  tunnel1_phase2_lifetime_seconds         = var.vpn_connection_tunnel1_phase2_lifetime_seconds
  tunnel1_rekey_fuzz_percentage           = var.vpn_connection_tunnel1_rekey_fuzz_percentage
  tunnel1_rekey_margin_time_seconds       = var.vpn_connection_tunnel1_rekey_margin_time_seconds
  tunnel1_replay_window_size              = var.vpn_connection_tunnel1_replay_window_size
  tunnel1_startup_action                  = var.vpn_connection_tunnel1_startup_action
  tunnel1_log_options {
    cloudwatch_log_options {
      log_enabled           = var.vpn_connection_tunnel1_log_enabled
      log_output_format     = var.vpn_connection_tunnel1_log_output_format
      log_group_arn         = aws_cloudwatch_log_group.this.arn
      bgp_log_enabled       = try(var.vpn_connection_tunnel1_log_bgp_enabled, null)
      bgp_log_group_arn     = try(var.vpn_connection_tunnel1_log_bgp_group_arn, null)
      bgp_log_output_format = try(var.vpn_connection_tunnel1_log_bgp_output_format, null)
    }
  }
  tunnel2_inside_cidr                     = var.vpn_connection_tunnel2_inside_cidr
  tunnel2_preshared_key                   = var.vpn_connection_tunnel2_preshared_key
  tunnel2_dpd_timeout_action              = var.vpn_connection_tunnel2_dpd_timeout_action
  tunnel2_dpd_timeout_seconds             = var.vpn_connection_tunnel2_dpd_timeout_seconds
  tunnel2_enable_tunnel_lifecycle_control = var.vpn_connection_tunnel2_enable_tunnel_lifecycle_control
  tunnel2_ike_versions                    = var.vpn_connection_tunnel2_ike_versions
  tunnel2_phase1_dh_group_numbers         = var.vpn_connection_tunnel2_phase1_dh_group_numbers
  tunnel2_phase1_encryption_algorithms    = var.vpn_connection_tunnel2_phase1_encryption_algorithms
  tunnel2_phase1_integrity_algorithms     = var.vpn_connection_tunnel2_phase1_integrity_algorithms
  tunnel2_phase1_lifetime_seconds         = var.vpn_connection_tunnel2_phase1_lifetime_seconds
  tunnel2_phase2_dh_group_numbers         = var.vpn_connection_tunnel2_phase2_dh_group_numbers
  tunnel2_phase2_encryption_algorithms    = var.vpn_connection_tunnel2_phase2_encryption_algorithms
  tunnel2_phase2_integrity_algorithms     = var.vpn_connection_tunnel2_phase2_integrity_algorithms
  tunnel2_phase2_lifetime_seconds         = var.vpn_connection_tunnel2_phase2_lifetime_seconds
  tunnel2_rekey_fuzz_percentage           = var.vpn_connection_tunnel2_rekey_fuzz_percentage
  tunnel2_rekey_margin_time_seconds       = var.vpn_connection_tunnel2_rekey_margin_time_seconds
  tunnel2_replay_window_size              = var.vpn_connection_tunnel2_replay_window_size
  tunnel2_startup_action                  = var.vpn_connection_tunnel2_startup_action
  tunnel2_log_options {
    cloudwatch_log_options {
      log_enabled           = var.vpn_connection_tunnel2_log_enabled
      log_output_format     = var.vpn_connection_tunnel2_log_output_format
      log_group_arn         = aws_cloudwatch_log_group.this.arn
      bgp_log_enabled       = try(var.vpn_connection_tunnel2_log_bgp_enabled, null)
      bgp_log_group_arn     = try(var.vpn_connection_tunnel2_log_bgp_group_arn, null)
      bgp_log_output_format = try(var.vpn_connection_tunnel2_log_bgp_output_format, null)
    }
  }

  tags = local.tags

  lifecycle {
    enabled = var.enabled
  }
}

resource "aws_vpn_connection_route" "this" {
  for_each               = var.enabled ? toset(var.vpn_connection_route_destination_cidr_block) : []
  destination_cidr_block = each.key
  vpn_connection_id      = aws_vpn_connection.this.id
}
