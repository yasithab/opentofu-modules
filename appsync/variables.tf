variable "enabled" {
  description = "Whether to create the AppSync resources."
  type        = bool
  default     = true
}


variable "name" {
  description = "Name of the AppSync GraphQL API."
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# GraphQL API
################################################################################

variable "authentication_type" {
  description = "Default authentication type. Valid values: `API_KEY`, `AWS_IAM`, `AMAZON_COGNITO_USER_POOLS`, `OPENID_CONNECT`, `AWS_LAMBDA`."
  type        = string
  default     = "API_KEY"

  validation {
    condition     = contains(["API_KEY", "AWS_IAM", "AMAZON_COGNITO_USER_POOLS", "OPENID_CONNECT", "AWS_LAMBDA"], var.authentication_type)
    error_message = "authentication_type must be one of: API_KEY, AWS_IAM, AMAZON_COGNITO_USER_POOLS, OPENID_CONNECT, AWS_LAMBDA."
  }
}

variable "schema" {
  description = "GraphQL schema definition string."
  type        = string
  default     = null
}

variable "xray_enabled" {
  description = "Whether X-Ray tracing is enabled."
  type        = bool
  default     = true
}

variable "introspection_config" {
  description = "Introspection configuration. Valid values: `ENABLED`, `DISABLED`."
  type        = string
  default     = "ENABLED"

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.introspection_config)
    error_message = "introspection_config must be one of: ENABLED, DISABLED."
  }
}

variable "query_depth_limit" {
  description = "Maximum depth of a query. Valid range: 1-75."
  type        = number
  default     = null

  validation {
    condition     = var.query_depth_limit == null || (var.query_depth_limit >= 1 && var.query_depth_limit <= 75)
    error_message = "query_depth_limit must be between 1 and 75."
  }
}

variable "resolver_count_limit" {
  description = "Maximum number of resolvers per query. Valid range: 1-10000."
  type        = number
  default     = null

  validation {
    condition     = var.resolver_count_limit == null || (var.resolver_count_limit >= 1 && var.resolver_count_limit <= 10000)
    error_message = "resolver_count_limit must be between 1 and 10000."
  }
}

variable "visibility" {
  description = "API visibility. Valid values: `GLOBAL`, `PRIVATE`."
  type        = string
  default     = "GLOBAL"

  validation {
    condition     = contains(["GLOBAL", "PRIVATE"], var.visibility)
    error_message = "visibility must be one of: GLOBAL, PRIVATE."
  }
}

################################################################################
# Authentication - Cognito
################################################################################

variable "user_pool_config" {
  description = "Cognito User Pool configuration for AMAZON_COGNITO_USER_POOLS authentication."
  type = object({
    user_pool_id        = string
    default_action      = optional(string, "DENY")
    app_id_client_regex = optional(string)
    aws_region          = optional(string)
  })
  default = null
}

################################################################################
# Authentication - OIDC
################################################################################

variable "openid_connect_config" {
  description = "OpenID Connect configuration for OPENID_CONNECT authentication."
  type = object({
    issuer    = string
    auth_ttl  = optional(number)
    client_id = optional(string)
    iat_ttl   = optional(number)
  })
  default = null
}

################################################################################
# Authentication - Lambda
################################################################################

variable "lambda_authorizer_config" {
  description = "Lambda authorizer configuration for AWS_LAMBDA authentication."
  type = object({
    authorizer_uri                   = string
    authorizer_result_ttl_in_seconds = optional(number, 300)
    identity_validation_expression   = optional(string)
  })
  default = null
}

################################################################################
# Additional Authentication Providers
################################################################################

variable "additional_authentication_providers" {
  description = "List of additional authentication provider configurations."
  type        = any
  default     = []
}

################################################################################
# API Keys
################################################################################

variable "api_keys" {
  description = "Map of API key configurations."
  type        = any
  default     = {}
}

################################################################################
# Data Sources
################################################################################

variable "datasources" {
  description = "Map of data source configurations. Supports DynamoDB, Lambda, HTTP, RDS, OpenSearch, EventBridge, and None types."
  type        = any
  default     = {}
}

################################################################################
# Functions
################################################################################

variable "functions" {
  description = "Map of AppSync function configurations for pipeline resolvers."
  type        = any
  default     = {}
}

################################################################################
# Resolvers
################################################################################

variable "resolvers" {
  description = "Map of resolver configurations. Supports unit and pipeline resolver kinds."
  type        = any
  default     = {}
}

################################################################################
# API Cache
################################################################################

variable "create_api_cache" {
  description = "Whether to create an API cache."
  type        = bool
  default     = false
}

variable "cache_api_caching_behavior" {
  description = "Caching behavior. Valid values: `FULL_REQUEST_CACHING`, `PER_RESOLVER_CACHING`."
  type        = string
  default     = "FULL_REQUEST_CACHING"

  validation {
    condition     = contains(["FULL_REQUEST_CACHING", "PER_RESOLVER_CACHING"], var.cache_api_caching_behavior)
    error_message = "cache_api_caching_behavior must be one of: FULL_REQUEST_CACHING, PER_RESOLVER_CACHING."
  }
}

variable "cache_type" {
  description = "Cache instance type. Valid values: `SMALL`, `MEDIUM`, `LARGE`, `XLARGE`, `LARGE_2X`, `LARGE_4X`, `LARGE_8X`, `LARGE_12X`, `T2_SMALL`, `T2_MEDIUM`, `R4_LARGE`, `R4_XLARGE`, `R4_2XLARGE`, `R4_4XLARGE`, `R4_8XLARGE`."
  type        = string
  default     = "SMALL"

  validation {
    condition     = contains(["SMALL", "MEDIUM", "LARGE", "XLARGE", "LARGE_2X", "LARGE_4X", "LARGE_8X", "LARGE_12X", "T2_SMALL", "T2_MEDIUM", "R4_LARGE", "R4_XLARGE", "R4_2XLARGE", "R4_4XLARGE", "R4_8XLARGE"], var.cache_type)
    error_message = "cache_type must be one of: SMALL, MEDIUM, LARGE, XLARGE, LARGE_2X, LARGE_4X, LARGE_8X, LARGE_12X, T2_SMALL, T2_MEDIUM, R4_LARGE, R4_XLARGE, R4_2XLARGE, R4_4XLARGE, R4_8XLARGE."
  }
}

variable "cache_ttl" {
  description = "TTL in seconds for cache entries."
  type        = number
  default     = 3600
}

variable "cache_transit_encryption_enabled" {
  description = "Whether transit encryption is enabled for the API cache."
  type        = bool
  default     = true
}

variable "cache_at_rest_encryption_enabled" {
  description = "Whether at-rest encryption is enabled for the API cache."
  type        = bool
  default     = true
}

################################################################################
# Domain Name
################################################################################

variable "create_domain_name" {
  description = "Whether to create a custom domain name for the API."
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Custom domain name for the AppSync API."
  type        = string
  default     = null
}

variable "domain_certificate_arn" {
  description = "ARN of the ACM certificate for the custom domain."
  type        = string
  default     = null

  validation {
    condition     = var.domain_certificate_arn == null || can(regex("^arn:", var.domain_certificate_arn))
    error_message = "domain_certificate_arn must be a valid ARN starting with 'arn:'."
  }
}

variable "domain_description" {
  description = "Description of the custom domain name."
  type        = string
  default     = null
}

################################################################################
# WAF
################################################################################

variable "waf_web_acl_arn" {
  description = "ARN of the WAFv2 Web ACL to associate with the GraphQL API."
  type        = string
  default     = null

  validation {
    condition     = var.waf_web_acl_arn == null || can(regex("^arn:", var.waf_web_acl_arn))
    error_message = "waf_web_acl_arn must be a valid ARN starting with 'arn:'."
  }
}

################################################################################
# Logging
################################################################################

variable "logging_enabled" {
  description = "Whether CloudWatch logging is enabled for the API."
  type        = bool
  default     = true
}

variable "create_logging_role" {
  description = "Whether to create an IAM role for CloudWatch logging."
  type        = bool
  default     = true
}

variable "logging_role_arn" {
  description = "ARN of an existing IAM role for CloudWatch logging. Used when `create_logging_role` is false."
  type        = string
  default     = null

  validation {
    condition     = var.logging_role_arn == null || can(regex("^arn:", var.logging_role_arn))
    error_message = "logging_role_arn must be a valid ARN starting with 'arn:'."
  }
}

variable "log_field_log_level" {
  description = "Field-level logging level. Valid values: `ALL`, `ERROR`, `NONE`."
  type        = string
  default     = "ERROR"

  validation {
    condition     = contains(["ALL", "ERROR", "NONE"], var.log_field_log_level)
    error_message = "log_field_log_level must be one of: ALL, ERROR, NONE."
  }
}

variable "log_exclude_verbose_content" {
  description = "Whether to exclude verbose content (headers, context, evaluated mapping templates) from logs."
  type        = bool
  default     = true
}
