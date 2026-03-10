###################################################
# Standard Module Variables
###################################################

variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name of the Web ACL and prefix for related resources. Required."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to all resources."
  type        = map(string)
  default     = {}
}

###################################################
# Web ACL Core Settings
###################################################

variable "description" {
  description = "A friendly description of the Web ACL."
  type        = string
  default     = null
}

variable "scope" {
  description = "Specifies whether the Web ACL is for an AWS CloudFront distribution (CLOUDFRONT) or for a regional application (REGIONAL). CLOUDFRONT scope must be created in us-east-1."
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "scope must be REGIONAL or CLOUDFRONT."
  }
}

variable "token_domains" {
  description = "List of domains to accept in web requests that contain a CAPTCHA or challenge token."
  type        = list(string)
  default     = []
}

###################################################
# Default Action
###################################################

variable "default_action" {
  description = "Action to take on requests that don't match any rules. ALLOW or BLOCK."
  type        = string
  default     = "ALLOW"

  validation {
    condition     = contains(["ALLOW", "BLOCK"], upper(var.default_action))
    error_message = "default_action must be ALLOW or BLOCK."
  }
}

variable "default_action_config" {
  description = <<-EOT
    Optional configuration for the default action. Use when you want custom headers on
    ALLOW or custom response on BLOCK.

    For ALLOW with custom headers:
      { allow = { insert_headers = [{ name = "x-allowed", value = "true" }] } }

    For BLOCK with custom response:
      { block = { response_code = 403, custom_response_body_key = "restricted" } }
  EOT
  type        = any
  default     = null
}

###################################################
# Custom Response Bodies
###################################################

variable "custom_response_bodies" {
  description = <<-EOT
    List of custom response body definitions that can be referenced by name in block rules.
    Each entry: { key = string, content = string, content_type = string }
    content_type: TEXT_PLAIN, TEXT_HTML, or APPLICATION_JSON
  EOT
  type = list(object({
    key          = string
    content      = string
    content_type = string
  }))
  default = []
}

###################################################
# Visibility Config
###################################################

variable "visibility_config" {
  description = <<-EOT
    Visibility configuration for the Web ACL. Also used as the default for rules that
    do not specify their own visibility_config.
    Defaults: cloudwatch_metrics_enabled=true, metric_name=var.name, sampled_requests_enabled=true.
  EOT
  type = object({
    cloudwatch_metrics_enabled = bool
    metric_name                = string
    sampled_requests_enabled   = bool
  })
  default = {
    cloudwatch_metrics_enabled = true
    metric_name                = null
    sampled_requests_enabled   = true
  }
}

###################################################
# Rules
###################################################

variable "rules" {
  description = <<-EOT
    List of WAFv2 rule objects. Only used when rule_json is null.
    Each rule requires: name, priority, statement, and either action or override_action.
    See README for full rule structure reference.
  EOT
  type        = any
  default     = []
}

variable "rule_json" {
  description = <<-EOT
    Raw JSON string of WAFv2 rules to apply to the Web ACL. When set, takes precedence
    over the structured rules variable and rule_json is passed directly to the provider.
    Use this for complex rules that exceed the structured variable schema (e.g., deeply
    nested and/or/not statements).
  EOT
  type        = string
  default     = null
}

###################################################
# Advanced Web ACL Settings
###################################################

variable "association_config" {
  description = <<-EOT
    Configuration for resource type-specific request body inspection size limits.
    Structure:
      {
        request_body = {
          api_gateway              = { default_size_inspection_limit = "KB_16" }
          app_runner_service       = { default_size_inspection_limit = "KB_16" }
          cloudfront               = { default_size_inspection_limit = "KB_16" }
          cognito_user_pool        = { default_size_inspection_limit = "KB_16" }
          verified_access_instance = { default_size_inspection_limit = "KB_16" }
        }
      }
    Valid values for default_size_inspection_limit: KB_16, KB_32, KB_48, KB_64
  EOT
  type        = any
  default     = null
}

variable "captcha_config" {
  description = "Specifies how AWS WAF should handle CAPTCHA evaluations at the Web ACL level. Sets the immunity time in seconds."
  type = object({
    immunity_time = number
  })
  default = null
}

variable "challenge_config" {
  description = "Specifies how AWS WAF should handle challenge evaluations at the Web ACL level. Sets the immunity time in seconds."
  type = object({
    immunity_time = number
  })
  default = null
}

variable "data_protection_config" {
  description = <<-EOT
    Configuration for data protection applied before logging WAF request data.
    Structure:
      {
        data_protection = [
          {
            action                     = "HASH"   # HASH or SUBSTITUTION
            exclude_rate_based_details = optional(bool)
            exclude_rule_match_details = optional(bool)
            fields = [
              {
                field_type = "QUERY_STRING"  # QUERY_STRING, SINGLE_HEADER, URI_PATH, etc.
                field_keys = optional(list(string))  # For SINGLE_HEADER: list of header names
              }
            ]
          }
        ]
      }
  EOT
  type        = any
  default     = null
}

###################################################
# Helper Resources
###################################################

variable "ip_sets" {
  description = <<-EOT
    Map of IP sets to create. Map key becomes the IP set name.
    Each value: {
      addresses          = list(string)   # CIDR notation
      ip_address_version = string         # IPV4 or IPV6
      description        = optional(string)
    }
    Created IP sets can be referenced by name in rules using ip_set_reference_statement.name.
  EOT
  type = map(object({
    addresses          = list(string)
    ip_address_version = string
    description        = optional(string)
  }))
  default = {}
}

variable "regex_pattern_sets" {
  description = <<-EOT
    Map of regex pattern sets to create. Map key becomes the regex pattern set name.
    Each value: {
      regular_expressions = list(string)
      description         = optional(string)
    }
    Created sets can be referenced by name in rules using regex_pattern_set_reference_statement.name.
  EOT
  type = map(object({
    regular_expressions = list(string)
    description         = optional(string)
  }))
  default = {}
}

variable "rule_groups" {
  description = <<-EOT
    Map of rule groups to create. Map key becomes the rule group name.
    Each value: {
      capacity    = number              # WCU capacity
      description = optional(string)
      rules_json  = optional(string)    # Raw JSON; takes precedence over rules
      rules       = optional(any)       # Structured rules list (common statement types)
      cloudwatch_metrics_enabled = optional(bool)
      metric_name                = optional(string)
      sampled_requests_enabled   = optional(bool)
      custom_response_bodies     = optional(list({ key=string, content=string, content_type=string }))
    }
    Created rule groups can be referenced by name in rules using rule_group_reference_statement.name.
  EOT
  type = map(object({
    capacity                   = number
    description                = optional(string)
    rules_json                 = optional(string)
    rules                      = optional(any)
    cloudwatch_metrics_enabled = optional(bool)
    metric_name                = optional(string)
    sampled_requests_enabled   = optional(bool)
    custom_response_bodies = optional(list(object({
      key          = string
      content      = string
      content_type = string
    })))
  }))
  default = {}
}

variable "api_keys" {
  description = <<-EOT
    Map of API keys to create for application integration (CAPTCHA/Challenge JavaScript API).
    Map key is a descriptive name. Each value: { token_domains = list(string) }
  EOT
  type = map(object({
    token_domains = list(string)
  }))
  default = {}
}

###################################################
# Associations
###################################################

variable "associations" {
  description = <<-EOT
    Map of resources to associate with the Web ACL. Map key is a descriptive name,
    map value is the resource ARN.
    Supported resource types: ALB, API Gateway Stage, AppSync GraphQL API,
    App Runner Service, Cognito User Pool, Verified Access Instance.
    Note: CloudFront distributions are associated via the distribution's web_acl_id attribute.
  EOT
  type        = map(string)
  default     = {}
}

variable "rule_group_associations" {
  description = <<-EOT
    Map of rule group associations to the Web ACL. Map key is a descriptive name.
    When this is non-empty, the rule attribute of the Web ACL is added to lifecycle
    ignore_changes to avoid conflicts between inline rules and associated groups.
    Each value: {
      priority = number
      rule_group_reference = optional({
        arn  = optional(string)   # Use ARN for external rule groups
        name = optional(string)   # Use name for rule groups created by this module
        rule_action_overrides = optional(list({ name=string, action_to_use=string }))
      })
      managed_rule_group = optional({
        name        = string
        vendor_name = string   # Defaults to "AWS"
        version     = optional(string)
        rule_action_overrides = optional(list({ name=string, action_to_use=string }))
      })
      override_action   = optional(string)   # "none" or "count"
      visibility_config = optional({
        cloudwatch_metrics_enabled = bool
        metric_name                = string
        sampled_requests_enabled   = bool
      })
    }
  EOT
  type        = any
  default     = {}
}

###################################################
# Logging
###################################################

variable "logging_destination_arns" {
  description = <<-EOT
    List of ARNs of logging destinations. Supported: CloudWatch Logs log group,
    Kinesis Data Firehose delivery stream, S3 bucket.
    Names must start with aws-waf-logs-.
    When empty, no logging configuration is created.
  EOT
  type        = list(string)
  default     = []
}

variable "logging_filter" {
  description = <<-EOT
    Logging filter configuration to selectively log requests. When null, all requests are logged.
    Structure:
      {
        default_behavior = "KEEP" or "DROP"
        filters = [
          {
            behavior    = "KEEP" or "DROP"
            requirement = "MEETS_ANY" or "MEETS_ALL"  # default MEETS_ANY
            conditions  = [
              {
                action_condition     = { action = "ALLOW" | "BLOCK" | "COUNT" | "CAPTCHA" | "CHALLENGE" | "EXCLUDED_AS_COUNT" }
                label_name_condition = { label_name = "..." }
              }
            ]
          }
        ]
      }
  EOT
  type        = any
  default     = null
}

variable "logging_redacted_fields" {
  description = <<-EOT
    List of fields to redact from logs. Each entry specifies which field to redact:
      { uri_path = {} }
      { query_string = {} }
      { method = {} }
      { single_header = { name = "authorization" } }
  EOT
  type        = any
  default     = []
}
