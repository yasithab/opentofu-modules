data "aws_partition" "current" {}

locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  partition = data.aws_partition.current.partition
}

################################################################################
# GraphQL API
################################################################################

resource "aws_appsync_graphql_api" "this" {
  name                 = var.name
  authentication_type  = var.authentication_type
  schema               = var.schema
  xray_enabled         = var.xray_enabled
  introspection_config = var.introspection_config
  query_depth_limit    = var.query_depth_limit
  resolver_count_limit = var.resolver_count_limit
  visibility           = var.visibility

  dynamic "log_config" {
    for_each = var.logging_enabled ? [1] : []

    content {
      cloudwatch_logs_role_arn = var.create_logging_role ? aws_iam_role.logging.arn : var.logging_role_arn
      field_log_level          = var.log_field_log_level
      exclude_verbose_content  = var.log_exclude_verbose_content
    }
  }

  dynamic "user_pool_config" {
    for_each = var.authentication_type == "AMAZON_COGNITO_USER_POOLS" && var.user_pool_config != null ? [var.user_pool_config] : []

    content {
      default_action      = try(user_pool_config.value.default_action, "DENY")
      user_pool_id        = user_pool_config.value.user_pool_id
      app_id_client_regex = try(user_pool_config.value.app_id_client_regex, null)
      aws_region          = try(user_pool_config.value.aws_region, null)
    }
  }

  dynamic "openid_connect_config" {
    for_each = var.authentication_type == "OPENID_CONNECT" && var.openid_connect_config != null ? [var.openid_connect_config] : []

    content {
      issuer    = openid_connect_config.value.issuer
      auth_ttl  = try(openid_connect_config.value.auth_ttl, null)
      client_id = try(openid_connect_config.value.client_id, null)
      iat_ttl   = try(openid_connect_config.value.iat_ttl, null)
    }
  }

  dynamic "lambda_authorizer_config" {
    for_each = var.authentication_type == "AWS_LAMBDA" && var.lambda_authorizer_config != null ? [var.lambda_authorizer_config] : []

    content {
      authorizer_uri                   = lambda_authorizer_config.value.authorizer_uri
      authorizer_result_ttl_in_seconds = try(lambda_authorizer_config.value.authorizer_result_ttl_in_seconds, 300)
      identity_validation_expression   = try(lambda_authorizer_config.value.identity_validation_expression, null)
    }
  }

  dynamic "additional_authentication_provider" {
    for_each = var.additional_authentication_providers

    content {
      authentication_type = additional_authentication_provider.value.authentication_type

      dynamic "user_pool_config" {
        for_each = additional_authentication_provider.value.authentication_type == "AMAZON_COGNITO_USER_POOLS" ? [try(additional_authentication_provider.value.user_pool_config, {})] : []

        content {
          user_pool_id        = user_pool_config.value.user_pool_id
          app_id_client_regex = try(user_pool_config.value.app_id_client_regex, null)
          aws_region          = try(user_pool_config.value.aws_region, null)
        }
      }

      dynamic "openid_connect_config" {
        for_each = additional_authentication_provider.value.authentication_type == "OPENID_CONNECT" ? [try(additional_authentication_provider.value.openid_connect_config, {})] : []

        content {
          issuer    = openid_connect_config.value.issuer
          auth_ttl  = try(openid_connect_config.value.auth_ttl, null)
          client_id = try(openid_connect_config.value.client_id, null)
          iat_ttl   = try(openid_connect_config.value.iat_ttl, null)
        }
      }

      dynamic "lambda_authorizer_config" {
        for_each = additional_authentication_provider.value.authentication_type == "AWS_LAMBDA" ? [try(additional_authentication_provider.value.lambda_authorizer_config, {})] : []

        content {
          authorizer_uri                   = lambda_authorizer_config.value.authorizer_uri
          authorizer_result_ttl_in_seconds = try(lambda_authorizer_config.value.authorizer_result_ttl_in_seconds, 300)
          identity_validation_expression   = try(lambda_authorizer_config.value.identity_validation_expression, null)
        }
      }
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# API Key
################################################################################

resource "aws_appsync_api_key" "this" {
  for_each = { for k, v in var.api_keys : k => v if local.enabled }

  api_id      = aws_appsync_graphql_api.this.id
  description = try(each.value.description, null)
  expires     = try(each.value.expires, null)
}

################################################################################
# Data Sources
################################################################################

resource "aws_appsync_datasource" "this" {
  for_each = { for k, v in var.datasources : k => v if local.enabled }

  api_id           = aws_appsync_graphql_api.this.id
  name             = each.value.name
  type             = each.value.type
  description      = try(each.value.description, null)
  service_role_arn = try(each.value.service_role_arn, null)

  dynamic "dynamodb_config" {
    for_each = each.value.type == "AMAZON_DYNAMODB" ? [try(each.value.dynamodb_config, {})] : []

    content {
      table_name             = dynamodb_config.value.table_name
      region                 = try(dynamodb_config.value.region, null)
      use_caller_credentials = try(dynamodb_config.value.use_caller_credentials, false)
      versioned              = try(dynamodb_config.value.versioned, false)

      dynamic "delta_sync_config" {
        for_each = try(dynamodb_config.value.delta_sync_config, null) != null ? [dynamodb_config.value.delta_sync_config] : []

        content {
          base_table_ttl        = try(delta_sync_config.value.base_table_ttl, null)
          delta_sync_table_name = delta_sync_config.value.delta_sync_table_name
          delta_sync_table_ttl  = try(delta_sync_config.value.delta_sync_table_ttl, null)
        }
      }
    }
  }

  dynamic "lambda_config" {
    for_each = each.value.type == "AWS_LAMBDA" ? [try(each.value.lambda_config, {})] : []

    content {
      function_arn = lambda_config.value.function_arn
    }
  }

  dynamic "http_config" {
    for_each = each.value.type == "HTTP" ? [try(each.value.http_config, {})] : []

    content {
      endpoint = http_config.value.endpoint

      dynamic "authorization_config" {
        for_each = try(http_config.value.authorization_config, null) != null ? [http_config.value.authorization_config] : []

        content {
          authorization_type = try(authorization_config.value.authorization_type, "AWS_IAM")

          dynamic "aws_iam_config" {
            for_each = try(authorization_config.value.aws_iam_config, null) != null ? [authorization_config.value.aws_iam_config] : []

            content {
              signing_region       = try(aws_iam_config.value.signing_region, null)
              signing_service_name = try(aws_iam_config.value.signing_service_name, null)
            }
          }
        }
      }
    }
  }

  dynamic "relational_database_config" {
    for_each = each.value.type == "RELATIONAL_DATABASE" ? [try(each.value.relational_database_config, {})] : []

    content {
      source_type = try(relational_database_config.value.source_type, "RDS_HTTP_ENDPOINT")

      dynamic "http_endpoint_config" {
        for_each = try(relational_database_config.value.http_endpoint_config, null) != null ? [relational_database_config.value.http_endpoint_config] : []

        content {
          aws_secret_store_arn  = http_endpoint_config.value.aws_secret_store_arn
          db_cluster_identifier = http_endpoint_config.value.db_cluster_identifier
          database_name         = try(http_endpoint_config.value.database_name, null)
          region                = try(http_endpoint_config.value.region, null)
          schema                = try(http_endpoint_config.value.schema, null)
        }
      }
    }
  }

  dynamic "elasticsearch_config" {
    for_each = each.value.type == "AMAZON_ELASTICSEARCH" || each.value.type == "AMAZON_OPENSEARCH_SERVICE" ? [try(each.value.elasticsearch_config, each.value.opensearch_config, {})] : []

    content {
      endpoint = elasticsearch_config.value.endpoint
      region   = try(elasticsearch_config.value.region, null)
    }
  }

  dynamic "event_bridge_config" {
    for_each = each.value.type == "AMAZON_EVENTBRIDGE" ? [try(each.value.event_bridge_config, {})] : []

    content {
      event_bus_arn = event_bridge_config.value.event_bus_arn
    }
  }
}

################################################################################
# Functions
################################################################################

resource "aws_appsync_function" "this" {
  for_each = { for k, v in var.functions : k => v if local.enabled }

  api_id      = aws_appsync_graphql_api.this.id
  name        = each.value.name
  description = try(each.value.description, null)

  data_source = try(
    aws_appsync_datasource.this[each.value.datasource_key].name,
    each.value.data_source
  )

  request_mapping_template  = try(each.value.request_mapping_template, null)
  response_mapping_template = try(each.value.response_mapping_template, null)
  function_version          = try(each.value.function_version, null)
  max_batch_size            = try(each.value.max_batch_size, null)
  code                      = try(each.value.code, null)

  dynamic "runtime" {
    for_each = try(each.value.runtime, null) != null ? [each.value.runtime] : []

    content {
      name            = runtime.value.name
      runtime_version = runtime.value.runtime_version
    }
  }

  dynamic "sync_config" {
    for_each = try(each.value.sync_config, null) != null ? [each.value.sync_config] : []

    content {
      conflict_detection = try(sync_config.value.conflict_detection, "VERSION")
      conflict_handler   = try(sync_config.value.conflict_handler, "OPTIMISTIC_CONCURRENCY")

      dynamic "lambda_conflict_handler_config" {
        for_each = try(sync_config.value.lambda_conflict_handler_arn, null) != null ? [1] : []

        content {
          lambda_conflict_handler_arn = sync_config.value.lambda_conflict_handler_arn
        }
      }
    }
  }
}

################################################################################
# Resolvers
################################################################################

resource "aws_appsync_resolver" "this" {
  for_each = { for k, v in var.resolvers : k => v if local.enabled }

  api_id = aws_appsync_graphql_api.this.id
  type   = each.value.type
  field  = each.value.field
  kind   = try(each.value.kind, "UNIT")

  data_source = try(each.value.kind, "UNIT") == "UNIT" ? try(
    aws_appsync_datasource.this[each.value.datasource_key].name,
    each.value.data_source,
    null
  ) : null

  request_template  = try(each.value.request_template, null)
  response_template = try(each.value.response_template, null)
  max_batch_size    = try(each.value.max_batch_size, null)
  code              = try(each.value.code, null)

  dynamic "pipeline_config" {
    for_each = try(each.value.kind, "UNIT") == "PIPELINE" ? [1] : []

    content {
      functions = [
        for fn_key in try(each.value.pipeline_functions, []) : try(
          aws_appsync_function.this[fn_key].function_id,
          fn_key
        )
      ]
    }
  }

  dynamic "runtime" {
    for_each = try(each.value.runtime, null) != null ? [each.value.runtime] : []

    content {
      name            = runtime.value.name
      runtime_version = runtime.value.runtime_version
    }
  }

  dynamic "caching_config" {
    for_each = try(each.value.caching_config, null) != null ? [each.value.caching_config] : []

    content {
      caching_keys = try(caching_config.value.caching_keys, null)
      ttl          = try(caching_config.value.ttl, 3600)
    }
  }

  dynamic "sync_config" {
    for_each = try(each.value.sync_config, null) != null ? [each.value.sync_config] : []

    content {
      conflict_detection = try(sync_config.value.conflict_detection, "VERSION")
      conflict_handler   = try(sync_config.value.conflict_handler, "OPTIMISTIC_CONCURRENCY")

      dynamic "lambda_conflict_handler_config" {
        for_each = try(sync_config.value.lambda_conflict_handler_arn, null) != null ? [1] : []

        content {
          lambda_conflict_handler_arn = sync_config.value.lambda_conflict_handler_arn
        }
      }
    }
  }
}

################################################################################
# API Cache
################################################################################

resource "aws_appsync_api_cache" "this" {
  api_id                     = aws_appsync_graphql_api.this.id
  api_caching_behavior       = var.cache_api_caching_behavior
  type                       = var.cache_type
  ttl                        = var.cache_ttl
  transit_encryption_enabled = var.cache_transit_encryption_enabled
  at_rest_encryption_enabled = var.cache_at_rest_encryption_enabled

  lifecycle {
    enabled = local.enabled && var.create_api_cache
  }
}

################################################################################
# Domain Name
################################################################################

resource "aws_appsync_domain_name" "this" {
  domain_name     = var.domain_name
  certificate_arn = var.domain_certificate_arn
  description     = try(var.domain_description, null)

  lifecycle {
    enabled = local.enabled && var.create_domain_name
  }
}

resource "aws_appsync_domain_name_api_association" "this" {
  api_id      = aws_appsync_graphql_api.this.id
  domain_name = aws_appsync_domain_name.this.domain_name

  lifecycle {
    enabled = local.enabled && var.create_domain_name
  }
}

################################################################################
# WAF Association
################################################################################

resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = aws_appsync_graphql_api.this.arn
  web_acl_arn  = var.waf_web_acl_arn

  lifecycle {
    enabled = local.enabled && var.waf_web_acl_arn != null
  }
}

################################################################################
# IAM - Logging Role
################################################################################

resource "aws_iam_role" "logging" {
  name = "${var.name}-appsync-logging"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "appsync.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_logging_role && var.logging_enabled
  }
}

resource "aws_iam_role_policy_attachment" "logging" {
  role       = aws_iam_role.logging.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSAppSyncPushToCloudWatchLogs"

  lifecycle {
    enabled = local.enabled && var.create_logging_role && var.logging_enabled
  }
}
