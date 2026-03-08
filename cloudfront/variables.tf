
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
  description = "Controls if CloudFront distribution should be created"
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
  description = "One or more origins for this distribution (multiples allowed)."
  type        = any
  default     = null
}

variable "origin_group" {
  description = "One or more origin_group for this distribution (multiples allowed)."
  type        = any
  default     = {}
}

variable "viewer_certificate" {
  description = "The SSL configuration for this distribution"
  type        = any
  default = {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1"
  }
}

variable "geo_restriction" {
  description = "The restriction configuration for this distribution (geo_restrictions)"
  type        = any
  default     = {}
}

variable "logging_config" {
  description = "The logging configuration that controls how logs are written to your distribution (maximum one)."
  type        = any
  default     = {}
}

variable "custom_error_response" {
  description = "One or more custom error response elements"
  type        = any
  default     = {}
}

variable "default_cache_behavior" {
  description = "The default cache behavior for this distribution"
  type        = any
  default     = null
}

variable "ordered_cache_behavior" {
  description = "An ordered list of cache behaviors resource for this distribution. List from top to bottom in order of precedence. The topmost cache behavior will have precedence 0."
  type        = any
  default     = []
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
