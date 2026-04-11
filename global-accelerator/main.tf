data "aws_partition" "current" {}

locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# Accelerator
################################################################################

resource "aws_globalaccelerator_accelerator" "this" {
  name            = var.name
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
  client_affinity = try(each.value.client_affinity, "NONE")
  protocol        = try(each.value.protocol, "TCP")

  dynamic "port_range" {
    for_each = try(each.value.port_ranges, [{ from_port = 80, to_port = 80 }])

    content {
      from_port = port_range.value.from_port
      to_port   = try(port_range.value.to_port, port_range.value.from_port)
    }
  }
}

################################################################################
# Endpoint Group
################################################################################

resource "aws_globalaccelerator_endpoint_group" "this" {
  for_each = { for k, v in var.endpoint_groups : k => v if local.enabled && !var.create_custom_routing_accelerator }

  listener_arn = try(
    aws_globalaccelerator_listener.this[each.value.listener_key].id,
    each.value.listener_arn
  )

  endpoint_group_region         = try(each.value.endpoint_group_region, var.region)
  health_check_interval_seconds = try(each.value.health_check_interval_seconds, 30)
  health_check_path             = try(each.value.health_check_path, "/")
  health_check_port             = try(each.value.health_check_port, 80)
  health_check_protocol         = try(each.value.health_check_protocol, "HTTP")
  threshold_count               = try(each.value.threshold_count, 3)
  traffic_dial_percentage       = try(each.value.traffic_dial_percentage, 100)

  dynamic "endpoint_configuration" {
    for_each = try(each.value.endpoint_configurations, [])

    content {
      client_ip_preservation_enabled = try(endpoint_configuration.value.client_ip_preservation_enabled, true)
      endpoint_id                    = endpoint_configuration.value.endpoint_id
      weight                         = try(endpoint_configuration.value.weight, 128)
    }
  }

  dynamic "port_override" {
    for_each = try(each.value.port_overrides, [])

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
  name            = var.name
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
    for_each = try(each.value.port_ranges, [{ from_port = 80, to_port = 80 }])

    content {
      from_port = port_range.value.from_port
      to_port   = try(port_range.value.to_port, port_range.value.from_port)
    }
  }
}

################################################################################
# Custom Routing Endpoint Group
################################################################################

resource "aws_globalaccelerator_custom_routing_endpoint_group" "this" {
  for_each = { for k, v in var.custom_routing_endpoint_groups : k => v if local.enabled && var.create_custom_routing_accelerator }

  listener_arn = try(
    aws_globalaccelerator_custom_routing_listener.this[each.value.listener_key].id,
    each.value.listener_arn
  )

  endpoint_group_region = try(each.value.endpoint_group_region, var.region)

  dynamic "destination_configuration" {
    for_each = try(each.value.destination_configurations, [])

    content {
      from_port = destination_configuration.value.from_port
      to_port   = destination_configuration.value.to_port
      protocols = destination_configuration.value.protocols
    }
  }

  dynamic "endpoint_configuration" {
    for_each = try(each.value.endpoint_configurations, [])

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

  principals = try(each.value.principals, [])

  dynamic "resource" {
    for_each = try(each.value.resources, [])

    content {
      endpoint_id = resource.value.endpoint_id
      region      = try(resource.value.region, null)
    }
  }

  tags = local.tags
}
