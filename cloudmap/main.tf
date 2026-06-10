locals {
  enabled = var.enabled
  name    = var.name

  create_http_namespace             = local.enabled && var.create_namespace
  create_private_dns_namespace      = local.enabled && var.create_private_dns_namespace
  create_public_dns_namespace       = local.enabled && var.create_public_dns_namespace
  create_ecs_service_discovery_role = local.enabled && var.create_ecs_service_discovery_role && length(var.services) > 0
  create_lambda_instance            = local.enabled && var.enable_lambda_registration && local.lambda_service_key != null

  # Effective namespace type: explicit (for existing_namespace_id) or inferred
  # from the create_* flags.
  namespace_type = var.namespace_type != null ? var.namespace_type : (
    var.create_private_dns_namespace ? "dns_private" : (
      var.create_public_dns_namespace ? "dns_public" : "http"
    )
  )
  dns_namespace = contains(["dns_private", "dns_public"], local.namespace_type)

  namespace_id = var.existing_namespace_id != null ? var.existing_namespace_id : try(coalesce(
    try(aws_service_discovery_private_dns_namespace.this.id, null),
    try(aws_service_discovery_public_dns_namespace.this.id, null),
    try(aws_service_discovery_http_namespace.this.id, null),
  ), null)

  lambda_service_key = var.lambda_service_name != null ? var.lambda_service_name : (
    length(var.services) > 0 ? keys(var.services)[0] : null
  )

  ecs_service_discovery_role_name = var.ecs_service_discovery_role_name != null ? var.ecs_service_discovery_role_name : (
    local.name != null ? "${local.name}-service-discovery-role" : null
  )
  ecs_service_discovery_policy_name = local.name != null ? "${local.name}-service-discovery-policy" : (
    var.ecs_service_discovery_role_name != null ? "${var.ecs_service_discovery_role_name}-policy" : null
  )

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# Namespace Resources
################################################################################

# AWS CloudMap HTTP Namespace
resource "aws_service_discovery_http_namespace" "this" {
  name        = local.name
  description = var.namespace_description

  tags = merge(local.tags, { Name = local.name })

  lifecycle {
    enabled = local.create_http_namespace
  }
}

# AWS CloudMap Private DNS Namespace
resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = local.name
  description = var.namespace_description
  vpc         = var.vpc_id

  tags = merge(local.tags, { Name = local.name })

  lifecycle {
    enabled = local.create_private_dns_namespace
  }
}

# AWS CloudMap Public DNS Namespace
resource "aws_service_discovery_public_dns_namespace" "this" {
  name        = local.name
  description = var.namespace_description

  tags = merge(local.tags, { Name = local.name })

  lifecycle {
    enabled = local.create_public_dns_namespace
  }
}

################################################################################
# Service Discovery Services
################################################################################

resource "aws_service_discovery_service" "services" {
  for_each = { for k, v in var.services : k => v if local.enabled }

  name          = each.value.name
  description   = try(each.value.description, null)
  namespace_id  = local.namespace_id
  type          = try(each.value.type, null)
  force_destroy = try(each.value.force_destroy, true)

  # DNS config - only for DNS namespaces (private/public), not HTTP namespaces.
  # Driven by local.namespace_type so it also works with existing_namespace_id
  # (set var.namespace_type in that case).
  dynamic "dns_config" {
    for_each = var.enable_dns_config && local.dns_namespace ? [1] : []
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
      local.namespace_type == "dns_public"
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
      local.namespace_type == "dns_private" &&
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
  name = local.ecs_service_discovery_role_name

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
    enabled = local.create_ecs_service_discovery_role
  }
}

resource "aws_iam_role_policy" "ecs_service_discovery" {
  name = local.ecs_service_discovery_policy_name
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
    enabled = local.create_ecs_service_discovery_role
  }
}

################################################################################
# Lambda CloudMap Registration
################################################################################

resource "aws_service_discovery_instance" "lambda" {
  for_each = local.create_lambda_instance ? toset([local.lambda_service_key]) : toset([])

  instance_id = var.lambda_instance_id
  service_id  = aws_service_discovery_service.services[each.key].id

  # AWS_INSTANCE_IPV4 is only set when an IP address is provided; no
  # placeholder address is registered.
  attributes = merge(
    var.lambda_ip_address != null ? { AWS_INSTANCE_IPV4 = var.lambda_ip_address } : {},
    var.lambda_url != null ? { lambda_url = var.lambda_url } : {},
    {
      instance_type = "lambda"
      service_type  = "function"
      protocol      = "https"
    },
    var.lambda_attributes
  )
}

################################################################################
# Health Check Validation
################################################################################

locals {
  health_check_validation_errors = compact(flatten([
    for service_name, service in var.services : [
      service.health_check_config != null && local.namespace_type != "dns_public" ?
      "Service '${service_name}': health_check_config can only be used with public DNS namespaces" : null,

      try(service.health_check_custom_config, false) && local.namespace_type != "dns_private" ?
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
