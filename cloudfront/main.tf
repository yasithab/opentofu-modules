locals {
  enabled                        = var.enabled
  create_origin_access_identity  = local.enabled && var.create_origin_access_identity && length(keys(var.origin_access_identities)) > 0
  create_origin_access_control   = local.enabled && var.create_origin_access_control && length(keys(var.origin_access_control)) > 0
  create_vpc_origin              = local.enabled && var.create_vpc_origin && length(keys(var.vpc_origin)) > 0
  create_monitoring_subscription = local.enabled && var.create_monitoring_subscription

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

###################################################
# Cache Policies
###################################################
resource "aws_cloudfront_cache_policy" "this" {
  for_each = { for k, v in var.cache_policies : k => v if local.enabled }

  name    = each.key
  comment = try(each.value.comment, null)

  default_ttl = try(each.value.default_ttl, 86400)
  max_ttl     = try(each.value.max_ttl, 31536000)
  min_ttl     = try(each.value.min_ttl, 0)

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = try(each.value.enable_accept_encoding_brotli, true)
    enable_accept_encoding_gzip   = try(each.value.enable_accept_encoding_gzip, true)

    cookies_config {
      cookie_behavior = try(each.value.cookie_behavior, "none")
      dynamic "cookies" {
        for_each = length(try(each.value.cookies_items, [])) > 0 ? [1] : []
        content { items = each.value.cookies_items }
      }
    }

    headers_config {
      header_behavior = try(each.value.header_behavior, "none")
      dynamic "headers" {
        for_each = length(try(each.value.headers_items, [])) > 0 ? [1] : []
        content { items = each.value.headers_items }
      }
    }

    query_strings_config {
      query_string_behavior = try(each.value.query_string_behavior, "none")
      dynamic "query_strings" {
        for_each = length(try(each.value.query_strings_items, [])) > 0 ? [1] : []
        content { items = each.value.query_strings_items }
      }
    }
  }
}

###################################################
# Origin Request Policies
###################################################
resource "aws_cloudfront_origin_request_policy" "this" {
  for_each = { for k, v in var.origin_request_policies : k => v if local.enabled }

  name    = each.key
  comment = try(each.value.comment, null)

  cookies_config {
    cookie_behavior = try(each.value.cookie_behavior, "none")
    dynamic "cookies" {
      for_each = length(try(each.value.cookies_items, [])) > 0 ? [1] : []
      content { items = each.value.cookies_items }
    }
  }

  headers_config {
    header_behavior = try(each.value.header_behavior, "none")
    dynamic "headers" {
      for_each = length(try(each.value.headers_items, [])) > 0 ? [1] : []
      content { items = each.value.headers_items }
    }
  }

  query_strings_config {
    query_string_behavior = try(each.value.query_string_behavior, "none")
    dynamic "query_strings" {
      for_each = length(try(each.value.query_strings_items, [])) > 0 ? [1] : []
      content { items = each.value.query_strings_items }
    }
  }
}

###################################################
# Response Headers Policies
###################################################
resource "aws_cloudfront_response_headers_policy" "this" {
  for_each = { for k, v in var.response_headers_policies : k => v if local.enabled }

  name    = each.key
  comment = try(each.value.comment, null)

  dynamic "cors_config" {
    for_each = try(each.value.cors.enabled, false) ? [each.value.cors] : []
    iterator = cors
    content {
      origin_override                  = try(cors.value.override, true)
      access_control_allow_credentials = try(cors.value.access_control_allow_credentials, false)
      access_control_allow_headers { items = try(cors.value.access_control_allow_headers, ["*"]) }
      access_control_allow_methods { items = try(cors.value.access_control_allow_methods, ["ALL"]) }
      access_control_allow_origins { items = try(cors.value.access_control_allow_origins, ["*"]) }
      dynamic "access_control_expose_headers" {
        for_each = length(try(cors.value.access_control_expose_headers, [])) > 0 ? [cors.value.access_control_expose_headers] : []
        content { items = access_control_expose_headers.value }
      }
      access_control_max_age_sec = try(cors.value.access_control_max_age, 600)
    }
  }

  dynamic "custom_headers_config" {
    for_each = length(try(each.value.custom_headers, [])) > 0 ? [1] : []
    content {
      dynamic "items" {
        for_each = each.value.custom_headers
        content {
          header   = items.value.name
          value    = items.value.value
          override = try(items.value.override, false)
        }
      }
    }
  }

  remove_headers_config {
    dynamic "items" {
      for_each = try(each.value.remove_headers, [])
      content { header = items.value }
    }
  }

  dynamic "security_headers_config" {
    for_each = anytrue([
      try(each.value.content_security_policy_header.enabled, false),
      try(each.value.content_type_options_header.enabled, false),
      try(each.value.frame_options_header.enabled, false),
      try(each.value.referrer_policy_header.enabled, false),
      try(each.value.strict_transport_security_header.enabled, false),
      try(each.value.xss_protection_header.enabled, false),
    ]) ? [1] : []
    content {
      dynamic "content_security_policy" {
        for_each = try(each.value.content_security_policy_header.enabled, false) ? [each.value.content_security_policy_header] : []
        iterator = h
        content {
          override                = try(h.value.override, true)
          content_security_policy = try(h.value.value, "")
        }
      }
      dynamic "content_type_options" {
        for_each = try(each.value.content_type_options_header.enabled, false) ? [each.value.content_type_options_header] : []
        iterator = h
        content { override = try(h.value.override, true) }
      }
      dynamic "frame_options" {
        for_each = try(each.value.frame_options_header.enabled, false) ? [each.value.frame_options_header] : []
        iterator = h
        content {
          override     = try(h.value.override, true)
          frame_option = try(h.value.value, "SAMEORIGIN")
        }
      }
      dynamic "referrer_policy" {
        for_each = try(each.value.referrer_policy_header.enabled, false) ? [each.value.referrer_policy_header] : []
        iterator = h
        content {
          override        = try(h.value.override, true)
          referrer_policy = try(h.value.value, "strict-origin-when-cross-origin")
        }
      }
      dynamic "strict_transport_security" {
        for_each = try(each.value.strict_transport_security_header.enabled, false) ? [each.value.strict_transport_security_header] : []
        iterator = h
        content {
          override                   = try(h.value.override, true)
          access_control_max_age_sec = try(h.value.max_age, 31536000)
          include_subdomains         = try(h.value.include_subdomains, false)
          preload                    = try(h.value.preload, false)
        }
      }
      dynamic "xss_protection" {
        for_each = try(each.value.xss_protection_header.enabled, false) ? [each.value.xss_protection_header] : []
        iterator = h
        content {
          override   = try(h.value.override, true)
          protection = try(h.value.filtering_enabled, true)
          mode_block = try(h.value.block, false)
          report_uri = try(h.value.report, null)
        }
      }
    }
  }

  server_timing_headers_config {
    enabled       = try(each.value.server_timing_header.enabled, false)
    sampling_rate = try(each.value.server_timing_header.sampling_rate, 0)
  }
}

###################################################
# Key-Value Stores
###################################################
resource "aws_cloudfront_key_value_store" "this" {
  for_each = { for k, v in var.key_value_stores : k => v if local.enabled }

  name    = each.key
  comment = try(each.value.comment, null)
}

###################################################
# CloudFront Functions
###################################################
resource "aws_cloudfront_function" "this" {
  for_each = { for k, v in var.functions : k => v if local.enabled }

  name    = each.key
  runtime = each.value.runtime
  code    = each.value.code
  comment = try(each.value.comment, null)
  publish = try(each.value.publish, true)

  # Resolve key_value_store_associations: list of ARNs or names of inline KVS
  key_value_store_associations = try([
    for ref in each.value.key_value_store_associations :
    try(aws_cloudfront_key_value_store.this[ref].arn, ref)
  ], null)
}

###################################################
# Public Keys
###################################################
resource "aws_cloudfront_public_key" "this" {
  for_each = { for k, v in var.public_keys : k => v if local.enabled }

  name        = each.key
  encoded_key = each.value.encoded_key
  comment     = try(each.value.comment, null)
}

###################################################
# Key Groups
###################################################
resource "aws_cloudfront_key_group" "this" {
  for_each = { for k, v in var.key_groups : k => v if local.enabled }

  name    = each.key
  comment = try(each.value.comment, null)

  # Resolve items: list of public key IDs or names of inline public keys
  items = [
    for ref in each.value.items :
    try(aws_cloudfront_public_key.this[ref].id, ref)
  ]
}

###################################################
# Real-time Log Configs
###################################################
resource "aws_cloudfront_realtime_log_config" "this" {
  for_each = { for k, v in var.realtime_log_configs : k => v if local.enabled }

  name          = each.key
  sampling_rate = each.value.sampling_rate
  fields        = each.value.fields

  endpoint {
    stream_type = try(each.value.stream_type, "Kinesis")

    kinesis_stream_config {
      role_arn   = each.value.kinesis_stream_config.role_arn
      stream_arn = each.value.kinesis_stream_config.stream_arn
    }
  }
}

###################################################
# Continuous Deployment Policies
###################################################
resource "aws_cloudfront_continuous_deployment_policy" "this" {
  for_each = { for k, v in var.continuous_deployment_policies : k => v if local.enabled }

  enabled = try(each.value.policy_enabled, true)

  dynamic "staging_distribution_dns_names" {
    for_each = try(each.value.staging_distribution_dns_names, null) != null ? [each.value.staging_distribution_dns_names] : []
    content {
      items    = try(staging_distribution_dns_names.value.items, null)
      quantity = staging_distribution_dns_names.value.quantity
    }
  }

  dynamic "traffic_config" {
    for_each = try(each.value.traffic_config, null) != null ? [each.value.traffic_config] : []
    content {
      type = traffic_config.value.type

      dynamic "single_weight_config" {
        for_each = try(traffic_config.value.single_weight_config, null) != null ? [traffic_config.value.single_weight_config] : []
        content {
          weight = single_weight_config.value.weight

          dynamic "session_stickiness_config" {
            for_each = try(single_weight_config.value.session_stickiness_config, null) != null ? [single_weight_config.value.session_stickiness_config] : []
            content {
              idle_ttl    = session_stickiness_config.value.idle_ttl
              maximum_ttl = session_stickiness_config.value.maximum_ttl
            }
          }
        }
      }

      dynamic "single_header_config" {
        for_each = try(traffic_config.value.single_header_config, null) != null ? [traffic_config.value.single_header_config] : []
        content {
          header = single_header_config.value.header
          value  = single_header_config.value.value
        }
      }
    }
  }
}

resource "aws_cloudfront_origin_access_identity" "this" {
  for_each = local.create_origin_access_identity ? var.origin_access_identities : {}

  comment = each.value

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudfront_origin_access_control" "this" {
  for_each = local.create_origin_access_control ? var.origin_access_control : {}

  name = each.key

  description                       = each.value["description"]
  origin_access_control_origin_type = each.value["origin_type"]
  signing_behavior                  = each.value["signing_behavior"]
  signing_protocol                  = each.value["signing_protocol"]
}

resource "aws_cloudfront_vpc_origin" "this" {
  for_each = local.create_vpc_origin ? var.vpc_origin : {}

  vpc_origin_endpoint_config {
    name                   = each.value["name"]
    arn                    = each.value["arn"]
    http_port              = each.value["http_port"]
    https_port             = each.value["https_port"]
    origin_protocol_policy = each.value["origin_protocol_policy"]

    origin_ssl_protocols {
      items    = each.value.origin_ssl_protocols.items
      quantity = each.value.origin_ssl_protocols.quantity
    }
  }

  tags = local.tags
}

resource "aws_cloudfront_distribution" "this" {
  aliases                         = var.aliases
  anycast_ip_list_id              = var.anycast_ip_list_id
  comment                         = var.comment
  continuous_deployment_policy_id = var.continuous_deployment_policy_id
  default_root_object             = var.default_root_object
  enabled                         = var.distribution_enabled
  http_version                    = var.http_version
  is_ipv6_enabled                 = var.is_ipv6_enabled
  price_class                     = var.price_class
  retain_on_delete                = var.retain_on_delete
  staging                         = var.staging
  wait_for_deployment             = var.wait_for_deployment
  web_acl_id                      = var.web_acl_id

  tags = local.tags

  dynamic "logging_config" {
    for_each = var.logging_config != null ? [var.logging_config] : []

    content {
      bucket          = logging_config.value.bucket
      prefix          = logging_config.value.prefix
      include_cookies = logging_config.value.include_cookies
    }
  }

  dynamic "origin" {
    for_each = var.origin

    content {
      domain_name                 = origin.value.domain_name
      origin_id                   = coalesce(origin.value.origin_id, origin.key)
      origin_path                 = origin.value.origin_path
      connection_attempts         = origin.value.connection_attempts
      connection_timeout          = origin.value.connection_timeout
      response_completion_timeout = origin.value.response_completion_timeout
      origin_access_control_id = origin.value.origin_access_control_id != null ? origin.value.origin_access_control_id : (
        origin.value.origin_access_control != null ? try(aws_cloudfront_origin_access_control.this[origin.value.origin_access_control].id, null) : null
      )

      dynamic "s3_origin_config" {
        for_each = origin.value.s3_origin_config != null ? [origin.value.s3_origin_config] : []

        content {
          origin_access_identity = s3_origin_config.value.cloudfront_access_identity_path != null ? s3_origin_config.value.cloudfront_access_identity_path : try(aws_cloudfront_origin_access_identity.this[s3_origin_config.value.origin_access_identity].cloudfront_access_identity_path, null)
        }
      }

      dynamic "custom_origin_config" {
        for_each = origin.value.custom_origin_config != null ? [origin.value.custom_origin_config] : []

        content {
          http_port                = custom_origin_config.value.http_port
          https_port               = custom_origin_config.value.https_port
          origin_protocol_policy   = custom_origin_config.value.origin_protocol_policy
          origin_ssl_protocols     = custom_origin_config.value.origin_ssl_protocols
          origin_keepalive_timeout = custom_origin_config.value.origin_keepalive_timeout
          origin_read_timeout      = custom_origin_config.value.origin_read_timeout
          ip_address_type          = custom_origin_config.value.ip_address_type
        }
      }

      dynamic "custom_header" {
        for_each = origin.value.custom_headers

        content {
          name  = custom_header.key
          value = custom_header.value
        }
      }

      dynamic "origin_shield" {
        for_each = origin.value.origin_shield != null ? [origin.value.origin_shield] : []

        content {
          enabled              = origin_shield.value.enabled
          origin_shield_region = origin_shield.value.origin_shield_region
        }
      }

      dynamic "vpc_origin_config" {
        for_each = origin.value.vpc_origin_config != null ? [origin.value.vpc_origin_config] : []

        content {
          vpc_origin_id = vpc_origin_config.value.vpc_origin_id != null ? vpc_origin_config.value.vpc_origin_id : (
            vpc_origin_config.value.vpc_origin != null ? try(aws_cloudfront_vpc_origin.this[vpc_origin_config.value.vpc_origin].id, null) : null
          )
          origin_keepalive_timeout = vpc_origin_config.value.origin_keepalive_timeout
          origin_read_timeout      = vpc_origin_config.value.origin_read_timeout
          owner_account_id         = vpc_origin_config.value.owner_account_id
        }
      }
    }
  }

  dynamic "origin_group" {
    for_each = var.origin_group

    content {
      origin_id = coalesce(origin_group.value.origin_id, origin_group.key)

      failover_criteria {
        status_codes = origin_group.value.failover_status_codes
      }

      member {
        origin_id = origin_group.value.primary_member_origin_id
      }

      member {
        origin_id = origin_group.value.secondary_member_origin_id
      }
    }
  }

  dynamic "default_cache_behavior" {
    for_each = [var.default_cache_behavior]
    iterator = i

    content {
      target_origin_id       = i.value.target_origin_id
      viewer_protocol_policy = i.value.viewer_protocol_policy

      allowed_methods           = i.value.allowed_methods
      cached_methods            = i.value.cached_methods
      compress                  = i.value.compress
      field_level_encryption_id = i.value.field_level_encryption_id
      smooth_streaming          = i.value.smooth_streaming
      trusted_signers           = i.value.trusted_signers
      trusted_key_groups        = i.value.trusted_key_groups

      cache_policy_id = i.value.cache_policy_id != null ? i.value.cache_policy_id : try(
        aws_cloudfront_cache_policy.this[i.value.cache_policy_name].id,
        data.aws_cloudfront_cache_policy.this[i.value.cache_policy_name].id,
        null,
      )
      origin_request_policy_id = i.value.origin_request_policy_id != null ? i.value.origin_request_policy_id : try(
        aws_cloudfront_origin_request_policy.this[i.value.origin_request_policy_name].id,
        data.aws_cloudfront_origin_request_policy.this[i.value.origin_request_policy_name].id,
        null,
      )
      response_headers_policy_id = i.value.response_headers_policy_id != null ? i.value.response_headers_policy_id : try(
        aws_cloudfront_response_headers_policy.this[i.value.response_headers_policy_name].id,
        data.aws_cloudfront_response_headers_policy.this[i.value.response_headers_policy_name].id,
        null,
      )

      realtime_log_config_arn = i.value.realtime_log_config_arn != null ? i.value.realtime_log_config_arn : try(
        aws_cloudfront_realtime_log_config.this[i.value.realtime_log_config_name].arn,
        null,
      )

      dynamic "lambda_function_association" {
        for_each = i.value.lambda_function_association
        iterator = l

        content {
          event_type   = l.value.event_type
          lambda_arn   = l.value.lambda_arn
          include_body = l.value.include_body
        }
      }

      dynamic "function_association" {
        for_each = i.value.function_association
        iterator = f

        content {
          event_type   = f.value.event_type
          function_arn = f.value.function_arn != null ? f.value.function_arn : try(aws_cloudfront_function.this[f.value.function_name].arn, null)
        }
      }

      dynamic "grpc_config" {
        for_each = i.value.grpc_config != null ? [i.value.grpc_config] : []

        content {
          enabled = grpc_config.value.enabled
        }
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behavior
    iterator = i

    content {
      path_pattern           = i.value.path_pattern
      target_origin_id       = i.value.target_origin_id
      viewer_protocol_policy = i.value.viewer_protocol_policy

      allowed_methods           = i.value.allowed_methods
      cached_methods            = i.value.cached_methods
      compress                  = i.value.compress
      field_level_encryption_id = i.value.field_level_encryption_id
      smooth_streaming          = i.value.smooth_streaming
      trusted_signers           = i.value.trusted_signers
      trusted_key_groups        = i.value.trusted_key_groups

      cache_policy_id = i.value.cache_policy_id != null ? i.value.cache_policy_id : try(
        aws_cloudfront_cache_policy.this[i.value.cache_policy_name].id,
        data.aws_cloudfront_cache_policy.this[i.value.cache_policy_name].id,
        null,
      )
      origin_request_policy_id = i.value.origin_request_policy_id != null ? i.value.origin_request_policy_id : try(
        aws_cloudfront_origin_request_policy.this[i.value.origin_request_policy_name].id,
        data.aws_cloudfront_origin_request_policy.this[i.value.origin_request_policy_name].id,
        null,
      )
      response_headers_policy_id = i.value.response_headers_policy_id != null ? i.value.response_headers_policy_id : try(
        aws_cloudfront_response_headers_policy.this[i.value.response_headers_policy_name].id,
        data.aws_cloudfront_response_headers_policy.this[i.value.response_headers_policy_name].id,
        null,
      )

      realtime_log_config_arn = i.value.realtime_log_config_arn != null ? i.value.realtime_log_config_arn : try(
        aws_cloudfront_realtime_log_config.this[i.value.realtime_log_config_name].arn,
        null,
      )

      dynamic "lambda_function_association" {
        for_each = i.value.lambda_function_association
        iterator = l

        content {
          event_type   = l.value.event_type
          lambda_arn   = l.value.lambda_arn
          include_body = l.value.include_body
        }
      }

      dynamic "function_association" {
        for_each = i.value.function_association
        iterator = f

        content {
          event_type   = f.value.event_type
          function_arn = f.value.function_arn != null ? f.value.function_arn : try(aws_cloudfront_function.this[f.value.function_name].arn, null)
        }
      }

      dynamic "grpc_config" {
        for_each = i.value.grpc_config != null ? [i.value.grpc_config] : []

        content {
          enabled = grpc_config.value.enabled
        }
      }
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.viewer_certificate.acm_certificate_arn
    cloudfront_default_certificate = var.viewer_certificate.cloudfront_default_certificate
    iam_certificate_id             = var.viewer_certificate.iam_certificate_id

    minimum_protocol_version = var.viewer_certificate.minimum_protocol_version
    ssl_support_method       = var.viewer_certificate.ssl_support_method
  }

  dynamic "viewer_mtls_config" {
    for_each = var.viewer_mtls_config != null ? [var.viewer_mtls_config] : []

    content {
      mode = try(viewer_mtls_config.value.mode, null)

      dynamic "trust_store_config" {
        for_each = try(viewer_mtls_config.value.trust_store_config, null) != null ? [viewer_mtls_config.value.trust_store_config] : []

        content {
          trust_store_id                 = trust_store_config.value.trust_store_id
          advertise_trust_store_ca_names = try(trust_store_config.value.advertise_trust_store_ca_names, null)
          ignore_certificate_expiry      = try(trust_store_config.value.ignore_certificate_expiry, null)
        }
      }
    }
  }

  dynamic "connection_function_association" {
    for_each = var.connection_function_association_id != null ? [var.connection_function_association_id] : []

    content {
      id = connection_function_association.value
    }
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_response

    content {
      error_code = custom_error_response.value.error_code

      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }

  restrictions {
    dynamic "geo_restriction" {
      for_each = [var.geo_restriction]

      content {
        restriction_type = lookup(geo_restriction.value, "restriction_type", "none")
        locations        = lookup(geo_restriction.value, "locations", [])
      }
    }
  }

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_cloudfront_monitoring_subscription" "this" {
  distribution_id = try(aws_cloudfront_distribution.this.id, null)

  monitoring_subscription {
    realtime_metrics_subscription_config {
      realtime_metrics_subscription_status = var.realtime_metrics_subscription_status
    }
  }

  lifecycle {
    enabled = local.create_monitoring_subscription
  }
}

data "aws_cloudfront_cache_policy" "this" {
  for_each = toset([
    for v in concat([var.default_cache_behavior], var.ordered_cache_behavior) :
    v.cache_policy_name
    if local.enabled && v.cache_policy_id == null && v.cache_policy_name != null && !contains(keys(var.cache_policies), v.cache_policy_name)
  ])
  name = each.key
}

data "aws_cloudfront_origin_request_policy" "this" {
  for_each = toset([
    for v in concat([var.default_cache_behavior], var.ordered_cache_behavior) :
    v.origin_request_policy_name
    if local.enabled && v.origin_request_policy_id == null && v.origin_request_policy_name != null && !contains(keys(var.origin_request_policies), v.origin_request_policy_name)
  ])
  name = each.key
}

data "aws_cloudfront_response_headers_policy" "this" {
  for_each = toset([
    for v in concat([var.default_cache_behavior], var.ordered_cache_behavior) :
    v.response_headers_policy_name
    if local.enabled && v.response_headers_policy_id == null && v.response_headers_policy_name != null && !contains(keys(var.response_headers_policies), v.response_headers_policy_name)
  ])
  name = each.key
}
