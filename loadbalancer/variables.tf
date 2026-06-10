variable "name" {
  description = "Name to use for resource naming and tagging."
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

################################################################################
# Load Balancer
################################################################################

variable "access_logs" {
  description = "Map containing access logging configuration for load balancer"
  type        = map(string)
  default     = {}
}

variable "connection_logs" {
  description = "Map containing connection logging configuration for load balancer (ALB only)"
  type        = map(string)
  default     = {}
}

variable "health_check_logs" {
  description = "Map containing health check logging configuration for load balancer (ALB only). Requires `bucket`, optional `enabled` and `prefix`"
  type        = map(string)
  default     = {}
}

variable "ipam_pools" {
  description = "Map containing IPAM pool configuration for load balancer (ALB only). Requires `ipv4_ipam_pool_id`"
  type        = map(string)
  default     = {}
}

variable "minimum_load_balancer_capacity" {
  description = "Pre-warm capacity for the load balancer. Requires `capacity_units` (number). Billing applies during the pre-warming period"
  type        = any
  default     = {}
}

variable "secondary_ips_auto_assigned_per_subnet" {
  description = "Number of secondary private IPv4 addresses to automatically assign to each NLB network interface. Valid values are 0-7. NLB only"
  type        = number
  default     = null
}

variable "client_keep_alive" {
  description = "Client keep alive value in seconds. The valid range is 60-604800 seconds. The default is 3600 seconds."
  type        = number
  default     = null

  validation {
    condition     = var.client_keep_alive == null || (var.client_keep_alive >= 60 && var.client_keep_alive <= 604800)
    error_message = "The client_keep_alive must be between 60 and 604800 seconds."
  }
}

variable "customer_owned_ipv4_pool" {
  description = "The ID of the customer owned ipv4 pool to use for this load balancer"
  type        = string
  default     = null
}

variable "desync_mitigation_mode" {
  description = "Determines how the load balancer handles requests that might pose a security risk to an application due to HTTP desync. Valid values are `monitor`, `defensive` (default), `strictest`"
  type        = string
  default     = null

  validation {
    condition     = var.desync_mitigation_mode == null || contains(["monitor", "defensive", "strictest"], var.desync_mitigation_mode)
    error_message = "The desync_mitigation_mode must be 'monitor', 'defensive', or 'strictest'."
  }
}

variable "dns_record_client_routing_policy" {
  description = "Indicates how traffic is distributed among the load balancer Availability Zones. Possible values are any_availability_zone (default), availability_zone_affinity, or partial_availability_zone_affinity. Only valid for network type load balancers."
  type        = string
  default     = null

  validation {
    condition     = var.dns_record_client_routing_policy == null || contains(["any_availability_zone", "availability_zone_affinity", "partial_availability_zone_affinity"], var.dns_record_client_routing_policy)
    error_message = "The dns_record_client_routing_policy must be 'any_availability_zone', 'availability_zone_affinity', or 'partial_availability_zone_affinity'."
  }
}

variable "drop_invalid_header_fields" {
  description = "Indicates whether HTTP headers with header fields that are not valid are removed by the load balancer (`true`) or routed to targets (`false`). The default is `true`. Elastic Load Balancing requires that message header names contain only alphanumeric characters and hyphens. Only valid for Load Balancers of type `application`"
  type        = bool
  default     = true
}

variable "enable_cross_zone_load_balancing" {
  description = "If `true`, cross-zone load balancing of the load balancer will be enabled. For application load balancer this feature is always enabled (`true`) and cannot be disabled. Defaults to `true`"
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "If `true`, deletion of the load balancer will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer. Defaults to `true`"
  type        = bool
  default     = true
}

variable "enable_http2" {
  description = "Indicates whether HTTP/2 is enabled in application load balancers. Defaults to `true`"
  type        = bool
  default     = null
}

variable "enable_tls_version_and_cipher_suite_headers" {
  description = "Indicates whether the two headers (`x-amzn-tls-version` and `x-amzn-tls-cipher-suite`), which contain information about the negotiated TLS version and cipher suite, are added to the client request before sending it to the target. Only valid for Load Balancers of type `application`. Defaults to `false`"
  type        = bool
  default     = null
}

variable "enable_waf_fail_open" {
  description = "Indicates whether to allow a WAF-enabled load balancer to route requests to targets if it is unable to forward the request to AWS WAF. Defaults to `false`"
  type        = bool
  default     = null
}

variable "enable_xff_client_port" {
  description = "Indicates whether the X-Forwarded-For header should preserve the source port that the client used to connect to the load balancer in `application` load balancers. Defaults to `false`"
  type        = bool
  default     = null
}

variable "enable_zonal_shift" {
  description = "Indicates whether zonal shift is enabled for the load balancer. Only valid for load balancers of type application or network."
  type        = bool
  default     = null
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle. Only valid for Load Balancers of type `application`. Default: `60`"
  type        = number
  default     = null
}

variable "internal" {
  description = "If true, the LB will be internal. Defaults to `true` so load balancers are not internet-facing unless explicitly requested; set to `false` for a public load balancer"
  type        = bool
  default     = true
}

variable "ip_address_type" {
  description = "The type of IP addresses used by the subnets for your load balancer. Possible values are `ipv4`, `dualstack`, and `dualstack-without-public-ipv4`"
  type        = string
  default     = null

  validation {
    condition     = var.ip_address_type == null || contains(["ipv4", "dualstack", "dualstack-without-public-ipv4"], var.ip_address_type)
    error_message = "The ip_address_type must be 'ipv4', 'dualstack', or 'dualstack-without-public-ipv4'."
  }
}

variable "load_balancer_type" {
  description = "The type of load balancer to create. Possible values are `application`, `gateway`, or `network`. The default value is `application`"
  type        = string
  default     = "application"

  validation {
    condition     = contains(["application", "gateway", "network"], var.load_balancer_type)
    error_message = "The load_balancer_type must be 'application', 'gateway', or 'network'."
  }
}

variable "enforce_security_group_inbound_rules_on_private_link_traffic" {
  description = "Indicates whether inbound security group rules are enforced for traffic originating from a PrivateLink. Only valid for Load Balancers of type network. The possible values are on and off."
  type        = string
  default     = null

  validation {
    condition     = var.enforce_security_group_inbound_rules_on_private_link_traffic == null || contains(["on", "off"], var.enforce_security_group_inbound_rules_on_private_link_traffic)
    error_message = "The enforce_security_group_inbound_rules_on_private_link_traffic must be 'on' or 'off'."
  }
}

# variable "name" {
#   description = "The name of the LB. This name must be unique within your AWS account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and must not begin or end with a hyphen"
#   type        = string
#   default     = null
# }

variable "name_prefix" {
  description = "Creates a unique name beginning with the specified prefix. Conflicts with `name`"
  type        = string
  default     = null
}

variable "preserve_host_header" {
  description = "Indicates whether the Application Load Balancer should preserve the Host header in the HTTP request and send it to the target without any change. Defaults to `false`"
  type        = bool
  default     = null
}

variable "security_groups" {
  description = "A list of security group IDs to assign to the LB"
  type        = list(string)
  default     = []
}

variable "subnet_mapping" {
  description = "A list of subnet mapping blocks describing subnets to attach to load balancer"
  type        = list(map(string))
  default     = []
}

variable "subnets" {
  description = "A list of subnet IDs to attach to the LB. Subnets cannot be updated for Load Balancers of type `network`. Changing this value for load balancers of type `network` will force a recreation of the resource"
  type        = list(string)
  default     = null
}

variable "xff_header_processing_mode" {
  description = "Determines how the load balancer modifies the X-Forwarded-For header in the HTTP request before sending the request to the target. The possible values are `append`, `preserve`, and `remove`. Only valid for Load Balancers of type `application`. The default is `append`"
  type        = string
  default     = null

  validation {
    condition     = var.xff_header_processing_mode == null || contains(["append", "preserve", "remove"], var.xff_header_processing_mode)
    error_message = "The xff_header_processing_mode must be 'append', 'preserve', or 'remove'."
  }
}

variable "timeouts" {
  description = "Create, update, and delete timeout configurations for the load balancer"
  type        = map(string)
  default     = {}
}

################################################################################
# Listener(s)
################################################################################

variable "default_port" {
  description = "Default port used across the listener and target group"
  type        = number
  default     = 80

  validation {
    condition     = var.default_port >= 1 && var.default_port <= 65535
    error_message = "The default_port must be between 1 and 65535."
  }
}

variable "default_protocol" {
  description = "Default protocol used across the listener and target group"
  type        = string
  default     = "HTTP"
}

variable "listeners" {
  description = "Map of listener configurations to create. Each listener defines exactly one default action (`forward`, `weighted_forward`, `redirect`, `fixed_response`, `authenticate_cognito`, `authenticate_oidc`, or `jwt_validation`) and an optional map of `rules`. OIDC client secrets must be provided via `listener_auth_oidc_client_secrets` - inline `client_secret` values are rejected"
  type = map(object({
    alpn_policy                 = optional(string)
    certificate_arn             = optional(string)
    additional_certificate_arns = optional(list(string), [])
    port                        = optional(number)
    protocol                    = optional(string)
    ssl_policy                  = optional(string)
    tcp_idle_timeout_seconds    = optional(number)
    tags                        = optional(map(string), {})

    # Default action - exactly one of the following must be set
    forward = optional(object({
      arn              = optional(string)
      target_group_key = optional(string)
      order            = optional(number)
    }))
    weighted_forward = optional(object({
      target_groups = list(object({
        arn              = optional(string)
        target_group_key = optional(string)
        weight           = optional(number)
      }))
      stickiness = optional(object({
        duration = optional(number, 60)
        enabled  = optional(bool)
      }))
      order = optional(number)
    }))
    redirect = optional(object({
      host        = optional(string)
      path        = optional(string)
      port        = optional(string)
      protocol    = optional(string)
      query       = optional(string)
      status_code = string
      order       = optional(number)
    }))
    fixed_response = optional(object({
      content_type = string
      message_body = optional(string)
      status_code  = optional(string)
      order        = optional(number)
    }))
    authenticate_cognito = optional(object({
      authentication_request_extra_params = optional(map(string))
      on_unauthenticated_request          = optional(string)
      scope                               = optional(string)
      session_cookie_name                 = optional(string)
      session_timeout                     = optional(number)
      user_pool_arn                       = string
      user_pool_client_id                 = string
      user_pool_domain                    = string
      order                               = optional(number)
    }))
    authenticate_oidc = optional(object({
      authentication_request_extra_params = optional(map(string))
      authorization_endpoint              = string
      client_id                           = string
      client_secret                       = optional(string) # rejected by validation - use listener_auth_oidc_client_secrets
      issuer                              = string
      on_unauthenticated_request          = optional(string)
      scope                               = optional(string)
      session_cookie_name                 = optional(string)
      session_timeout                     = optional(number)
      token_endpoint                      = string
      user_info_endpoint                  = string
      order                               = optional(number)
    }))
    jwt_validation = optional(object({
      issuer        = string
      jwks_endpoint = string
      additional_claims = optional(list(object({
        format = string
        name   = string
        values = list(string)
      })), [])
      order = optional(number)
    }))

    mutual_authentication = optional(object({
      mode                             = string
      trust_store_arn                  = optional(string)
      trust_store_key                  = optional(string)
      advertise_trust_store_ca_names   = optional(string)
      ignore_client_certificate_expiry = optional(bool)
    }))

    routing_http_request_x_amzn_mtls_clientcert_header_name               = optional(string)
    routing_http_request_x_amzn_mtls_clientcert_issuer_header_name        = optional(string)
    routing_http_request_x_amzn_mtls_clientcert_leaf_header_name          = optional(string)
    routing_http_request_x_amzn_mtls_clientcert_serial_number_header_name = optional(string)
    routing_http_request_x_amzn_mtls_clientcert_subject_header_name       = optional(string)
    routing_http_request_x_amzn_mtls_clientcert_validity_header_name      = optional(string)
    routing_http_request_x_amzn_tls_cipher_suite_header_name              = optional(string)
    routing_http_request_x_amzn_tls_version_header_name                   = optional(string)
    routing_http_response_access_control_allow_credentials_header_value   = optional(string)
    routing_http_response_access_control_allow_headers_header_value       = optional(string)
    routing_http_response_access_control_allow_methods_header_value       = optional(string)
    routing_http_response_access_control_allow_origin_header_value        = optional(string)
    routing_http_response_access_control_expose_headers_header_value      = optional(string)
    routing_http_response_access_control_max_age_header_value             = optional(string)
    routing_http_response_content_security_policy_header_value            = optional(string)
    routing_http_response_server_enabled                                  = optional(bool)
    routing_http_response_strict_transport_security_header_value          = optional(string)
    routing_http_response_x_content_type_options_header_value             = optional(string)
    routing_http_response_x_frame_options_header_value                    = optional(string)

    rules = optional(map(object({
      listener_arn = optional(string)
      priority     = optional(number)
      tags         = optional(map(string), {})

      actions = list(object({
        type  = string
        order = optional(number)

        # forward
        target_group_arn = optional(string)
        target_group_key = optional(string)

        # weighted-forward
        target_groups = optional(list(object({
          arn              = optional(string)
          target_group_key = optional(string)
          weight           = optional(number)
        })))
        stickiness = optional(object({
          duration = optional(number, 60)
          enabled  = optional(bool)
        }))

        # redirect
        host        = optional(string)
        path        = optional(string)
        port        = optional(string)
        protocol    = optional(string)
        query       = optional(string)
        status_code = optional(string)

        # fixed-response
        content_type = optional(string)
        message_body = optional(string)

        # authenticate-cognito
        authentication_request_extra_params = optional(map(string))
        on_unauthenticated_request          = optional(string)
        scope                               = optional(string)
        session_cookie_name                 = optional(string)
        session_timeout                     = optional(number)
        user_pool_arn                       = optional(string)
        user_pool_client_id                 = optional(string)
        user_pool_domain                    = optional(string)

        # authenticate-oidc
        authorization_endpoint = optional(string)
        client_id              = optional(string)
        client_secret          = optional(string) # rejected by validation - use listener_auth_oidc_client_secrets
        issuer                 = optional(string)
        token_endpoint         = optional(string)
        user_info_endpoint     = optional(string)

        # jwt-validation
        jwks_endpoint = optional(string)
        additional_claims = optional(list(object({
          format = string
          name   = string
          values = list(string)
        })))
      }))

      conditions = optional(list(object({
        host_header = optional(object({
          values       = optional(list(string))
          regex_values = optional(list(string))
        }))
        http_header = optional(object({
          http_header_name = string
          values           = optional(list(string))
          regex_values     = optional(list(string))
        }))
        http_request_method = optional(object({
          values = list(string)
        }))
        path_pattern = optional(object({
          values       = optional(list(string))
          regex_values = optional(list(string))
        }))
        query_string = optional(object({
          key   = optional(string)
          value = string
        }))
        source_ip = optional(object({
          values = list(string)
        }))
      })), [])

      transforms = optional(list(object({
        type = string
        url_rewrite_config = optional(object({
          rewrite = optional(object({
            regex   = string
            replace = string
          }))
        }))
        host_header_rewrite_config = optional(object({
          rewrite = optional(object({
            regex   = string
            replace = string
          }))
        }))
      })), [])
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for listener in values(var.listeners) :
      length(compact([
        listener.forward != null ? "forward" : "",
        listener.weighted_forward != null ? "weighted_forward" : "",
        listener.redirect != null ? "redirect" : "",
        listener.fixed_response != null ? "fixed_response" : "",
        listener.authenticate_cognito != null ? "authenticate_cognito" : "",
        listener.authenticate_oidc != null ? "authenticate_oidc" : "",
        listener.jwt_validation != null ? "jwt_validation" : "",
      ])) == 1
    ])
    error_message = "Each listener must define exactly one default action: forward, weighted_forward, redirect, fixed_response, authenticate_cognito, authenticate_oidc, or jwt_validation."
  }

  validation {
    condition = alltrue(flatten([
      for listener in values(var.listeners) : concat(
        [listener.authenticate_oidc == null || try(listener.authenticate_oidc.client_secret, null) == null],
        [
          for rule in values(listener.rules) : [
            for action in rule.actions : action.client_secret == null
          ]
        ]
      )
    ]))
    error_message = "Inline `client_secret` is not supported in `listeners` (default actions or rule actions). Provide OIDC client secrets via the sensitive `listener_auth_oidc_client_secrets` map, keyed by listener key (default actions) or \"<listener_key>/<rule_key>\" (rule actions)."
  }

  validation {
    condition = alltrue(flatten([
      for rules in [for listener in values(var.listeners) : listener.rules] : [
        for rule in values(rules) : [
          for action in rule.actions :
          contains(["forward", "weighted-forward", "redirect", "fixed-response", "authenticate-cognito", "authenticate-oidc", "jwt-validation"], action.type)
        ]
      ]
    ]))
    error_message = "Each listener rule action `type` must be one of: forward, weighted-forward, redirect, fixed-response, authenticate-cognito, authenticate-oidc, jwt-validation."
  }

  validation {
    condition = alltrue(flatten([
      for listener_key, listener in var.listeners : concat(
        [listener.authenticate_oidc == null || contains(nonsensitive(keys(var.listener_auth_oidc_client_secrets)), listener_key)],
        [
          for rule_key, rule in listener.rules : alltrue([
            for action in rule.actions :
            action.type != "authenticate-oidc" || contains(nonsensitive(keys(var.listener_auth_oidc_client_secrets)), "${listener_key}/${rule_key}")
          ])
        ]
      )
    ]))
    error_message = "Every `authenticate-oidc` action requires a matching entry in `listener_auth_oidc_client_secrets`, keyed by the listener key (default actions) or \"<listener_key>/<rule_key>\" (rule actions)."
  }
}

variable "listener_auth_oidc_client_secrets" {
  description = "Map of OIDC client secrets for `authenticate-oidc` actions, keyed by listener key (for listener default actions) or `<listener_key>/<rule_key>` (for listener rule actions). This is the only way to supply OIDC client secrets - inline `client_secret` values in `listeners` are rejected. Every `authenticate-oidc` action must have a matching entry here"
  type        = map(string)
  default     = {}
  sensitive   = true
}

################################################################################
# Target Group
################################################################################

variable "target_groups" {
  description = "Map of target group configurations to create. Set `create_attachment = false` to skip the target group attachment (e.g. when targets register themselves via autoscaling)"
  type = map(object({
    connection_termination             = optional(bool)
    deregistration_delay               = optional(number)
    ip_address_type                    = optional(string)
    lambda_multi_value_headers_enabled = optional(bool)
    load_balancing_algorithm_type      = optional(string)
    load_balancing_anomaly_mitigation  = optional(string)
    load_balancing_cross_zone_enabled  = optional(string)
    name                               = optional(string)
    name_prefix                        = optional(string)
    port                               = optional(number)
    preserve_client_ip                 = optional(bool)
    protocol                           = optional(string)
    protocol_version                   = optional(string)
    proxy_protocol_v2                  = optional(bool)
    slow_start                         = optional(number)
    target_control_port                = optional(number)
    target_type                        = optional(string)
    vpc_id                             = optional(string)
    tags                               = optional(map(string), {})

    health_check = optional(object({
      enabled             = optional(bool)
      healthy_threshold   = optional(number)
      interval            = optional(number)
      matcher             = optional(string)
      path                = optional(string)
      port                = optional(string)
      protocol            = optional(string)
      timeout             = optional(number)
      unhealthy_threshold = optional(number)
    }))

    stickiness = optional(object({
      cookie_duration = optional(number)
      cookie_name     = optional(string)
      enabled         = optional(bool, true)
      type            = optional(string)
    }))

    target_failover = optional(list(object({
      on_deregistration = string
      on_unhealthy      = string
    })), [])

    target_group_health = optional(object({
      dns_failover = optional(object({
        minimum_healthy_targets_count      = optional(string)
        minimum_healthy_targets_percentage = optional(string)
      }))
      unhealthy_state_routing = optional(object({
        minimum_healthy_targets_count      = optional(number)
        minimum_healthy_targets_percentage = optional(string)
      }))
    }))

    target_health_state = optional(object({
      enable_unhealthy_connection_termination = optional(bool, true)
      unhealthy_draining_interval             = optional(number)
    }))

    # Attachment
    create_attachment = optional(bool, true)
    target_id         = optional(string)
    availability_zone = optional(string)
    quic_server_id    = optional(string)

    # Lambda permission (when the target is a Lambda function)
    attach_lambda_permission  = optional(bool, false)
    lambda_qualifier          = optional(string)
    lambda_statement_id       = optional(string, "AllowExecutionFromLb")
    lambda_action             = optional(string, "lambda:InvokeFunction")
    lambda_principal          = optional(string)
    lambda_source_account     = optional(string)
    lambda_event_source_token = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for tg in values(var.target_groups) :
      tg.target_id != null if tg.create_attachment
    ])
    error_message = "Each target group with `create_attachment = true` (the default) must set `target_id`. Set `create_attachment = false` for target groups whose targets register themselves."
  }
}

variable "additional_target_group_attachments" {
  description = "Map of additional target group attachments to create. Use `target_group_key` to attach to the target group created in `target_groups`"
  type = map(object({
    target_group_key  = string
    target_id         = string
    port              = optional(number)
    target_type       = optional(string)
    availability_zone = optional(string)
    quic_server_id    = optional(string)
  }))
  default = {}
}

################################################################################
# Security Group
################################################################################

variable "create_security_group" {
  description = "Determines if a security group is created"
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "Name to use on security group created"
  type        = string
  default     = null
}

variable "security_group_use_name_prefix" {
  description = "Determines whether the security group name (`security_group_name`) is used as a prefix"
  type        = bool
  default     = true
}

variable "security_group_description" {
  description = "Description of the security group created"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "Identifier of the VPC where the security group will be created"
  type        = string
  default     = null

  validation {
    condition     = var.vpc_id == null || can(regex("^vpc-", var.vpc_id))
    error_message = "The vpc_id must start with 'vpc-'."
  }
}

variable "security_group_ingress_rules" {
  description = "Security group ingress rules to add to the security group created"
  type        = any
  default     = {}
}

variable "security_group_egress_rules" {
  description = "Security group egress rules to add to the security group created"
  type        = any
  default     = {}
}

variable "security_group_tags" {
  description = "A map of additional tags to add to the security group created"
  type        = map(string)
  default     = {}
}

################################################################################
# Route53 Record(s)
################################################################################

variable "route53_records" {
  description = "Map of Route53 records to create. Each record map should contain `zone_id`, `name`, and `type`"
  type        = any
  default     = {}
}

################################################################################
# WAF
################################################################################

variable "associate_web_acl" {
  description = "Indicates whether a Web Application Firewall (WAF) ACL should be associated with the load balancer"
  type        = bool
  default     = false
}

variable "web_acl_arn" {
  description = "Web Application Firewall (WAF) ARN of the resource to associate with the load balancer"
  type        = string
  default     = null

  validation {
    condition     = var.web_acl_arn == null || can(regex("^arn:", var.web_acl_arn))
    error_message = "The web_acl_arn must be a valid ARN starting with 'arn:'."
  }
}

################################################################################
# Trust Store(s)
################################################################################

variable "trust_stores" {
  description = "Map of trust store configurations to create for mTLS mutual authentication. Each entry requires `ca_certificates_bundle_s3_bucket` and `ca_certificates_bundle_s3_key`. Use `trust_store_key` in listener `mutual_authentication.trust_store_arn` to reference created stores"
  type        = any
  default     = {}
}

variable "trust_store_revocations" {
  description = "Map of trust store revocation configurations. Each entry requires `revocations_s3_bucket`, `revocations_s3_key`, and either `trust_store_arn` (existing) or `trust_store_key` (references a key in `trust_stores`)"
  type        = any
  default     = {}
}

################################################################################