
locals {
  enabled = var.enabled
  name    = var.name

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
    Region    = data.aws_region.current.region
  })
}

################################################################################
# Accelerator
################################################################################

resource "aws_globalaccelerator_accelerator" "this" {
  name            = local.name
  ip_address_type = var.ip_address_type
  ip_addresses    = var.ip_addresses
  enabled         = var.accelerator_enabled

  dynamic "attributes" {
    for_each = var.flow_logs_enabled || var.flow_logs_s3_bucket != null ? [1] : []

    content {
      flow_logs_enabled   = var.flow_logs_enabled
      flow_logs_s3_bucket = var.flow_logs_s3_bucket
      flow_logs_s3_prefix = var.flow_logs_s3_prefix
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled && !var.create_custom_routing_accelerator
  }
}

################################################################################
# Listener
################################################################################

resource "aws_globalaccelerator_listener" "this" {
  for_each = { for k, v in var.listeners : k => v if local.enabled && !var.create_custom_routing_accelerator }

  accelerator_arn = aws_globalaccelerator_accelerator.this.id
  client_affinity = each.value.client_affinity
  protocol        = each.value.protocol

  dynamic "port_range" {
    for_each = each.value.port_ranges

    content {
      from_port = port_range.value.from_port
      to_port   = coalesce(port_range.value.to_port, port_range.value.from_port)
    }
  }
}

################################################################################
# Endpoint Group
################################################################################

resource "aws_globalaccelerator_endpoint_group" "this" {
  for_each = { for k, v in var.endpoint_groups : k => v if local.enabled && !var.create_custom_routing_accelerator }

  listener_arn = each.value.listener_key != null ? aws_globalaccelerator_listener.this[each.value.listener_key].id : each.value.listener_arn

  endpoint_group_region         = each.value.endpoint_group_region != null ? each.value.endpoint_group_region : var.region
  health_check_interval_seconds = each.value.health_check_interval_seconds
  health_check_path             = each.value.health_check_path
  health_check_port             = each.value.health_check_port
  health_check_protocol         = each.value.health_check_protocol
  threshold_count               = each.value.threshold_count
  traffic_dial_percentage       = each.value.traffic_dial_percentage

  dynamic "endpoint_configuration" {
    for_each = each.value.endpoint_configurations

    content {
      client_ip_preservation_enabled = endpoint_configuration.value.client_ip_preservation_enabled
      endpoint_id                    = endpoint_configuration.value.endpoint_id
      weight                         = endpoint_configuration.value.weight
    }
  }

  dynamic "port_override" {
    for_each = each.value.port_overrides

    content {
      endpoint_port = port_override.value.endpoint_port
      listener_port = port_override.value.listener_port
    }
  }
}

################################################################################
# Custom Routing Accelerator
################################################################################

resource "aws_globalaccelerator_custom_routing_accelerator" "this" {
  name            = local.name
  ip_address_type = var.ip_address_type
  ip_addresses    = var.ip_addresses
  enabled         = var.accelerator_enabled

  dynamic "attributes" {
    for_each = var.flow_logs_enabled || var.flow_logs_s3_bucket != null ? [1] : []

    content {
      flow_logs_enabled   = var.flow_logs_enabled
      flow_logs_s3_bucket = var.flow_logs_s3_bucket
      flow_logs_s3_prefix = var.flow_logs_s3_prefix
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_custom_routing_accelerator
  }
}

################################################################################
# Custom Routing Listener
################################################################################

resource "aws_globalaccelerator_custom_routing_listener" "this" {
  for_each = { for k, v in var.custom_routing_listeners : k => v if local.enabled && var.create_custom_routing_accelerator }

  accelerator_arn = aws_globalaccelerator_custom_routing_accelerator.this.id

  dynamic "port_range" {
    for_each = each.value.port_ranges

    content {
      from_port = port_range.value.from_port
      to_port   = coalesce(port_range.value.to_port, port_range.value.from_port)
    }
  }
}

################################################################################
# Custom Routing Endpoint Group
################################################################################

resource "aws_globalaccelerator_custom_routing_endpoint_group" "this" {
  for_each = { for k, v in var.custom_routing_endpoint_groups : k => v if local.enabled && var.create_custom_routing_accelerator }

  listener_arn = each.value.listener_key != null ? aws_globalaccelerator_custom_routing_listener.this[each.value.listener_key].id : each.value.listener_arn

  endpoint_group_region = each.value.endpoint_group_region != null ? each.value.endpoint_group_region : var.region

  dynamic "destination_configuration" {
    for_each = each.value.destination_configurations

    content {
      from_port = destination_configuration.value.from_port
      to_port   = destination_configuration.value.to_port
      protocols = destination_configuration.value.protocols
    }
  }

  dynamic "endpoint_configuration" {
    for_each = each.value.endpoint_configurations

    content {
      endpoint_id = endpoint_configuration.value.endpoint_id
    }
  }
}

################################################################################
# Cross-Zone Load Balancing
################################################################################

resource "aws_globalaccelerator_cross_account_attachment" "this" {
  for_each = { for k, v in var.cross_account_attachments : k => v if local.enabled }

  name = each.value.name

  principals = each.value.principals

  dynamic "resource" {
    for_each = each.value.resources

    content {
      endpoint_id = resource.value.endpoint_id
      region      = resource.value.region
    }
  }

  tags = local.tags
}

data "aws_region" "current" {}
