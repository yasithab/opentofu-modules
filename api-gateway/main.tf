locals {
  enabled                                 = var.enabled
  create_rest_api_policy                  = local.enabled && var.rest_api_policy != null
  create_log_group                        = local.enabled && var.logging_level != "OFF"
  log_group_arn                           = try(aws_cloudwatch_log_group.this.arn, null)
  vpc_link_enabled                        = local.enabled && length(var.private_link_target_arns) > 0
  aws_api_gateway_method_settings_enabled = local.enabled && var.logging_level != "OFF"

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

resource "aws_api_gateway_rest_api" "this" {
  name                         = var.name
  body                         = jsonencode(var.openapi_config)
  description                  = var.description
  binary_media_types           = var.binary_media_types
  minimum_compression_size     = var.minimum_compression_size
  put_rest_api_mode            = var.put_rest_api_mode
  disable_execute_api_endpoint = var.disable_execute_api_endpoint
  api_key_source               = var.api_key_source
  fail_on_warnings             = var.fail_on_warnings
  parameters                   = var.parameters
  policy                       = var.rest_api_inline_policy
  tags                         = local.tags

  endpoint_configuration {
    types            = [var.endpoint_type]
    ip_address_type  = var.endpoint_ip_address_type
    vpc_endpoint_ids = var.vpc_endpoint_ids
  }

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_api_gateway_rest_api_policy" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  policy = var.rest_api_policy

  lifecycle {
    enabled = local.create_rest_api_policy
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/apigateway/${var.name}"
  retention_in_days = var.log_group_retention_in_days
  skip_destroy      = var.cloudwatch_log_group_skip_destroy
  log_group_class   = var.cloudwatch_log_group_class

  tags = local.tags

  lifecycle {
    enabled = local.create_log_group
  }
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  description = var.deployment_description
  variables   = var.deployment_variables

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.this.body))
  }

  lifecycle {
    enabled               = local.enabled
    create_before_destroy = true
  }
  depends_on = [aws_api_gateway_rest_api_policy.this]
}

resource "aws_api_gateway_stage" "this" {
  deployment_id         = aws_api_gateway_deployment.this.id
  rest_api_id           = aws_api_gateway_rest_api.this.id
  stage_name            = var.stage_name
  xray_tracing_enabled  = var.xray_tracing_enabled
  description           = var.stage_description
  documentation_version = var.documentation_version
  client_certificate_id = var.client_certificate_id
  cache_cluster_enabled = var.cache_cluster_enabled
  cache_cluster_size    = var.cache_cluster_size
  tags                  = local.tags

  variables = merge(
    var.stage_variables,
    local.vpc_link_enabled ? { vpc_link_id = aws_api_gateway_vpc_link.this.id } : {}
  )

  dynamic "access_log_settings" {
    for_each = local.create_log_group ? [1] : []

    content {
      destination_arn = local.log_group_arn
      format          = replace(var.access_log_format, "\n", "")
    }
  }

  dynamic "canary_settings" {
    for_each = var.canary_settings != null ? [var.canary_settings] : []

    content {
      deployment_id            = try(canary_settings.value.deployment_id, aws_api_gateway_deployment.this.id)
      percent_traffic          = try(canary_settings.value.percent_traffic, null)
      stage_variable_overrides = try(canary_settings.value.stage_variable_overrides, null)
      use_stage_cache          = try(canary_settings.value.use_stage_cache, null)
    }
  }

  lifecycle {
    enabled = local.enabled
  }
}

#Set the logging, metrics and tracing levels for all methods
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled                            = var.metrics_enabled
    logging_level                              = var.logging_level
    data_trace_enabled                         = var.data_trace_enabled
    throttling_burst_limit                     = var.throttling_burst_limit
    throttling_rate_limit                      = var.throttling_rate_limit
    caching_enabled                            = var.caching_enabled
    cache_ttl_in_seconds                       = var.cache_ttl_in_seconds
    cache_data_encrypted                       = var.cache_data_encrypted
    require_authorization_for_cache_control    = var.require_authorization_for_cache_control
    unauthorized_cache_control_header_strategy = var.unauthorized_cache_control_header_strategy
  }

  lifecycle {
    enabled = local.aws_api_gateway_method_settings_enabled
  }
}

#Optionally create a VPC Link to allow the API Gateway to communicate with private resources (e.g. ALB)
resource "aws_api_gateway_vpc_link" "this" {
  name        = var.name
  description = "VPC Link for ${var.name}"
  target_arns = var.private_link_target_arns
  tags        = local.tags

  lifecycle {
    enabled = local.vpc_link_enabled
  }
}

resource "aws_api_gateway_resource" "api_resources" {
  for_each    = local.enabled && var.create_rest_api_gateway_resource ? var.api_resources : {}
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = try(each.value.parent_id, aws_api_gateway_rest_api.this.root_resource_id)
  path_part   = each.value.path_part
}
