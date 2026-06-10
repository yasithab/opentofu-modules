
###################################################
# Policy variables
###################################################

variable "cache_policies" {
  description = "Map of CloudFront cache policies to create. Map key is used as the policy name. Supports: comment, default_ttl, max_ttl, min_ttl, cookie_behavior, cookies_items, header_behavior, headers_items, query_string_behavior, query_strings_items, enable_accept_encoding_brotli, enable_accept_encoding_gzip."
  type        = any
  default     = {}
}

variable "origin_request_policies" {
  description = "Map of CloudFront origin request policies to create. Map key is used as the policy name. Supports: comment, cookie_behavior, cookies_items, header_behavior, headers_items, query_string_behavior, query_strings_items."
  type        = any
  default     = {}
}

variable "response_headers_policies" {
  description = "Map of CloudFront response headers policies to create. Map key is used as the policy name. Supports: comment, cors (object), custom_headers (list), remove_headers (set), content_security_policy_header, content_type_options_header, frame_options_header, referrer_policy_header, strict_transport_security_header, xss_protection_header, server_timing_header."
  type        = any
  default     = {}
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

variable "distribution_enabled" {
  description = "Whether the CloudFront distribution accepts end user requests for content. Decoupled from `enabled` (which controls resource creation), so a distribution can be kept in state but disabled"
  type        = bool
  default     = true
}

variable "create_origin_access_identity" {
  description = "Controls if CloudFront origin access identity should be created"
  type        = bool
  default     = false
}

variable "origin_access_identities" {
  description = "Map of CloudFront origin access identities (value as a comment)"
  type        = map(string)
  default     = {}
}

variable "create_origin_access_control" {
  description = "Controls if CloudFront origin access control should be created"
  type        = bool
  default     = false
}

variable "origin_access_control" {
  description = "Map of CloudFront origin access control"
  type = map(object({
    description      = string
    origin_type      = string
    signing_behavior = string
    signing_protocol = string
  }))

  default = {
    s3 = {
      description      = "",
      origin_type      = "s3",
      signing_behavior = "always",
      signing_protocol = "sigv4"
    }
  }
}

variable "aliases" {
  description = "Extra CNAMEs (alternate domain names), if any, for this distribution."
  type        = list(string)
  default     = null
}

variable "comment" {
  description = "Any comments you want to include about the distribution."
  type        = string
  default     = null
}

variable "continuous_deployment_policy_id" {
  description = "Identifier of a continuous deployment policy. This argument should only be set on a production distribution."
  type        = string
  default     = null
}

variable "default_root_object" {
  description = "The object that you want CloudFront to return (for example, index.html) when an end user requests the root URL."
  type        = string
  default     = null
}

variable "http_version" {
  description = "The maximum HTTP version to support on the distribution. Allowed values are http1.1, http2, http2and3, and http3. The default is http2."
  type        = string
  default     = "http2"

  validation {
    condition     = contains(["http1.1", "http2", "http2and3", "http3"], var.http_version)
    error_message = "http_version must be one of: http1.1, http2, http2and3, http3."
  }
}

variable "is_ipv6_enabled" {
  description = "Whether the IPv6 is enabled for the distribution."
  type        = bool
  default     = null
}

variable "price_class" {
  description = "The price class for this distribution. One of PriceClass_All, PriceClass_200, PriceClass_100"
  type        = string
  default     = null

  validation {
    condition     = var.price_class == null || contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "price_class must be one of: PriceClass_All, PriceClass_200, PriceClass_100."
  }
}

variable "retain_on_delete" {
  description = "Disables the distribution instead of deleting it when destroying the resource through Terraform. If this is set, the distribution needs to be deleted manually afterwards."
  type        = bool
  default     = false
}

variable "wait_for_deployment" {
  description = "If enabled, the resource will wait for the distribution status to change from InProgress to Deployed. Setting this to false will skip the process."
  type        = bool
  default     = true
}

variable "web_acl_id" {
  description = "If you're using AWS WAF to filter CloudFront requests, the Id of the AWS WAF web ACL that is associated with the distribution. The WAF Web ACL must exist in the WAF Global (CloudFront) region and the credentials configuring this argument must have waf:GetWebACL permissions assigned. If using WAFv2, provide the ARN of the web ACL."
  type        = string
  default     = null
}

variable "staging" {
  description = "Whether the distribution is a staging distribution."
  type        = bool
  default     = false
}

variable "origin" {
  description = "Map of origins for this distribution. The map key is used as `origin_id` unless overridden. Exactly one of `custom_origin_config`, `s3_origin_config` (legacy OAI), `vpc_origin_config`, or `origin_access_control_id`/`origin_access_control` should be used per origin. `origin_access_control` and `s3_origin_config.origin_access_identity`/`vpc_origin_config.vpc_origin` accept names of OAC/OAI/VPC-origin resources created inline by this module."
  type = map(object({
    domain_name                 = string
    origin_id                   = optional(string)
    origin_path                 = optional(string, "")
    connection_attempts         = optional(number)
    connection_timeout          = optional(number)
    response_completion_timeout = optional(number)
    origin_access_control_id    = optional(string)
    origin_access_control       = optional(string)
    custom_headers              = optional(map(string), {})
    custom_origin_config = optional(object({
      http_port                = optional(number, 80)
      https_port               = optional(number, 443)
      origin_protocol_policy   = optional(string, "https-only")
      origin_ssl_protocols     = optional(list(string), ["TLSv1.2"])
      origin_keepalive_timeout = optional(number)
      origin_read_timeout      = optional(number)
      ip_address_type          = optional(string)
    }))
    s3_origin_config = optional(object({
      cloudfront_access_identity_path = optional(string)
      origin_access_identity          = optional(string)
    }))
    origin_shield = optional(object({
      enabled              = optional(bool, true)
      origin_shield_region = string
    }))
    vpc_origin_config = optional(object({
      vpc_origin_id            = optional(string)
      vpc_origin               = optional(string)
      origin_keepalive_timeout = optional(number)
      origin_read_timeout      = optional(number)
      owner_account_id         = optional(string)
    }))
  }))
  default = {}
}

variable "origin_group" {
  description = "Map of origin groups for this distribution. The map key is used as `origin_id` unless overridden."
  type = map(object({
    origin_id                  = optional(string)
    failover_status_codes      = list(number)
    primary_member_origin_id   = string
    secondary_member_origin_id = string
  }))
  default = {}
}

variable "viewer_certificate" {
  description = "The SSL configuration for this distribution. minimum_protocol_version defaults to TLSv1.2_2021; override only if legacy clients require an older protocol"
  type = object({
    acm_certificate_arn            = optional(string)
    cloudfront_default_certificate = optional(bool)
    iam_certificate_id             = optional(string)
    minimum_protocol_version       = optional(string, "TLSv1.2_2021")
    ssl_support_method             = optional(string)
  })
  default = {
    cloudfront_default_certificate = true
  }
}

variable "geo_restriction" {
  description = "The restriction configuration for this distribution (geo_restrictions)"
  type        = any
  default     = {}
}

variable "logging_config" {
  description = "The logging configuration that controls how logs are written to your distribution (maximum one). Strongly recommended for production distributions. Set to null (default) to disable logging"
  type = object({
    bucket          = string
    prefix          = optional(string)
    include_cookies = optional(bool)
  })
  default = null
}

variable "custom_error_response" {
  description = "List of custom error response elements"
  type = list(object({
    error_code            = number
    response_code         = optional(number)
    response_page_path    = optional(string)
    error_caching_min_ttl = optional(number)
  }))
  default = []
}

variable "default_cache_behavior" {
  description = "The default cache behavior for this distribution (required). A cache policy is mandatory: set `cache_policy_id` (e.g. an AWS managed policy ID) or `cache_policy_name` (inline policy from `cache_policies`, or an AWS/externally managed policy looked up by name). Legacy `forwarded_values` is not supported. The `*_name` variants of origin request, response headers and realtime log config follow the same resolution rules."
  type = object({
    target_origin_id          = string
    viewer_protocol_policy    = optional(string, "redirect-to-https")
    allowed_methods           = optional(list(string), ["GET", "HEAD", "OPTIONS"])
    cached_methods            = optional(list(string), ["GET", "HEAD"])
    compress                  = optional(bool, true)
    field_level_encryption_id = optional(string)
    smooth_streaming          = optional(bool)
    trusted_signers           = optional(list(string))
    trusted_key_groups        = optional(list(string))

    cache_policy_id              = optional(string)
    cache_policy_name            = optional(string)
    origin_request_policy_id     = optional(string)
    origin_request_policy_name   = optional(string)
    response_headers_policy_id   = optional(string)
    response_headers_policy_name = optional(string)

    realtime_log_config_arn  = optional(string)
    realtime_log_config_name = optional(string)

    function_association = optional(list(object({
      event_type    = string
      function_arn  = optional(string)
      function_name = optional(string)
    })), [])

    lambda_function_association = optional(list(object({
      event_type   = string
      lambda_arn   = string
      include_body = optional(bool)
    })), [])

    grpc_config = optional(object({
      enabled = bool
    }))
  })

  validation {
    condition     = var.default_cache_behavior.cache_policy_id != null || var.default_cache_behavior.cache_policy_name != null
    error_message = "default_cache_behavior requires a cache policy: set cache_policy_id (e.g. AWS managed CachingOptimized: 658327ea-f89d-4fab-a63d-7e88639e58f6) or cache_policy_name. Legacy forwarded_values is no longer supported."
  }

  validation {
    condition = alltrue([
      for f in var.default_cache_behavior.function_association :
      f.function_arn != null || f.function_name != null
    ])
    error_message = "Each function_association entry requires either function_arn or function_name."
  }
}

variable "ordered_cache_behavior" {
  description = "An ordered list of cache behaviors for this distribution, evaluated top to bottom (the topmost behavior has precedence 0). Same shape as `default_cache_behavior` plus the required `path_pattern`. A cache policy (`cache_policy_id` or `cache_policy_name`) is mandatory per behavior; legacy `forwarded_values` is not supported."
  type = list(object({
    path_pattern              = string
    target_origin_id          = string
    viewer_protocol_policy    = optional(string, "redirect-to-https")
    allowed_methods           = optional(list(string), ["GET", "HEAD", "OPTIONS"])
    cached_methods            = optional(list(string), ["GET", "HEAD"])
    compress                  = optional(bool, true)
    field_level_encryption_id = optional(string)
    smooth_streaming          = optional(bool)
    trusted_signers           = optional(list(string))
    trusted_key_groups        = optional(list(string))

    cache_policy_id              = optional(string)
    cache_policy_name            = optional(string)
    origin_request_policy_id     = optional(string)
    origin_request_policy_name   = optional(string)
    response_headers_policy_id   = optional(string)
    response_headers_policy_name = optional(string)

    realtime_log_config_arn  = optional(string)
    realtime_log_config_name = optional(string)

    function_association = optional(list(object({
      event_type    = string
      function_arn  = optional(string)
      function_name = optional(string)
    })), [])

    lambda_function_association = optional(list(object({
      event_type   = string
      lambda_arn   = string
      include_body = optional(bool)
    })), [])

    grpc_config = optional(object({
      enabled = bool
    }))
  }))
  default = []

  validation {
    condition = alltrue([
      for b in var.ordered_cache_behavior :
      b.cache_policy_id != null || b.cache_policy_name != null
    ])
    error_message = "Every ordered_cache_behavior requires a cache policy: set cache_policy_id (e.g. AWS managed CachingOptimized: 658327ea-f89d-4fab-a63d-7e88639e58f6) or cache_policy_name. Legacy forwarded_values is no longer supported."
  }

  validation {
    condition = alltrue([
      for b in var.ordered_cache_behavior : alltrue([
        for f in b.function_association :
        f.function_arn != null || f.function_name != null
      ])
    ])
    error_message = "Each function_association entry requires either function_arn or function_name."
  }
}

variable "create_monitoring_subscription" {
  description = "If enabled, the resource for monitoring subscription will created."
  type        = bool
  default     = false
}

variable "realtime_metrics_subscription_status" {
  description = "A flag that indicates whether additional CloudWatch metrics are enabled for a given CloudFront distribution. Valid values are `Enabled` and `Disabled`."
  type        = string
  default     = "Enabled"

  validation {
    condition     = contains(["Enabled", "Disabled"], var.realtime_metrics_subscription_status)
    error_message = "realtime_metrics_subscription_status must be one of: Enabled, Disabled."
  }
}

variable "create_vpc_origin" {
  description = "If enabled, the resource for VPC origin will be created."
  type        = bool
  default     = false
}

variable "vpc_origin" {
  description = "Map of CloudFront VPC origin"
  type = map(object({
    name                   = string
    arn                    = string
    http_port              = number
    https_port             = number
    origin_protocol_policy = string
    origin_ssl_protocols = object({
      items    = list(string)
      quantity = number
    })
  }))
  default = {}
}

variable "anycast_ip_list_id" {
  description = "ID of the Anycast static IP list to associate with the CloudFront distribution"
  type        = string
  default     = null
}

variable "viewer_mtls_config" {
  description = "Configuration for viewer mTLS authentication. Supports 'mode' (string) and 'trust_store_config' object with 'trust_store_id' (required), 'advertise_trust_store_ca_names' (bool), and 'ignore_certificate_expiry' (bool)."
  type        = any
  default     = null
}

variable "connection_function_association_id" {
  description = "ID of the CloudFront connection-level function to associate with the distribution (v6.28+)"
  type        = string
  default     = null
}

###################################################
# New inline resource variables
###################################################

variable "key_value_stores" {
  description = "Map of CloudFront Key-Value Stores to create. Map key is used as the store name. Supports: comment (string)."
  type        = any
  default     = {}
}

variable "functions" {
  description = "Map of CloudFront Functions to create. Map key is used as the function name. Required: runtime (string, e.g. 'cloudfront-js-2.0'), code (string, JS source). Optional: comment (string), publish (bool, default true), key_value_store_associations (list of KVS ARNs or inline KVS names)."
  type        = any
  default     = {}
}

variable "public_keys" {
  description = "Map of CloudFront Public Keys to create. Map key is used as the key name. Required: encoded_key (string, PEM-encoded public key). Optional: comment (string)."
  type        = any
  default     = {}
}

variable "key_groups" {
  description = "Map of CloudFront Key Groups to create. Map key is used as the group name. Required: items (list of public key IDs or inline public key names). Optional: comment (string)."
  type        = any
  default     = {}
}

variable "realtime_log_configs" {
  description = "Map of CloudFront Real-time Log Configs to create. Map key is used as the config name. Required: sampling_rate (number, 1-100), fields (list of strings), kinesis_stream_config (object with role_arn and stream_arn). Optional: stream_type (string, default 'Kinesis')."
  type        = any
  default     = {}
}

variable "continuous_deployment_policies" {
  description = "Map of CloudFront Continuous Deployment Policies to create. Map key is used as the policy identifier. Required: policy_enabled (bool). Optional: staging_distribution_dns_names (object with items and quantity), traffic_config (object with type and one of single_weight_config or single_header_config)."
  type        = any
  default     = {}
}
