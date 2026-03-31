locals {
  enabled                       = var.enabled
  create_origin_access_identity = var.create_origin_access_identity && length(keys(var.origin_access_identities)) > 0
  create_origin_access_control  = var.create_origin_access_control && length(keys(var.origin_access_control)) > 0
  create_vpc_origin             = var.create_vpc_origin && length(keys(var.vpc_origin)) > 0

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

###################################################
# Cache Policies
###################################################
resource "aws_cloudfront_cache_policy" "this" {
  for_each = { for k, v in var.cache_policies : k => v if var.enabled }

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
  for_each = { for k, v in var.origin_request_policies : k => v if var.enabled }

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
  for_each = { for k, v in var.response_headers_policies : k => v if var.enabled }

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
  for_each = { for k, v in var.key_value_stores : k => v if var.enabled }

  name    = each.key
  comment = try(each.value.comment, null)
}

###################################################
# CloudFront Functions
###################################################
resource "aws_cloudfront_function" "this" {
  for_each = { for k, v in var.functions : k => v if var.enabled }

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
  for_each = { for k, v in var.public_keys : k => v if var.enabled }

  name        = each.key
  encoded_key = each.value.encoded_key
  comment     = try(each.value.comment, null)
}

###################################################
# Key Groups
###################################################
resource "aws_cloudfront_key_group" "this" {
  for_each = { for k, v in var.key_groups : k => v if var.enabled }

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
  for_each = { for k, v in var.realtime_log_configs : k => v if var.enabled }

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
  for_each = { for k, v in var.continuous_deployment_policies : k => v if var.enabled }

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
  count = var.enabled ? 1 : 0

  aliases                         = var.aliases
  anycast_ip_list_id              = var.anycast_ip_list_id
  comment                         = var.comment
  continuous_deployment_policy_id = var.continuous_deployment_policy_id
  default_root_object             = var.default_root_object
  enabled                         = local.enabled
  http_version                    = var.http_version
  is_ipv6_enabled                 = var.is_ipv6_enabled
  price_class                     = var.price_class
  retain_on_delete                = var.retain_on_delete
  staging                         = var.staging
  wait_for_deployment             = var.wait_for_deployment
  web_acl_id                      = var.web_acl_id

  tags = local.tags

  dynamic "logging_config" {
    for_each = length(keys(var.logging_config)) == 0 ? [] : [var.logging_config]

    content {
      bucket          = logging_config.value["bucket"]
      prefix          = lookup(logging_config.value, "prefix", null)
      include_cookies = lookup(logging_config.value, "include_cookies", null)
    }
  }

  dynamic "origin" {
    for_each = var.origin

    content {
      domain_name                 = origin.value.domain_name
      origin_id                   = lookup(origin.value, "origin_id", origin.key)
      origin_path                 = lookup(origin.value, "origin_path", "")
      connection_attempts         = lookup(origin.value, "connection_attempts", null)
      connection_timeout          = lookup(origin.value, "connection_timeout", null)
      response_completion_timeout = lookup(origin.value, "response_completion_timeout", null)
      origin_access_control_id    = lookup(origin.value, "origin_access_control_id", lookup(lookup(aws_cloudfront_origin_access_control.this, lookup(origin.value, "origin_access_control", ""), {}), "id", null))

      dynamic "s3_origin_config" {
        for_each = length(keys(lookup(origin.value, "s3_origin_config", {}))) == 0 ? [] : [lookup(origin.value, "s3_origin_config", {})]

        content {
          origin_access_identity = lookup(s3_origin_config.value, "cloudfront_access_identity_path", lookup(lookup(aws_cloudfront_origin_access_identity.this, lookup(s3_origin_config.value, "origin_access_identity", ""), {}), "cloudfront_access_identity_path", null))
        }
      }

      dynamic "custom_origin_config" {
        for_each = length(lookup(origin.value, "custom_origin_config", "")) == 0 ? [] : [lookup(origin.value, "custom_origin_config", "")]

        content {
          http_port                = custom_origin_config.value.http_port
          https_port               = custom_origin_config.value.https_port
          origin_protocol_policy   = custom_origin_config.value.origin_protocol_policy
          origin_ssl_protocols     = custom_origin_config.value.origin_ssl_protocols
          origin_keepalive_timeout = lookup(custom_origin_config.value, "origin_keepalive_timeout", null)
          origin_read_timeout      = lookup(custom_origin_config.value, "origin_read_timeout", null)
          ip_address_type          = try(custom_origin_config.value.ip_address_type, null)
        }
      }

      dynamic "custom_header" {
        for_each = lookup(origin.value, "custom_header", [])

        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }

      dynamic "origin_shield" {
        for_each = length(keys(lookup(origin.value, "origin_shield", {}))) == 0 ? [] : [lookup(origin.value, "origin_shield", {})]

        content {
          enabled              = origin_shield.value.enabled
          origin_shield_region = origin_shield.value.origin_shield_region
        }
      }

      dynamic "vpc_origin_config" {
        for_each = length(keys(lookup(origin.value, "vpc_origin_config", {}))) == 0 ? [] : [lookup(origin.value, "vpc_origin_config", {})]

        content {
          vpc_origin_id            = lookup(vpc_origin_config.value, "vpc_origin_id", lookup(lookup(aws_cloudfront_vpc_origin.this, lookup(vpc_origin_config.value, "vpc_origin", ""), {}), "id", null))
          origin_keepalive_timeout = lookup(vpc_origin_config.value, "origin_keepalive_timeout", null)
          origin_read_timeout      = lookup(vpc_origin_config.value, "origin_read_timeout", null)
          owner_account_id         = lookup(vpc_origin_config.value, "owner_account_id", null)
        }
      }
    }
  }

  dynamic "origin_group" {
    for_each = var.origin_group

    content {
      origin_id = lookup(origin_group.value, "origin_id", origin_group.key)

      failover_criteria {
        status_codes = origin_group.value["failover_status_codes"]
      }

      member {
        origin_id = origin_group.value["primary_member_origin_id"]
      }

      member {
        origin_id = origin_group.value["secondary_member_origin_id"]
      }
    }
  }

  dynamic "default_cache_behavior" {
    for_each = [var.default_cache_behavior]
    iterator = i

    content {
      target_origin_id       = i.value["target_origin_id"]
      viewer_protocol_policy = i.value["viewer_protocol_policy"]

      allowed_methods           = lookup(i.value, "allowed_methods", ["GET", "HEAD", "OPTIONS"])
      cached_methods            = lookup(i.value, "cached_methods", ["GET", "HEAD"])
      compress                  = lookup(i.value, "compress", null)
      field_level_encryption_id = lookup(i.value, "field_level_encryption_id", null)
      smooth_streaming          = lookup(i.value, "smooth_streaming", null)
      trusted_signers           = lookup(i.value, "trusted_signers", null)
      trusted_key_groups        = lookup(i.value, "trusted_key_groups", null)

      cache_policy_id            = try(i.value.cache_policy_id, aws_cloudfront_cache_policy.this[i.value.cache_policy_name].id, data.aws_cloudfront_cache_policy.this[i.value.cache_policy_name].id, null)
      origin_request_policy_id   = try(i.value.origin_request_policy_id, aws_cloudfront_origin_request_policy.this[i.value.origin_request_policy_name].id, data.aws_cloudfront_origin_request_policy.this[i.value.origin_request_policy_name].id, null)
      response_headers_policy_id = try(i.value.response_headers_policy_id, aws_cloudfront_response_headers_policy.this[i.value.response_headers_policy_name].id, data.aws_cloudfront_response_headers_policy.this[i.value.response_headers_policy_name].id, null)

      realtime_log_config_arn = try(i.value.realtime_log_config_arn, aws_cloudfront_realtime_log_config.this[i.value.realtime_log_config_name].arn, null)

      min_ttl     = lookup(i.value, "min_ttl", null)
      default_ttl = lookup(i.value, "default_ttl", null)
      max_ttl     = lookup(i.value, "max_ttl", null)

      dynamic "forwarded_values" {
        for_each = lookup(i.value, "use_forwarded_values", true) ? [true] : []

        content {
          query_string            = lookup(i.value, "query_string", false)
          query_string_cache_keys = lookup(i.value, "query_string_cache_keys", [])
          headers                 = lookup(i.value, "headers", [])

          cookies {
            forward           = lookup(i.value, "cookies_forward", "none")
            whitelisted_names = lookup(i.value, "cookies_whitelisted_names", null)
          }
        }
      }

      dynamic "lambda_function_association" {
        for_each = lookup(i.value, "lambda_function_association", [])
        iterator = l

        content {
          event_type   = l.key
          lambda_arn   = l.value.lambda_arn
          include_body = lookup(l.value, "include_body", null)
        }
      }

      dynamic "function_association" {
        for_each = lookup(i.value, "function_association", [])
        iterator = f

        content {
          event_type   = f.key
          function_arn = try(f.value.function_arn, aws_cloudfront_function.this[f.value.function_name].arn)
        }
      }

      dynamic "grpc_config" {
        for_each = lookup(i.value, "grpc_config", null) != null ? [i.value.grpc_config] : []

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
      path_pattern           = i.value["path_pattern"]
      target_origin_id       = i.value["target_origin_id"]
      viewer_protocol_policy = i.value["viewer_protocol_policy"]

      allowed_methods           = lookup(i.value, "allowed_methods", ["GET", "HEAD", "OPTIONS"])
      cached_methods            = lookup(i.value, "cached_methods", ["GET", "HEAD"])
      compress                  = lookup(i.value, "compress", null)
      field_level_encryption_id = lookup(i.value, "field_level_encryption_id", null)
      smooth_streaming          = lookup(i.value, "smooth_streaming", null)
      trusted_signers           = lookup(i.value, "trusted_signers", null)
      trusted_key_groups        = lookup(i.value, "trusted_key_groups", null)

      cache_policy_id            = try(i.value.cache_policy_id, aws_cloudfront_cache_policy.this[i.value.cache_policy_name].id, data.aws_cloudfront_cache_policy.this[i.value.cache_policy_name].id, null)
      origin_request_policy_id   = try(i.value.origin_request_policy_id, aws_cloudfront_origin_request_policy.this[i.value.origin_request_policy_name].id, data.aws_cloudfront_origin_request_policy.this[i.value.origin_request_policy_name].id, null)
      response_headers_policy_id = try(i.value.response_headers_policy_id, aws_cloudfront_response_headers_policy.this[i.value.response_headers_policy_name].id, data.aws_cloudfront_response_headers_policy.this[i.value.response_headers_policy_name].id, null)

      realtime_log_config_arn = try(i.value.realtime_log_config_arn, aws_cloudfront_realtime_log_config.this[i.value.realtime_log_config_name].arn, null)

      min_ttl     = lookup(i.value, "min_ttl", null)
      default_ttl = lookup(i.value, "default_ttl", null)
      max_ttl     = lookup(i.value, "max_ttl", null)

      dynamic "forwarded_values" {
        for_each = lookup(i.value, "use_forwarded_values", true) ? [true] : []

        content {
          query_string            = lookup(i.value, "query_string", false)
          query_string_cache_keys = lookup(i.value, "query_string_cache_keys", [])
          headers                 = lookup(i.value, "headers", [])

          cookies {
            forward           = lookup(i.value, "cookies_forward", "none")
            whitelisted_names = lookup(i.value, "cookies_whitelisted_names", null)
          }
        }
      }

      dynamic "lambda_function_association" {
        for_each = lookup(i.value, "lambda_function_association", [])
        iterator = l

        content {
          event_type   = l.key
          lambda_arn   = l.value.lambda_arn
          include_body = lookup(l.value, "include_body", null)
        }
      }

      dynamic "function_association" {
        for_each = lookup(i.value, "function_association", [])
        iterator = f

        content {
          event_type   = f.key
          function_arn = try(f.value.function_arn, aws_cloudfront_function.this[f.value.function_name].arn)
        }
      }

      dynamic "grpc_config" {
        for_each = lookup(i.value, "grpc_config", null) != null ? [i.value.grpc_config] : []

        content {
          enabled = grpc_config.value.enabled
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      web_acl_id
    ]

  }

  viewer_certificate {
    acm_certificate_arn            = lookup(var.viewer_certificate, "acm_certificate_arn", null)
    cloudfront_default_certificate = lookup(var.viewer_certificate, "cloudfront_default_certificate", null)
    iam_certificate_id             = lookup(var.viewer_certificate, "iam_certificate_id", null)

    minimum_protocol_version = lookup(var.viewer_certificate, "minimum_protocol_version", "TLSv1.2_2021")
    ssl_support_method       = lookup(var.viewer_certificate, "ssl_support_method", null)
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
    for_each = length(flatten([var.custom_error_response])[0]) > 0 ? flatten([var.custom_error_response]) : []

    content {
      error_code = custom_error_response.value["error_code"]

      response_code         = lookup(custom_error_response.value, "response_code", null)
      response_page_path    = lookup(custom_error_response.value, "response_page_path", null)
      error_caching_min_ttl = lookup(custom_error_response.value, "error_caching_min_ttl", null)
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
}

resource "aws_cloudfront_monitoring_subscription" "this" {
  distribution_id = one(aws_cloudfront_distribution.this).id

  monitoring_subscription {
    realtime_metrics_subscription_config {
      realtime_metrics_subscription_status = var.realtime_metrics_subscription_status
    }
  }

  lifecycle {
    enabled = var.enabled && var.create_monitoring_subscription
  }
}

data "aws_cloudfront_cache_policy" "this" {
  for_each = toset([
    for v in concat([var.default_cache_behavior], var.ordered_cache_behavior) :
    v.cache_policy_name
    if can(v.cache_policy_name) && !contains(keys(var.cache_policies), v.cache_policy_name)
  ])
  name = each.key
}

data "aws_cloudfront_origin_request_policy" "this" {
  for_each = toset([
    for v in concat([var.default_cache_behavior], var.ordered_cache_behavior) :
    v.origin_request_policy_name
    if can(v.origin_request_policy_name) && !contains(keys(var.origin_request_policies), v.origin_request_policy_name)
  ])
  name = each.key
}

data "aws_cloudfront_response_headers_policy" "this" {
  for_each = toset([
    for v in concat([var.default_cache_behavior], var.ordered_cache_behavior) :
    v.response_headers_policy_name
    if can(v.response_headers_policy_name) && !contains(keys(var.response_headers_policies), v.response_headers_policy_name)
  ])
  name = each.key
}
