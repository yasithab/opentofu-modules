data "aws_partition" "current" {}

locals {
  create = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# Load Balancer
################################################################################

# trivy:ignore:AVD-AWS-0053 - Module intentionally supports both internal and internet-facing LBs; callers control via var.internal
resource "aws_lb" "this" {
  dynamic "access_logs" {
    for_each = length(var.access_logs) > 0 ? [var.access_logs] : []

    content {
      bucket  = access_logs.value.bucket
      enabled = try(access_logs.value.enabled, true)
      prefix  = try(access_logs.value.prefix, null)
    }
  }

  dynamic "connection_logs" {
    for_each = length(var.connection_logs) > 0 ? [var.connection_logs] : []
    content {
      bucket  = connection_logs.value.bucket
      enabled = try(connection_logs.value.enabled, true)
      prefix  = try(connection_logs.value.prefix, null)
    }
  }

  dynamic "health_check_logs" {
    for_each = length(var.health_check_logs) > 0 ? [var.health_check_logs] : []
    content {
      bucket  = health_check_logs.value.bucket
      enabled = try(health_check_logs.value.enabled, true)
      prefix  = try(health_check_logs.value.prefix, null)
    }
  }

  dynamic "ipam_pools" {
    for_each = length(var.ipam_pools) > 0 ? [var.ipam_pools] : []
    content {
      ipv4_ipam_pool_id = ipam_pools.value.ipv4_ipam_pool_id
    }
  }

  dynamic "minimum_load_balancer_capacity" {
    for_each = length(var.minimum_load_balancer_capacity) > 0 ? [var.minimum_load_balancer_capacity] : []
    content {
      capacity_units = minimum_load_balancer_capacity.value.capacity_units
    }
  }

  client_keep_alive                                            = var.client_keep_alive
  customer_owned_ipv4_pool                                     = var.customer_owned_ipv4_pool
  desync_mitigation_mode                                       = var.desync_mitigation_mode
  dns_record_client_routing_policy                             = var.dns_record_client_routing_policy
  drop_invalid_header_fields                                   = var.drop_invalid_header_fields
  enable_cross_zone_load_balancing                             = var.enable_cross_zone_load_balancing
  enable_deletion_protection                                   = var.enable_deletion_protection
  enable_http2                                                 = var.enable_http2
  enable_tls_version_and_cipher_suite_headers                  = var.enable_tls_version_and_cipher_suite_headers
  enable_waf_fail_open                                         = var.enable_waf_fail_open
  enable_xff_client_port                                       = var.enable_xff_client_port
  enable_zonal_shift                                           = var.enable_zonal_shift
  enforce_security_group_inbound_rules_on_private_link_traffic = var.enforce_security_group_inbound_rules_on_private_link_traffic
  idle_timeout                                                 = var.idle_timeout
  internal                                                     = var.internal
  ip_address_type                                              = var.ip_address_type
  load_balancer_type                                           = var.load_balancer_type
  name                                                         = var.name
  name_prefix                                                  = var.name_prefix
  preserve_host_header                                         = var.preserve_host_header
  secondary_ips_auto_assigned_per_subnet                       = var.secondary_ips_auto_assigned_per_subnet
  security_groups                                              = var.create_security_group ? concat([aws_security_group.this.id], var.security_groups) : var.security_groups

  dynamic "subnet_mapping" {
    for_each = var.subnet_mapping

    content {
      allocation_id        = lookup(subnet_mapping.value, "allocation_id", null)
      ipv6_address         = lookup(subnet_mapping.value, "ipv6_address", null)
      private_ipv4_address = lookup(subnet_mapping.value, "private_ipv4_address", null)
      subnet_id            = subnet_mapping.value.subnet_id
    }
  }

  subnets                    = var.subnets
  tags                       = local.tags
  xff_header_processing_mode = var.xff_header_processing_mode

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    delete = try(var.timeouts.delete, null)
  }

  lifecycle {
    enabled = local.create
    ignore_changes = [
      tags["elasticbeanstalk:shared-elb-environment-count"]
    ]
  }
}

################################################################################
# Listener(s)
################################################################################

resource "aws_lb_listener" "this" {
  for_each = { for k, v in var.listeners : k => v if local.create }

  alpn_policy     = try(each.value.alpn_policy, null)
  certificate_arn = try(each.value.certificate_arn, null)

  # Single dynamic block guarantees exactly 1 default_action per listener,
  # satisfying the provider schema requirement (min 1). The action type and
  # nested sub-blocks are determined from which listener key is set.
  dynamic "default_action" {
    for_each = [each.value]

    content {
      type = (
        can(default_action.value.authenticate_cognito.user_pool_arn) ? "authenticate-cognito" :
        can(default_action.value.authenticate_oidc.client_id) ? "authenticate-oidc" :
        can(default_action.value.fixed_response.content_type) ? "fixed-response" :
        can(default_action.value.redirect.status_code) ? "redirect" :
        can(default_action.value.jwt_validation.issuer) ? "jwt-validation" :
        "forward"
      )

      order = try(coalesce(
        try(default_action.value.authenticate_cognito.order, null),
        try(default_action.value.authenticate_oidc.order, null),
        try(default_action.value.fixed_response.order, null),
        try(default_action.value.forward.order, null),
        try(default_action.value.weighted_forward.order, null),
        try(default_action.value.redirect.order, null),
        try(default_action.value.jwt_validation.order, null),
      ), null)

      # Simple forward: single target group ARN at the action level
      target_group_arn = try(
        length(try(default_action.value.forward.target_groups, [])) > 0 ? null :
        try(default_action.value.forward.arn, aws_lb_target_group.this[default_action.value.forward.target_group_key].arn, null),
        null
      )

      dynamic "authenticate_cognito" {
        for_each = try([default_action.value.authenticate_cognito], [])
        content {
          authentication_request_extra_params = try(authenticate_cognito.value.authentication_request_extra_params, null)
          on_unauthenticated_request          = try(authenticate_cognito.value.on_unauthenticated_request, null)
          scope                               = try(authenticate_cognito.value.scope, null)
          session_cookie_name                 = try(authenticate_cognito.value.session_cookie_name, null)
          session_timeout                     = try(authenticate_cognito.value.session_timeout, null)
          user_pool_arn                       = authenticate_cognito.value.user_pool_arn
          user_pool_client_id                 = authenticate_cognito.value.user_pool_client_id
          user_pool_domain                    = authenticate_cognito.value.user_pool_domain
        }
      }

      dynamic "authenticate_oidc" {
        for_each = try([default_action.value.authenticate_oidc], [])
        content {
          authentication_request_extra_params = try(authenticate_oidc.value.authentication_request_extra_params, null)
          authorization_endpoint              = authenticate_oidc.value.authorization_endpoint
          client_id                           = authenticate_oidc.value.client_id
          client_secret                       = authenticate_oidc.value.client_secret
          issuer                              = authenticate_oidc.value.issuer
          on_unauthenticated_request          = try(authenticate_oidc.value.on_unauthenticated_request, null)
          scope                               = try(authenticate_oidc.value.scope, null)
          session_cookie_name                 = try(authenticate_oidc.value.session_cookie_name, null)
          session_timeout                     = try(authenticate_oidc.value.session_timeout, null)
          token_endpoint                      = authenticate_oidc.value.token_endpoint
          user_info_endpoint                  = authenticate_oidc.value.user_info_endpoint
        }
      }

      dynamic "fixed_response" {
        for_each = try([default_action.value.fixed_response], [])
        content {
          content_type = fixed_response.value.content_type
          message_body = try(fixed_response.value.message_body, null)
          status_code  = try(fixed_response.value.status_code, null)
        }
      }

      # Weighted forward: multiple target groups with weights
      dynamic "forward" {
        for_each = length(try(default_action.value.weighted_forward.target_groups, [])) > 0 ? [default_action.value.weighted_forward] : []
        content {
          dynamic "target_group" {
            for_each = try(forward.value.target_groups, [])
            content {
              arn    = try(target_group.value.arn, aws_lb_target_group.this[target_group.value.target_group_key].arn, null)
              weight = try(target_group.value.weight, null)
            }
          }

          dynamic "stickiness" {
            for_each = try([forward.value.stickiness], [])
            content {
              duration = try(stickiness.value.duration, 60)
              enabled  = try(stickiness.value.enabled, null)
            }
          }
        }
      }

      dynamic "redirect" {
        for_each = try([default_action.value.redirect], [])
        content {
          host        = try(redirect.value.host, null)
          path        = try(redirect.value.path, null)
          port        = try(redirect.value.port, null)
          protocol    = try(redirect.value.protocol, null)
          query       = try(redirect.value.query, null)
          status_code = redirect.value.status_code
        }
      }

      dynamic "jwt_validation" {
        for_each = try([default_action.value.jwt_validation], [])
        content {
          issuer        = jwt_validation.value.issuer
          jwks_endpoint = jwt_validation.value.jwks_endpoint

          dynamic "additional_claim" {
            for_each = try(jwt_validation.value.additional_claims, [])
            content {
              format = additional_claim.value.format
              name   = additional_claim.value.name
              values = additional_claim.value.values
            }
          }
        }
      }
    }
  }

  dynamic "mutual_authentication" {
    for_each = try([each.value.mutual_authentication], [])
    content {
      mode                             = mutual_authentication.value.mode
      trust_store_arn                  = try(mutual_authentication.value.trust_store_arn, null)
      advertise_trust_store_ca_names   = try(mutual_authentication.value.advertise_trust_store_ca_names, null)
      ignore_client_certificate_expiry = try(mutual_authentication.value.ignore_client_certificate_expiry, null)
    }
  }

  load_balancer_arn        = aws_lb.this.arn
  port                     = try(each.value.port, var.default_port)
  protocol                 = try(each.value.protocol, var.default_protocol)
  ssl_policy               = contains(["HTTPS", "TLS"], try(each.value.protocol, var.default_protocol)) ? try(each.value.ssl_policy, "ELBSecurityPolicy-TLS13-1-2-Res-2021-06") : try(each.value.ssl_policy, null)
  tcp_idle_timeout_seconds = try(each.value.tcp_idle_timeout_seconds, null)

  routing_http_request_x_amzn_mtls_clientcert_header_name               = try(each.value.routing_http_request_x_amzn_mtls_clientcert_header_name, null)
  routing_http_request_x_amzn_mtls_clientcert_issuer_header_name        = try(each.value.routing_http_request_x_amzn_mtls_clientcert_issuer_header_name, null)
  routing_http_request_x_amzn_mtls_clientcert_leaf_header_name          = try(each.value.routing_http_request_x_amzn_mtls_clientcert_leaf_header_name, null)
  routing_http_request_x_amzn_mtls_clientcert_serial_number_header_name = try(each.value.routing_http_request_x_amzn_mtls_clientcert_serial_number_header_name, null)
  routing_http_request_x_amzn_mtls_clientcert_subject_header_name       = try(each.value.routing_http_request_x_amzn_mtls_clientcert_subject_header_name, null)
  routing_http_request_x_amzn_mtls_clientcert_validity_header_name      = try(each.value.routing_http_request_x_amzn_mtls_clientcert_validity_header_name, null)
  routing_http_request_x_amzn_tls_cipher_suite_header_name              = try(each.value.routing_http_request_x_amzn_tls_cipher_suite_header_name, null)
  routing_http_request_x_amzn_tls_version_header_name                   = try(each.value.routing_http_request_x_amzn_tls_version_header_name, null)
  routing_http_response_access_control_allow_credentials_header_value   = try(each.value.routing_http_response_access_control_allow_credentials_header_value, null)
  routing_http_response_access_control_allow_headers_header_value       = try(each.value.routing_http_response_access_control_allow_headers_header_value, null)
  routing_http_response_access_control_allow_methods_header_value       = try(each.value.routing_http_response_access_control_allow_methods_header_value, null)
  routing_http_response_access_control_allow_origin_header_value        = try(each.value.routing_http_response_access_control_allow_origin_header_value, null)
  routing_http_response_access_control_expose_headers_header_value      = try(each.value.routing_http_response_access_control_expose_headers_header_value, null)
  routing_http_response_access_control_max_age_header_value             = try(each.value.routing_http_response_access_control_max_age_header_value, null)
  routing_http_response_content_security_policy_header_value            = try(each.value.routing_http_response_content_security_policy_header_value, null)
  routing_http_response_server_enabled                                  = try(each.value.routing_http_response_server_enabled, null)
  routing_http_response_strict_transport_security_header_value          = try(each.value.routing_http_response_strict_transport_security_header_value, null)
  routing_http_response_x_content_type_options_header_value             = try(each.value.routing_http_response_x_content_type_options_header_value, null)
  routing_http_response_x_frame_options_header_value                    = try(each.value.routing_http_response_x_frame_options_header_value, null)

  tags = merge(local.tags, try(each.value.tags, {}))
}

################################################################################
# Listener Rule(s)
################################################################################

locals {
  # This allows rules to be specified under the listener definition
  listener_rules = flatten([
    for listener_key, listener_values in var.listeners : [
      for rule_key, rule_values in lookup(listener_values, "rules", {}) :
      merge(rule_values, {
        listener_key = listener_key
        rule_key     = rule_key
      })
    ]
  ])
}

resource "aws_lb_listener_rule" "this" {
  for_each = { for v in local.listener_rules : "${v.listener_key}/${v.rule_key}" => v if local.create }

  listener_arn = try(each.value.listener_arn, aws_lb_listener.this[each.value.listener_key].arn)
  priority     = try(each.value.priority, null)

  dynamic "action" {
    for_each = [for action in each.value.actions : action if action.type == "authenticate-cognito"]

    content {
      type  = "authenticate-cognito"
      order = try(action.value.order, null)

      authenticate_cognito {
        authentication_request_extra_params = try(action.value.authentication_request_extra_params, null)
        on_unauthenticated_request          = try(action.value.on_unauthenticated_request, null)
        scope                               = try(action.value.scope, null)
        session_cookie_name                 = try(action.value.session_cookie_name, null)
        session_timeout                     = try(action.value.session_timeout, null)
        user_pool_arn                       = action.value.user_pool_arn
        user_pool_client_id                 = action.value.user_pool_client_id
        user_pool_domain                    = action.value.user_pool_domain
      }
    }
  }

  dynamic "action" {
    for_each = [for action in each.value.actions : action if action.type == "authenticate-oidc"]

    content {
      type  = "authenticate-oidc"
      order = try(action.value.order, null)

      authenticate_oidc {
        authentication_request_extra_params = try(action.value.authentication_request_extra_params, null)
        authorization_endpoint              = action.value.authorization_endpoint
        client_id                           = action.value.client_id
        client_secret                       = action.value.client_secret
        issuer                              = action.value.issuer
        on_unauthenticated_request          = try(action.value.on_unauthenticated_request, null)
        scope                               = try(action.value.scope, null)
        session_cookie_name                 = try(action.value.session_cookie_name, null)
        session_timeout                     = try(action.value.session_timeout, null)
        token_endpoint                      = action.value.token_endpoint
        user_info_endpoint                  = action.value.user_info_endpoint
      }
    }
  }

  dynamic "action" {
    for_each = [for action in each.value.actions : action if action.type == "redirect"]

    content {
      type  = "redirect"
      order = try(action.value.order, null)

      redirect {
        host        = try(action.value.host, null)
        path        = try(action.value.path, null)
        port        = try(action.value.port, null)
        protocol    = try(action.value.protocol, null)
        query       = try(action.value.query, null)
        status_code = action.value.status_code
      }
    }
  }

  dynamic "action" {
    for_each = [for action in each.value.actions : action if action.type == "fixed-response"]

    content {
      type  = "fixed-response"
      order = try(action.value.order, null)

      fixed_response {
        content_type = action.value.content_type
        message_body = try(action.value.message_body, null)
        status_code  = try(action.value.status_code, null)
      }
    }
  }

  dynamic "action" {
    for_each = [for action in each.value.actions : action if action.type == "forward"]

    content {
      type             = "forward"
      order            = try(action.value.order, null)
      target_group_arn = try(action.value.target_group_arn, aws_lb_target_group.this[action.value.target_group_key].arn, null)
    }
  }

  dynamic "action" {
    for_each = [for action in each.value.actions : action if action.type == "weighted-forward"]

    content {
      type  = "forward"
      order = try(action.value.order, null)

      forward {
        dynamic "target_group" {
          for_each = try(action.value.target_groups, [])

          content {
            arn    = try(target_group.value.arn, aws_lb_target_group.this[target_group.value.target_group_key].arn)
            weight = try(target_group.value.weight, null)
          }
        }

        dynamic "stickiness" {
          for_each = try([action.value.stickiness], [])

          content {
            enabled  = try(stickiness.value.enabled, null)
            duration = try(stickiness.value.duration, 60)
          }
        }
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in each.value.conditions : condition if contains(keys(condition), "host_header")]

    content {
      dynamic "host_header" {
        for_each = try([condition.value.host_header], [])

        content {
          values       = try(host_header.value.values, null)
          regex_values = try(host_header.value.regex_values, null)
        }
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in each.value.conditions : condition if contains(keys(condition), "http_header")]

    content {
      dynamic "http_header" {
        for_each = try([condition.value.http_header], [])

        content {
          http_header_name = http_header.value.http_header_name
          values           = try(http_header.value.values, null)
          regex_values     = try(http_header.value.regex_values, null)
        }
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in each.value.conditions : condition if contains(keys(condition), "http_request_method")]

    content {
      dynamic "http_request_method" {
        for_each = try([condition.value.http_request_method], [])

        content {
          values = http_request_method.value.values
        }
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in each.value.conditions : condition if contains(keys(condition), "path_pattern")]

    content {
      dynamic "path_pattern" {
        for_each = try([condition.value.path_pattern], [])

        content {
          values       = try(path_pattern.value.values, null)
          regex_values = try(path_pattern.value.regex_values, null)
        }
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in each.value.conditions : condition if contains(keys(condition), "query_string")]

    content {
      dynamic "query_string" {
        for_each = try([condition.value.query_string], [])

        content {
          key   = try(query_string.value.key, null)
          value = query_string.value.value
        }
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in each.value.conditions : condition if contains(keys(condition), "source_ip")]

    content {
      dynamic "source_ip" {
        for_each = try([condition.value.source_ip], [])

        content {
          values = source_ip.value.values
        }
      }
    }
  }

  dynamic "action" {
    for_each = [for action in each.value.actions : action if action.type == "jwt-validation"]

    content {
      type  = "jwt-validation"
      order = try(action.value.order, null)

      jwt_validation {
        issuer        = action.value.issuer
        jwks_endpoint = action.value.jwks_endpoint

        dynamic "additional_claim" {
          for_each = try(action.value.additional_claims, [])

          content {
            format = additional_claim.value.format
            name   = additional_claim.value.name
            values = additional_claim.value.values
          }
        }
      }
    }
  }

  dynamic "transform" {
    for_each = try(each.value.transforms, [])
    content {
      type = transform.value.type

      dynamic "url_rewrite_config" {
        for_each = transform.value.type == "url-rewrite" ? [transform.value.url_rewrite_config] : []
        content {
          dynamic "rewrite" {
            for_each = try([url_rewrite_config.value.rewrite], [])
            content {
              regex   = rewrite.value.regex
              replace = rewrite.value.replace
            }
          }
        }
      }

      dynamic "host_header_rewrite_config" {
        for_each = transform.value.type == "host-header-rewrite" ? [transform.value.host_header_rewrite_config] : []
        content {
          dynamic "rewrite" {
            for_each = try([host_header_rewrite_config.value.rewrite], [])
            content {
              regex   = rewrite.value.regex
              replace = rewrite.value.replace
            }
          }
        }
      }
    }
  }

  tags = merge(local.tags, try(each.value.tags, {}))
}

################################################################################
# Certificate(s)
################################################################################

locals {
  # Take the list of `additional_certificate_arns` from the listener and create
  # a map entry that maps each certificate to the listener key. This map of maps
  # is then used to create the certificate resources.
  additional_certs = merge(values({
    for listener_key, listener_values in var.listeners : listener_key =>
    {
      # This will cause certs to be detached and reattached if certificate_arns
      # towards the front of the list are updated/removed. However, we need to have
      # unique keys on the resulting map and we can't have computed values (i.e. cert ARN)
      # in the key so we are using the array index as part of the key.
      for idx, cert_arn in lookup(listener_values, "additional_certificate_arns", []) :
      "${listener_key}/${idx}" => {
        listener_key    = listener_key
        certificate_arn = cert_arn
      }
    } if length(lookup(listener_values, "additional_certificate_arns", [])) > 0
  })...)
}

resource "aws_lb_listener_certificate" "this" {
  for_each = { for k, v in local.additional_certs : k => v if local.create }

  listener_arn    = aws_lb_listener.this[each.value.listener_key].arn
  certificate_arn = each.value.certificate_arn
}

################################################################################
# Target Group(s)
################################################################################

resource "aws_lb_target_group" "this" {
  for_each = { for k, v in var.target_groups : k => v if local.create }

  connection_termination = try(each.value.connection_termination, null)
  deregistration_delay   = try(each.value.deregistration_delay, null)

  dynamic "health_check" {
    for_each = try([each.value.health_check], [])

    content {
      enabled             = try(health_check.value.enabled, null)
      healthy_threshold   = try(health_check.value.healthy_threshold, null)
      interval            = try(health_check.value.interval, null)
      matcher             = try(health_check.value.matcher, null)
      path                = try(health_check.value.path, null)
      port                = try(health_check.value.port, null)
      protocol            = try(health_check.value.protocol, null)
      timeout             = try(health_check.value.timeout, null)
      unhealthy_threshold = try(health_check.value.unhealthy_threshold, null)
    }
  }

  ip_address_type                    = try(each.value.ip_address_type, null)
  lambda_multi_value_headers_enabled = try(each.value.lambda_multi_value_headers_enabled, null)
  load_balancing_algorithm_type      = try(each.value.load_balancing_algorithm_type, null)
  load_balancing_anomaly_mitigation  = try(each.value.load_balancing_anomaly_mitigation, null)
  load_balancing_cross_zone_enabled  = try(each.value.load_balancing_cross_zone_enabled, null)
  name                               = try(each.value.name, null)
  name_prefix                        = try(format("%s-", each.value.name_prefix), null)
  port                               = try(each.value.target_type, null) == "lambda" ? null : try(each.value.port, var.default_port)
  preserve_client_ip                 = try(each.value.preserve_client_ip, null)
  protocol                           = try(each.value.target_type, null) == "lambda" ? null : try(each.value.protocol, var.default_protocol)
  protocol_version                   = try(each.value.protocol_version, null)
  proxy_protocol_v2                  = try(each.value.proxy_protocol_v2, null)
  slow_start                         = try(each.value.slow_start, null)
  target_control_port                = try(each.value.target_control_port, null)

  dynamic "stickiness" {
    for_each = try([each.value.stickiness], [])

    content {
      cookie_duration = try(stickiness.value.cookie_duration, null)
      cookie_name     = try(stickiness.value.cookie_name, null)
      enabled         = try(stickiness.value.enabled, true)
      type            = var.load_balancer_type == "network" ? "source_ip" : stickiness.value.type
    }
  }

  dynamic "target_failover" {
    for_each = try(each.value.target_failover, [])

    content {
      on_deregistration = target_failover.value.on_deregistration
      on_unhealthy      = target_failover.value.on_unhealthy
    }
  }

  dynamic "target_group_health" {
    for_each = try([each.value.target_group_health], [])

    content {

      dynamic "dns_failover" {
        for_each = try([target_group_health.value.dns_failover], [])

        content {
          minimum_healthy_targets_count      = try(dns_failover.value.minimum_healthy_targets_count, null)
          minimum_healthy_targets_percentage = try(dns_failover.value.minimum_healthy_targets_percentage, null)
        }
      }

      dynamic "unhealthy_state_routing" {
        for_each = try([target_group_health.value.unhealthy_state_routing], [])

        content {
          minimum_healthy_targets_count      = try(unhealthy_state_routing.value.minimum_healthy_targets_count, null)
          minimum_healthy_targets_percentage = try(unhealthy_state_routing.value.minimum_healthy_targets_percentage, null)
        }
      }
    }
  }

  dynamic "target_health_state" {
    for_each = try([each.value.target_health_state], [])
    content {
      enable_unhealthy_connection_termination = try(target_health_state.value.enable_unhealthy_connection_termination, true)
      unhealthy_draining_interval             = try(target_health_state.value.unhealthy_draining_interval, null)
    }
  }

  target_type = try(each.value.target_type, null)
  vpc_id      = try(each.value.vpc_id, var.vpc_id)

  tags = merge(local.tags, try(each.value.tags, {}))

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Target Group Attachment
################################################################################

resource "aws_lb_target_group_attachment" "this" {
  for_each = { for k, v in var.target_groups : k => v if local.create && lookup(v, "create_attachment", true) }

  target_group_arn  = aws_lb_target_group.this[each.key].arn
  target_id         = each.value.target_id
  port              = try(each.value.target_type, null) == "lambda" ? null : try(each.value.port, var.default_port)
  availability_zone = try(each.value.availability_zone, null)
  quic_server_id    = try(each.value.quic_server_id, null)

  depends_on = [aws_lambda_permission.this]
}

resource "aws_lb_target_group_attachment" "additional" {
  for_each = { for k, v in var.additional_target_group_attachments : k => v if local.create }

  target_group_arn  = aws_lb_target_group.this[each.value.target_group_key].arn
  target_id         = each.value.target_id
  port              = try(each.value.target_type, null) == "lambda" ? null : try(each.value.port, var.default_port)
  availability_zone = try(each.value.availability_zone, null)
  quic_server_id    = try(each.value.quic_server_id, null)

  depends_on = [aws_lambda_permission.this]
}

################################################################################
# Lambda Permission
################################################################################

# Filter out the attachments for lambda functions. The ALB target group needs
# permission to forward a request on to # the specified lambda function.
# This filtered list is used to create those permission resources. # To get the
# lambda_function_name, the 6th index is taken from the function ARN format below
# arn:aws:lambda:<region>:<account-id>:function:my-function-name:<version-number>
locals {
  lambda_target_groups = {
    for k, v in var.target_groups :
    (k) => merge(v, { lambda_function_name = split(":", v.target_id)[6] })
    if try(v.attach_lambda_permission, false)
  }
}

resource "aws_lambda_permission" "this" {
  for_each = { for k, v in local.lambda_target_groups : k => v if local.create }

  function_name = each.value.lambda_function_name
  qualifier     = try(each.value.lambda_qualifier, null)

  statement_id       = try(each.value.lambda_statement_id, "AllowExecutionFromLb")
  action             = try(each.value.lambda_action, "lambda:InvokeFunction")
  principal          = try(each.value.lambda_principal, "elasticloadbalancing.${data.aws_partition.current.dns_suffix}")
  source_arn         = aws_lb_target_group.this[each.key].arn
  source_account     = try(each.value.lambda_source_account, null)
  event_source_token = try(each.value.lambda_event_source_token, null)
}

################################################################################
# Security Group
################################################################################

locals {
  create_security_group = local.create && var.create_security_group
  security_group_name   = try(coalesce(var.security_group_name, var.name, var.name_prefix), "")
}

resource "aws_security_group" "this" {
  name        = var.security_group_use_name_prefix ? null : local.security_group_name
  name_prefix = var.security_group_use_name_prefix ? "${local.security_group_name}-" : null
  description = coalesce(var.security_group_description, "Security group for ${local.security_group_name} ${var.load_balancer_type} load balancer")
  vpc_id      = var.vpc_id

  tags = merge(local.tags, var.security_group_tags)

  lifecycle {
    enabled               = local.create_security_group
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = { for k, v in var.security_group_egress_rules : k => v if local.create_security_group }

  # Required
  security_group_id = aws_security_group.this.id
  ip_protocol       = try(each.value.ip_protocol, "tcp")

  # Optional
  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  cidr_ipv6                    = lookup(each.value, "cidr_ipv6", null)
  description                  = try(each.value.description, null)
  from_port                    = try(each.value.from_port, null)
  prefix_list_id               = lookup(each.value, "prefix_list_id", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
  to_port                      = try(each.value.to_port, null)

  tags = merge(local.tags, var.security_group_tags, try(each.value.tags, {}))
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = { for k, v in var.security_group_ingress_rules : k => v if local.create_security_group }

  # Required
  security_group_id = aws_security_group.this.id
  ip_protocol       = try(each.value.ip_protocol, "tcp")

  # Optional
  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  cidr_ipv6                    = lookup(each.value, "cidr_ipv6", null)
  description                  = try(each.value.description, null)
  from_port                    = try(each.value.from_port, null)
  prefix_list_id               = lookup(each.value, "prefix_list_id", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
  to_port                      = try(each.value.to_port, null)

  tags = merge(local.tags, var.security_group_tags, try(each.value.tags, {}))
}

################################################################################
# Route53 Record(s)
################################################################################

resource "aws_route53_record" "this" {
  for_each = { for k, v in var.route53_records : k => v if var.enabled }

  zone_id = each.value.zone_id
  name    = try(each.value.name, each.key)
  type    = each.value.type

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}

################################################################################
# WAF
################################################################################

resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = aws_lb.this.arn
  web_acl_arn  = var.web_acl_arn

  lifecycle {
    enabled = var.associate_web_acl
  }
}

################################################################################
# Trust Store(s)
# Used for mTLS mutual authentication on HTTPS listeners
################################################################################

resource "aws_lb_trust_store" "this" {
  for_each = { for k, v in var.trust_stores : k => v if local.create }

  ca_certificates_bundle_s3_bucket         = each.value.ca_certificates_bundle_s3_bucket
  ca_certificates_bundle_s3_key            = each.value.ca_certificates_bundle_s3_key
  ca_certificates_bundle_s3_object_version = try(each.value.ca_certificates_bundle_s3_object_version, null)
  name                                     = try(each.value.name, null)
  name_prefix                              = try(each.value.name_prefix, null)

  tags = merge(local.tags, try(each.value.tags, {}))
}

resource "aws_lb_trust_store_revocation" "this" {
  for_each = { for k, v in var.trust_store_revocations : k => v if local.create }

  trust_store_arn               = try(each.value.trust_store_arn, aws_lb_trust_store.this[each.value.trust_store_key].arn)
  revocations_s3_bucket         = each.value.revocations_s3_bucket
  revocations_s3_key            = each.value.revocations_s3_key
  revocations_s3_object_version = try(each.value.revocations_s3_object_version, null)
}