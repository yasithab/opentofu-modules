data "aws_partition" "current" {}

locals {
  enabled = var.enabled
  name    = var.name

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
  name                                                         = local.name
  name_prefix                                                  = var.name_prefix
  preserve_host_header                                         = var.preserve_host_header
  secondary_ips_auto_assigned_per_subnet                       = var.secondary_ips_auto_assigned_per_subnet
  security_groups                                              = local.create_security_group ? concat([aws_security_group.this.id], var.security_groups) : var.security_groups

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
    enabled = local.enabled
    ignore_changes = [
      tags["elasticbeanstalk:shared-elb-environment-count"]
    ]
  }
}

################################################################################
# Listener(s)
################################################################################

resource "aws_lb_listener" "this" {
  for_each = { for k, v in var.listeners : k => v if local.enabled }

  alpn_policy     = each.value.alpn_policy
  certificate_arn = each.value.certificate_arn

  # Single dynamic block guarantees exactly 1 default_action per listener,
  # satisfying the provider schema requirement (min 1). The action type and
  # nested sub-blocks are determined from which listener key is set (the
  # variable validation guarantees exactly one is non-null).
  dynamic "default_action" {
    for_each = [each.value]

    content {
      type = (
        default_action.value.authenticate_cognito != null ? "authenticate-cognito" :
        default_action.value.authenticate_oidc != null ? "authenticate-oidc" :
        default_action.value.fixed_response != null ? "fixed-response" :
        default_action.value.redirect != null ? "redirect" :
        default_action.value.jwt_validation != null ? "jwt-validation" :
        "forward"
      )

      order = (
        default_action.value.authenticate_cognito != null ? default_action.value.authenticate_cognito.order :
        default_action.value.authenticate_oidc != null ? default_action.value.authenticate_oidc.order :
        default_action.value.fixed_response != null ? default_action.value.fixed_response.order :
        default_action.value.redirect != null ? default_action.value.redirect.order :
        default_action.value.jwt_validation != null ? default_action.value.jwt_validation.order :
        default_action.value.weighted_forward != null ? default_action.value.weighted_forward.order :
        default_action.value.forward != null ? default_action.value.forward.order :
        null
      )

      # Simple forward: single target group ARN at the action level
      target_group_arn = default_action.value.forward != null ? (
        default_action.value.forward.arn != null ? default_action.value.forward.arn : aws_lb_target_group.this[default_action.value.forward.target_group_key].arn
      ) : null

      dynamic "authenticate_cognito" {
        for_each = default_action.value.authenticate_cognito != null ? [default_action.value.authenticate_cognito] : []
        content {
          authentication_request_extra_params = authenticate_cognito.value.authentication_request_extra_params
          on_unauthenticated_request          = authenticate_cognito.value.on_unauthenticated_request
          scope                               = authenticate_cognito.value.scope
          session_cookie_name                 = authenticate_cognito.value.session_cookie_name
          session_timeout                     = authenticate_cognito.value.session_timeout
          user_pool_arn                       = authenticate_cognito.value.user_pool_arn
          user_pool_client_id                 = authenticate_cognito.value.user_pool_client_id
          user_pool_domain                    = authenticate_cognito.value.user_pool_domain
        }
      }

      dynamic "authenticate_oidc" {
        for_each = default_action.value.authenticate_oidc != null ? [default_action.value.authenticate_oidc] : []
        content {
          authentication_request_extra_params = authenticate_oidc.value.authentication_request_extra_params
          authorization_endpoint              = authenticate_oidc.value.authorization_endpoint
          client_id                           = authenticate_oidc.value.client_id
          # The secret comes exclusively from the sensitive secrets map, keyed
          # by listener key (inline client_secret is rejected by validation).
          client_secret              = var.listener_auth_oidc_client_secrets[each.key]
          issuer                     = authenticate_oidc.value.issuer
          on_unauthenticated_request = authenticate_oidc.value.on_unauthenticated_request
          scope                      = authenticate_oidc.value.scope
          session_cookie_name        = authenticate_oidc.value.session_cookie_name
          session_timeout            = authenticate_oidc.value.session_timeout
          token_endpoint             = authenticate_oidc.value.token_endpoint
          user_info_endpoint         = authenticate_oidc.value.user_info_endpoint
        }
      }

      dynamic "fixed_response" {
        for_each = default_action.value.fixed_response != null ? [default_action.value.fixed_response] : []
        content {
          content_type = fixed_response.value.content_type
          message_body = fixed_response.value.message_body
          status_code  = fixed_response.value.status_code
        }
      }

      # Weighted forward: multiple target groups with weights
      dynamic "forward" {
        for_each = default_action.value.weighted_forward != null ? [default_action.value.weighted_forward] : []
        content {
          dynamic "target_group" {
            for_each = forward.value.target_groups
            content {
              arn    = target_group.value.arn != null ? target_group.value.arn : aws_lb_target_group.this[target_group.value.target_group_key].arn
              weight = target_group.value.weight
            }
          }

          dynamic "stickiness" {
            for_each = forward.value.stickiness != null ? [forward.value.stickiness] : []
            content {
              duration = stickiness.value.duration
              enabled  = stickiness.value.enabled
            }
          }
        }
      }

      dynamic "redirect" {
        for_each = default_action.value.redirect != null ? [default_action.value.redirect] : []
        content {
          host        = redirect.value.host
          path        = redirect.value.path
          port        = redirect.value.port
          protocol    = redirect.value.protocol
          query       = redirect.value.query
          status_code = redirect.value.status_code
        }
      }

      dynamic "jwt_validation" {
        for_each = default_action.value.jwt_validation != null ? [default_action.value.jwt_validation] : []
        content {
          issuer        = jwt_validation.value.issuer
          jwks_endpoint = jwt_validation.value.jwks_endpoint

          dynamic "additional_claim" {
            for_each = jwt_validation.value.additional_claims
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
    for_each = each.value.mutual_authentication != null ? [each.value.mutual_authentication] : []
    content {
      mode                             = mutual_authentication.value.mode
      trust_store_arn                  = mutual_authentication.value.trust_store_arn != null ? mutual_authentication.value.trust_store_arn : (mutual_authentication.value.trust_store_key != null ? aws_lb_trust_store.this[mutual_authentication.value.trust_store_key].arn : null)
      advertise_trust_store_ca_names   = mutual_authentication.value.advertise_trust_store_ca_names
      ignore_client_certificate_expiry = mutual_authentication.value.ignore_client_certificate_expiry
    }
  }

  load_balancer_arn        = aws_lb.this.arn
  port                     = coalesce(each.value.port, var.default_port)
  protocol                 = coalesce(each.value.protocol, var.default_protocol)
  ssl_policy               = contains(["HTTPS", "TLS"], coalesce(each.value.protocol, var.default_protocol)) ? coalesce(each.value.ssl_policy, "ELBSecurityPolicy-TLS13-1-2-Res-2021-06") : each.value.ssl_policy
  tcp_idle_timeout_seconds = each.value.tcp_idle_timeout_seconds

  routing_http_request_x_amzn_mtls_clientcert_header_name               = each.value.routing_http_request_x_amzn_mtls_clientcert_header_name
  routing_http_request_x_amzn_mtls_clientcert_issuer_header_name        = each.value.routing_http_request_x_amzn_mtls_clientcert_issuer_header_name
  routing_http_request_x_amzn_mtls_clientcert_leaf_header_name          = each.value.routing_http_request_x_amzn_mtls_clientcert_leaf_header_name
  routing_http_request_x_amzn_mtls_clientcert_serial_number_header_name = each.value.routing_http_request_x_amzn_mtls_clientcert_serial_number_header_name
  routing_http_request_x_amzn_mtls_clientcert_subject_header_name       = each.value.routing_http_request_x_amzn_mtls_clientcert_subject_header_name
  routing_http_request_x_amzn_mtls_clientcert_validity_header_name      = each.value.routing_http_request_x_amzn_mtls_clientcert_validity_header_name
  routing_http_request_x_amzn_tls_cipher_suite_header_name              = each.value.routing_http_request_x_amzn_tls_cipher_suite_header_name
  routing_http_request_x_amzn_tls_version_header_name                   = each.value.routing_http_request_x_amzn_tls_version_header_name
  routing_http_response_access_control_allow_credentials_header_value   = each.value.routing_http_response_access_control_allow_credentials_header_value
  routing_http_response_access_control_allow_headers_header_value       = each.value.routing_http_response_access_control_allow_headers_header_value
  routing_http_response_access_control_allow_methods_header_value       = each.value.routing_http_response_access_control_allow_methods_header_value
  routing_http_response_access_control_allow_origin_header_value        = each.value.routing_http_response_access_control_allow_origin_header_value
  routing_http_response_access_control_expose_headers_header_value      = each.value.routing_http_response_access_control_expose_headers_header_value
  routing_http_response_access_control_max_age_header_value             = each.value.routing_http_response_access_control_max_age_header_value
  routing_http_response_content_security_policy_header_value            = each.value.routing_http_response_content_security_policy_header_value
  routing_http_response_server_enabled                                  = each.value.routing_http_response_server_enabled
  routing_http_response_strict_transport_security_header_value          = each.value.routing_http_response_strict_transport_security_header_value
  routing_http_response_x_content_type_options_header_value             = each.value.routing_http_response_x_content_type_options_header_value
  routing_http_response_x_frame_options_header_value                    = each.value.routing_http_response_x_frame_options_header_value

  tags = merge(local.tags, each.value.tags)
}

################################################################################
# Listener Rule(s)
################################################################################

locals {
  # This allows rules to be specified under the listener definition
  listener_rules = flatten([
    for listener_key, listener_values in var.listeners : [
      for rule_key, rule_values in listener_values.rules :
      merge(rule_values, {
        listener_key = listener_key
        rule_key     = rule_key
      })
    ]
  ])
}

resource "aws_lb_listener_rule" "this" {
  for_each = { for v in local.listener_rules : "${v.listener_key}/${v.rule_key}" => v if local.enabled }

  listener_arn = each.value.listener_arn != null ? each.value.listener_arn : aws_lb_listener.this[each.value.listener_key].arn
  priority     = each.value.priority

  dynamic "action" {
    for_each = [for action in each.value.actions : action if action.type == "authenticate-cognito"]

    content {
      type  = "authenticate-cognito"
      order = action.value.order

      authenticate_cognito {
        authentication_request_extra_params = action.value.authentication_request_extra_params
        on_unauthenticated_request          = action.value.on_unauthenticated_request
        scope                               = action.value.scope
        session_cookie_name                 = action.value.session_cookie_name
        session_timeout                     = action.value.session_timeout
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
      order = action.value.order

      authenticate_oidc {
        authentication_request_extra_params = action.value.authentication_request_extra_params
        authorization_endpoint              = action.value.authorization_endpoint
        client_id                           = action.value.client_id
        # The secret comes exclusively from the sensitive secrets map, keyed by
        # "<listener_key>/<rule_key>" (inline client_secret is rejected by validation).
        client_secret              = var.listener_auth_oidc_client_secrets[each.key]
        issuer                     = action.value.issuer
        on_unauthenticated_request = action.value.on_unauthenticated_request
        scope                      = action.value.scope
        session_cookie_name        = action.value.session_cookie_name
        session_timeout            = action.value.session_timeout
        token_endpoint             = action.value.token_endpoint
        user_info_endpoint         = action.value.user_info_endpoint
      }
    }
  }

  dynamic "action" {
    for_each = [for action in each.value.actions : action if action.type == "redirect"]

    content {
      type  = "redirect"
      order = action.value.order

      redirect {
        host        = action.value.host
        path        = action.value.path
        port        = action.value.port
        protocol    = action.value.protocol
        query       = action.value.query
        status_code = action.value.status_code
      }
    }
  }

  dynamic "action" {
    for_each = [for action in each.value.actions : action if action.type == "fixed-response"]

    content {
      type  = "fixed-response"
      order = action.value.order

      fixed_response {
        content_type = action.value.content_type
        message_body = action.value.message_body
        status_code  = action.value.status_code
      }
    }
  }

  dynamic "action" {
    for_each = [for action in each.value.actions : action if action.type == "forward"]

    content {
      type             = "forward"
      order            = action.value.order
      target_group_arn = action.value.target_group_arn != null ? action.value.target_group_arn : aws_lb_target_group.this[action.value.target_group_key].arn
    }
  }

  dynamic "action" {
    for_each = [for action in each.value.actions : action if action.type == "weighted-forward"]

    content {
      type  = "forward"
      order = action.value.order

      forward {
        dynamic "target_group" {
          for_each = action.value.target_groups != null ? action.value.target_groups : []

          content {
            arn    = target_group.value.arn != null ? target_group.value.arn : aws_lb_target_group.this[target_group.value.target_group_key].arn
            weight = target_group.value.weight
          }
        }

        dynamic "stickiness" {
          for_each = action.value.stickiness != null ? [action.value.stickiness] : []

          content {
            enabled  = stickiness.value.enabled
            duration = stickiness.value.duration
          }
        }
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in each.value.conditions : condition if condition.host_header != null]

    content {
      host_header {
        values       = condition.value.host_header.values
        regex_values = condition.value.host_header.regex_values
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in each.value.conditions : condition if condition.http_header != null]

    content {
      http_header {
        http_header_name = condition.value.http_header.http_header_name
        values           = condition.value.http_header.values
        regex_values     = condition.value.http_header.regex_values
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in each.value.conditions : condition if condition.http_request_method != null]

    content {
      http_request_method {
        values = condition.value.http_request_method.values
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in each.value.conditions : condition if condition.path_pattern != null]

    content {
      path_pattern {
        values       = condition.value.path_pattern.values
        regex_values = condition.value.path_pattern.regex_values
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in each.value.conditions : condition if condition.query_string != null]

    content {
      query_string {
        key   = condition.value.query_string.key
        value = condition.value.query_string.value
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in each.value.conditions : condition if condition.source_ip != null]

    content {
      source_ip {
        values = condition.value.source_ip.values
      }
    }
  }

  dynamic "action" {
    for_each = [for action in each.value.actions : action if action.type == "jwt-validation"]

    content {
      type  = "jwt-validation"
      order = action.value.order

      jwt_validation {
        issuer        = action.value.issuer
        jwks_endpoint = action.value.jwks_endpoint

        dynamic "additional_claim" {
          for_each = action.value.additional_claims != null ? action.value.additional_claims : []

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
    for_each = each.value.transforms
    content {
      type = transform.value.type

      dynamic "url_rewrite_config" {
        for_each = transform.value.type == "url-rewrite" && transform.value.url_rewrite_config != null ? [transform.value.url_rewrite_config] : []
        content {
          dynamic "rewrite" {
            for_each = url_rewrite_config.value.rewrite != null ? [url_rewrite_config.value.rewrite] : []
            content {
              regex   = rewrite.value.regex
              replace = rewrite.value.replace
            }
          }
        }
      }

      dynamic "host_header_rewrite_config" {
        for_each = transform.value.type == "host-header-rewrite" && transform.value.host_header_rewrite_config != null ? [transform.value.host_header_rewrite_config] : []
        content {
          dynamic "rewrite" {
            for_each = host_header_rewrite_config.value.rewrite != null ? [host_header_rewrite_config.value.rewrite] : []
            content {
              regex   = rewrite.value.regex
              replace = rewrite.value.replace
            }
          }
        }
      }
    }
  }

  tags = merge(local.tags, each.value.tags)
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
      # Keyed by certificate ARN so that adding/removing a certificate in the
      # middle of the list does not detach and reattach the remaining ones.
      # Note: certificate ARNs must be known at plan time (no computed values
      # in for_each keys) - pass literal ARNs or apply the certificates first.
      for cert_arn in listener_values.additional_certificate_arns :
      "${listener_key}/${cert_arn}" => {
        listener_key    = listener_key
        certificate_arn = cert_arn
      }
    } if length(listener_values.additional_certificate_arns) > 0
  })...)
}

resource "aws_lb_listener_certificate" "this" {
  for_each = { for k, v in local.additional_certs : k => v if local.enabled }

  listener_arn    = aws_lb_listener.this[each.value.listener_key].arn
  certificate_arn = each.value.certificate_arn
}

################################################################################
# Target Group(s)
################################################################################

resource "aws_lb_target_group" "this" {
  for_each = { for k, v in var.target_groups : k => v if local.enabled }

  connection_termination = each.value.connection_termination
  deregistration_delay   = each.value.deregistration_delay

  dynamic "health_check" {
    for_each = each.value.health_check != null ? [each.value.health_check] : []

    content {
      enabled             = health_check.value.enabled
      healthy_threshold   = health_check.value.healthy_threshold
      interval            = health_check.value.interval
      matcher             = health_check.value.matcher
      path                = health_check.value.path
      port                = health_check.value.port
      protocol            = health_check.value.protocol
      timeout             = health_check.value.timeout
      unhealthy_threshold = health_check.value.unhealthy_threshold
    }
  }

  ip_address_type                    = each.value.ip_address_type
  lambda_multi_value_headers_enabled = each.value.lambda_multi_value_headers_enabled
  load_balancing_algorithm_type      = each.value.load_balancing_algorithm_type
  load_balancing_anomaly_mitigation  = each.value.load_balancing_anomaly_mitigation
  load_balancing_cross_zone_enabled  = each.value.load_balancing_cross_zone_enabled
  name                               = each.value.name
  name_prefix                        = each.value.name_prefix != null ? format("%s-", each.value.name_prefix) : null
  port                               = each.value.target_type == "lambda" ? null : coalesce(each.value.port, var.default_port)
  preserve_client_ip                 = each.value.preserve_client_ip
  protocol                           = each.value.target_type == "lambda" ? null : coalesce(each.value.protocol, var.default_protocol)
  protocol_version                   = each.value.protocol_version
  proxy_protocol_v2                  = each.value.proxy_protocol_v2
  slow_start                         = each.value.slow_start
  target_control_port                = each.value.target_control_port

  dynamic "stickiness" {
    for_each = each.value.stickiness != null ? [each.value.stickiness] : []

    content {
      cookie_duration = stickiness.value.cookie_duration
      cookie_name     = stickiness.value.cookie_name
      enabled         = stickiness.value.enabled
      type            = var.load_balancer_type == "network" ? "source_ip" : stickiness.value.type
    }
  }

  dynamic "target_failover" {
    for_each = each.value.target_failover

    content {
      on_deregistration = target_failover.value.on_deregistration
      on_unhealthy      = target_failover.value.on_unhealthy
    }
  }

  dynamic "target_group_health" {
    for_each = each.value.target_group_health != null ? [each.value.target_group_health] : []

    content {

      dynamic "dns_failover" {
        for_each = target_group_health.value.dns_failover != null ? [target_group_health.value.dns_failover] : []

        content {
          minimum_healthy_targets_count      = dns_failover.value.minimum_healthy_targets_count
          minimum_healthy_targets_percentage = dns_failover.value.minimum_healthy_targets_percentage
        }
      }

      dynamic "unhealthy_state_routing" {
        for_each = target_group_health.value.unhealthy_state_routing != null ? [target_group_health.value.unhealthy_state_routing] : []

        content {
          minimum_healthy_targets_count      = unhealthy_state_routing.value.minimum_healthy_targets_count
          minimum_healthy_targets_percentage = unhealthy_state_routing.value.minimum_healthy_targets_percentage
        }
      }
    }
  }

  dynamic "target_health_state" {
    for_each = each.value.target_health_state != null ? [each.value.target_health_state] : []
    content {
      enable_unhealthy_connection_termination = target_health_state.value.enable_unhealthy_connection_termination
      unhealthy_draining_interval             = target_health_state.value.unhealthy_draining_interval
    }
  }

  target_type = each.value.target_type
  vpc_id      = each.value.vpc_id != null ? each.value.vpc_id : var.vpc_id

  tags = merge(local.tags, each.value.tags)

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Target Group Attachment
################################################################################

resource "aws_lb_target_group_attachment" "this" {
  for_each = { for k, v in var.target_groups : k => v if local.enabled && v.create_attachment }

  target_group_arn  = aws_lb_target_group.this[each.key].arn
  target_id         = each.value.target_id
  port              = each.value.target_type == "lambda" ? null : coalesce(each.value.port, var.default_port)
  availability_zone = each.value.availability_zone
  quic_server_id    = each.value.quic_server_id

  depends_on = [aws_lambda_permission.this]
}

resource "aws_lb_target_group_attachment" "additional" {
  for_each = { for k, v in var.additional_target_group_attachments : k => v if local.enabled }

  target_group_arn  = aws_lb_target_group.this[each.value.target_group_key].arn
  target_id         = each.value.target_id
  port              = each.value.target_type == "lambda" ? null : coalesce(each.value.port, var.default_port)
  availability_zone = each.value.availability_zone
  quic_server_id    = each.value.quic_server_id

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
    (k) => merge(v, { lambda_function_name = try(split(":", v.target_id)[6], null) })
    if v.attach_lambda_permission
  }
}

resource "aws_lambda_permission" "this" {
  for_each = { for k, v in local.lambda_target_groups : k => v if local.enabled }

  function_name = each.value.lambda_function_name
  qualifier     = each.value.lambda_qualifier

  statement_id       = each.value.lambda_statement_id
  action             = each.value.lambda_action
  principal          = each.value.lambda_principal != null ? each.value.lambda_principal : "elasticloadbalancing.${data.aws_partition.current.dns_suffix}"
  source_arn         = aws_lb_target_group.this[each.key].arn
  source_account     = each.value.lambda_source_account
  event_source_token = each.value.lambda_event_source_token

  lifecycle {
    precondition {
      condition     = can(regex("^arn:[^:]+:lambda:[^:]*:[^:]*:function:.+", each.value.target_id))
      error_message = "Target group '${each.key}': target_id must be a full Lambda function ARN (arn:<partition>:lambda:<region>:<account-id>:function:<name>[:<qualifier>]) when attach_lambda_permission is true."
    }
  }
}

################################################################################
# Security Group
################################################################################

locals {
  create_security_group = local.enabled && var.create_security_group
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
  for_each = { for k, v in var.route53_records : k => v if local.enabled }

  zone_id = each.value.zone_id
  name    = try(each.value.name, each.key)
  type    = each.value.type

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = try(each.value.evaluate_target_health, true)
  }
}

################################################################################
# WAF
################################################################################

locals {
  create_web_acl_association = local.enabled && var.associate_web_acl
}

resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = aws_lb.this.arn
  web_acl_arn  = var.web_acl_arn

  lifecycle {
    enabled = local.create_web_acl_association
  }
}

################################################################################
# Trust Store(s)
# Used for mTLS mutual authentication on HTTPS listeners
################################################################################

resource "aws_lb_trust_store" "this" {
  for_each = { for k, v in var.trust_stores : k => v if local.enabled }

  ca_certificates_bundle_s3_bucket         = each.value.ca_certificates_bundle_s3_bucket
  ca_certificates_bundle_s3_key            = each.value.ca_certificates_bundle_s3_key
  ca_certificates_bundle_s3_object_version = try(each.value.ca_certificates_bundle_s3_object_version, null)
  name                                     = try(each.value.name, null)
  name_prefix                              = try(each.value.name_prefix, null)

  tags = merge(local.tags, try(each.value.tags, {}))
}

resource "aws_lb_trust_store_revocation" "this" {
  for_each = { for k, v in var.trust_store_revocations : k => v if local.enabled }

  trust_store_arn               = try(each.value.trust_store_arn, aws_lb_trust_store.this[each.value.trust_store_key].arn)
  revocations_s3_bucket         = each.value.revocations_s3_bucket
  revocations_s3_key            = each.value.revocations_s3_key
  revocations_s3_object_version = try(each.value.revocations_s3_object_version, null)
}