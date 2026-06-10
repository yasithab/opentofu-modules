locals {
  enabled = var.enabled

  connection_name = var.name != null ? var.name : "${var.github_organization_name}-github"

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

resource "aws_codeconnections_connection" "this" {
  name          = local.connection_name
  provider_type = var.host_arn == null ? var.provider_type : null
  host_arn      = var.host_arn

  tags = local.tags

  timeouts {
    create = var.connection_timeouts.create
    delete = var.connection_timeouts.delete
  }

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_codeconnections_host" "this" {
  name              = var.host_name
  provider_endpoint = var.host_provider_endpoint
  provider_type     = var.host_provider_type

  dynamic "vpc_configuration" {
    for_each = var.host_vpc_configuration != null ? [var.host_vpc_configuration] : []
    content {
      security_group_ids = vpc_configuration.value.security_group_ids
      subnet_ids         = vpc_configuration.value.subnet_ids
      vpc_id             = vpc_configuration.value.vpc_id
      tls_certificate    = try(vpc_configuration.value.tls_certificate, null)
    }
  }

  tags = local.tags

  timeouts {
    create = var.host_timeouts.create
    delete = var.host_timeouts.delete
  }

  lifecycle {
    enabled = local.enabled && var.create_host

    precondition {
      condition     = !var.create_host || var.host_name != null
      error_message = "host_name must be set when create_host is true."
    }

    precondition {
      condition     = !var.create_host || var.host_provider_endpoint != null
      error_message = "host_provider_endpoint must be set when create_host is true."
    }

    precondition {
      condition     = !var.create_host || var.host_provider_type != null
      error_message = "host_provider_type must be set when create_host is true."
    }
  }
}