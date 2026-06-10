data "aws_partition" "current" {}

locals {
  enabled                                 = var.enabled
  name                                    = var.name
  create_rest_api_policy                  = local.enabled && var.rest_api_policy != null
  create_log_group                        = local.enabled && var.logging_level != "OFF"
  create_api_gateway_account              = local.enabled && var.create_api_gateway_account
  log_group_arn                           = try(aws_cloudwatch_log_group.this.arn, null)
  vpc_link_enabled                        = local.enabled && length(var.private_link_target_arns) > 0
  aws_api_gateway_method_settings_enabled = local.enabled && var.logging_level != "OFF"
  create_domain_name                      = local.enabled && var.domain_name != null
  create_waf_association                  = local.enabled && var.waf_web_acl_arn != null

  # Custom domains only support EDGE and REGIONAL endpoint configurations.
  domain_endpoint_type = var.endpoint_type == "EDGE" ? "EDGE" : "REGIONAL"

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
    Region    = data.aws_region.current.region
  })
}

resource "aws_api_gateway_rest_api" "this" {
  name                         = local.name
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
  name              = "/aws/apigateway/${local.name}"
  retention_in_days = var.log_group_retention_in_days
  kms_key_id        = var.log_group_kms_key_id
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

  # Redeploy whenever the API definition or anything affecting its behavior
  # changes: body, deployment variables, resource policy, or import parameters.
  triggers = {
    redeployment = sha1(jsonencode({
      body                 = aws_api_gateway_rest_api.this.body
      deployment_variables = var.deployment_variables
      policy               = var.rest_api_policy
      inline_policy        = var.rest_api_inline_policy
      parameters           = var.parameters
    }))
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
  name        = local.name
  description = "VPC Link for ${local.name}"
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

################################################################################
# API Gateway Account (region-wide CloudWatch logging role)
################################################################################

# API Gateway requires a region-wide account-level CloudWatch role before any
# stage can push execution logs. This is a singleton per region/account -
# enable it here only if it is not already managed elsewhere.
resource "aws_iam_role" "api_gateway_account" {
  name = "${local.name}-apigateway-cloudwatch"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags

  lifecycle {
    enabled = local.create_api_gateway_account
  }
}

resource "aws_iam_role_policy_attachment" "api_gateway_account" {
  role       = aws_iam_role.api_gateway_account.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"

  lifecycle {
    enabled = local.create_api_gateway_account
  }
}

resource "aws_api_gateway_account" "this" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_account.arn

  depends_on = [aws_iam_role_policy_attachment.api_gateway_account]

  lifecycle {
    enabled = local.create_api_gateway_account
  }
}

################################################################################
# Usage Plans & API Keys
################################################################################

resource "aws_api_gateway_usage_plan" "this" {
  for_each = { for k, v in var.usage_plans : k => v if local.enabled }

  name         = "${local.name}-${each.key}"
  description  = each.value.description
  product_code = each.value.product_code
  tags         = local.tags

  api_stages {
    api_id = aws_api_gateway_rest_api.this.id
    stage  = aws_api_gateway_stage.this.stage_name

    dynamic "throttle" {
      for_each = each.value.method_throttle

      content {
        path        = throttle.value.path
        burst_limit = throttle.value.burst_limit
        rate_limit  = throttle.value.rate_limit
      }
    }
  }

  dynamic "quota_settings" {
    for_each = each.value.quota_settings != null ? [each.value.quota_settings] : []

    content {
      limit  = quota_settings.value.limit
      offset = quota_settings.value.offset
      period = quota_settings.value.period
    }
  }

  dynamic "throttle_settings" {
    for_each = each.value.throttle_settings != null ? [each.value.throttle_settings] : []

    content {
      burst_limit = throttle_settings.value.burst_limit
      rate_limit  = throttle_settings.value.rate_limit
    }
  }
}

resource "aws_api_gateway_api_key" "this" {
  for_each = { for k, v in var.api_keys : k => v if local.enabled }

  name        = "${local.name}-${each.key}"
  description = each.value.description
  enabled     = each.value.enabled
  tags        = local.tags
}

resource "aws_api_gateway_usage_plan_key" "this" {
  for_each = { for k, v in var.api_keys : k => v if local.enabled && v.usage_plan_key != null }

  key_id        = aws_api_gateway_api_key.this[each.key].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.this[each.value.usage_plan_key].id
}

################################################################################
# Custom Domain
################################################################################

resource "aws_api_gateway_domain_name" "this" {
  domain_name              = var.domain_name
  certificate_arn          = local.domain_endpoint_type == "EDGE" ? var.domain_certificate_arn : null
  regional_certificate_arn = local.domain_endpoint_type == "REGIONAL" ? var.domain_certificate_arn : null
  security_policy          = var.domain_security_policy
  tags                     = local.tags

  endpoint_configuration {
    types = [local.domain_endpoint_type]
  }

  lifecycle {
    enabled = local.create_domain_name
  }
}

resource "aws_api_gateway_base_path_mapping" "this" {
  api_id      = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  domain_name = aws_api_gateway_domain_name.this.domain_name
  base_path   = var.domain_base_path

  lifecycle {
    enabled = local.create_domain_name
  }
}

################################################################################
# WAF Web ACL Association
################################################################################

resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = aws_api_gateway_stage.this.arn
  web_acl_arn  = var.waf_web_acl_arn

  lifecycle {
    enabled = local.create_waf_association
  }
}

data "aws_region" "current" {}
