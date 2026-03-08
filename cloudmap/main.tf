locals {
  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  namespace_id = var.existing_namespace_id != null ? var.existing_namespace_id : (
    var.create_private_dns_namespace ? aws_service_discovery_private_dns_namespace.this.id : (
      var.create_public_dns_namespace ? aws_service_discovery_public_dns_namespace.this.id : (
        var.create_namespace ? aws_service_discovery_http_namespace.this.id : null
      )
    )
  )

  lambda_service_key = var.lambda_service_name != null ? var.lambda_service_name : (
    length(var.services) > 0 ? keys(var.services)[0] : null
  )
}

################################################################################
# Namespace Resources
################################################################################

# AWS CloudMap HTTP Namespace
resource "aws_service_discovery_http_namespace" "this" {
  name        = var.namespace_name
  description = var.namespace_description

  tags = merge(local.tags, { Name = var.namespace_name })

  lifecycle {
    enabled = var.enabled && var.create_namespace
  }
}

# AWS CloudMap Private DNS Namespace
resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = var.namespace_name
  description = var.namespace_description
  vpc         = var.vpc_id

  tags = merge(local.tags, { Name = var.namespace_name })

  lifecycle {
    enabled = var.enabled && var.create_private_dns_namespace
  }
}

# AWS CloudMap Public DNS Namespace
resource "aws_service_discovery_public_dns_namespace" "this" {
  name        = var.namespace_name
  description = var.namespace_description

  tags = merge(local.tags, { Name = var.namespace_name })

  lifecycle {
    enabled = var.enabled && var.create_public_dns_namespace
  }
}

################################################################################
# Service Discovery Services
################################################################################

resource "aws_service_discovery_service" "services" {
  for_each = { for k, v in var.services : k => v if var.enabled }

  name          = each.value.name
  description   = try(each.value.description, null)
  namespace_id  = local.namespace_id
  type          = try(each.value.type, null)
  force_destroy = try(each.value.force_destroy, true)

  # DNS config - only for DNS namespaces (private/public), not HTTP namespaces
  dynamic "dns_config" {
    for_each = var.enable_dns_config && (var.create_private_dns_namespace || var.create_public_dns_namespace) ? [1] : []
    content {
      namespace_id = local.namespace_id

      dns_records {
        ttl  = try(each.value.dns_ttl, var.dns_ttl)
        type = try(each.value.dns_record_type, var.dns_record_type)
      }

      routing_policy = try(each.value.routing_policy, var.routing_policy)
    }
  }

  # Standard health check - only for public DNS namespaces
  # Mutually exclusive with health_check_custom_config
  dynamic "health_check_config" {
    for_each = (
      try(each.value.health_check_config, null) != null &&
      var.enable_health_checks &&
      var.create_public_dns_namespace
    ) ? [each.value.health_check_config] : []

    content {
      resource_path     = health_check_config.value.resource_path
      type              = health_check_config.value.type
      failure_threshold = try(health_check_config.value.failure_threshold, null)
    }
  }

  # Custom health check - only for private DNS namespaces
  # Deprecated in v6 in favour of health_check_config; kept for backward compatibility
  dynamic "health_check_custom_config" {
    for_each = (
      try(each.value.health_check_custom_config, false) &&
      var.enable_health_checks &&
      var.create_private_dns_namespace &&
      try(each.value.health_check_config, null) == null
    ) ? [1] : []
    content {
    }
  }

  tags = merge(local.tags, { Name = each.value.name }, try(each.value.tags, {}))
}

################################################################################
# ECS Service Discovery IAM
################################################################################

resource "aws_iam_role" "ecs_service_discovery" {
  name = "${var.namespace_name}-service-discovery-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  lifecycle {
    enabled = var.enabled && var.create_ecs_service_discovery_role && length(var.services) > 0
  }
}

resource "aws_iam_role_policy" "ecs_service_discovery" {
  name = "${var.namespace_name}-service-discovery-policy"
  role = aws_iam_role.ecs_service_discovery.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "servicediscovery:RegisterInstance",
          "servicediscovery:DeregisterInstance",
          "servicediscovery:GetInstancesHealthStatus",
          "servicediscovery:UpdateInstanceCustomHealthStatus"
        ]
        Resource = [for service in aws_service_discovery_service.services : service.arn]
      }
    ]
  })

  lifecycle {
    enabled = var.enabled && var.create_ecs_service_discovery_role && length(var.services) > 0
  }
}

################################################################################
# Lambda CloudMap Registration
################################################################################

resource "aws_service_discovery_instance" "lambda" {
  for_each = var.enabled && var.enable_lambda_registration && var.lambda_service_name != null ? toset([var.lambda_service_name]) : toset([])

  instance_id = var.lambda_instance_id
  service_id  = aws_service_discovery_service.services[each.key].id

  attributes = merge(
    {
      "AWS_INSTANCE_IPV4" = var.lambda_ip_address != null ? var.lambda_ip_address : "127.0.0.1"
      "instance_type"     = "lambda"
      "service_type"      = "function"
      "protocol"          = "https"
      "lambda_url"        = var.lambda_url
    },
    var.lambda_attributes
  )

  depends_on = [aws_service_discovery_service.services]
}

################################################################################
# Health Check Validation
################################################################################

locals {
  health_check_validation_errors = compact(flatten([
    for service_name, service in var.services : [
      service.health_check_config != null && !var.create_public_dns_namespace ?
      "Service '${service_name}': health_check_config can only be used with public DNS namespaces" : null,

      try(service.health_check_custom_config, false) && !var.create_private_dns_namespace ?
      "Service '${service_name}': health_check_custom_config can only be used with private DNS namespaces" : null,

      service.health_check_config != null && try(service.health_check_custom_config, false) ?
      "Service '${service_name}': Cannot use both health_check_config and health_check_custom_config simultaneously" : null
    ]
  ]))
}

check "health_check_validation" {
  assert {
    condition     = length(local.health_check_validation_errors) == 0
    error_message = "Health check configuration errors: ${join(", ", local.health_check_validation_errors)}"
  }
}
