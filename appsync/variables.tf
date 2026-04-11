variable "enabled" {
  description = "Whether to create the AppSync resources."
  type        = bool
  default     = true
}

variable "region" {
  description = "AWS region override. Uses provider region when null."
  type        = string
  default     = null
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
}

variable "query_depth_limit" {
  description = "Maximum depth of a query. Valid range: 1-75."
  type        = number
  default     = null
}

variable "resolver_count_limit" {
  description = "Maximum number of resolvers per query. Valid range: 1-10000."
  type        = number
  default     = null
}

variable "visibility" {
  description = "API visibility. Valid values: `GLOBAL`, `PRIVATE`."
  type        = string
  default     = "GLOBAL"
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
}

variable "cache_type" {
  description = "Cache instance type. Valid values: `SMALL`, `MEDIUM`, `LARGE`, `XLARGE`, `LARGE_2X`, `LARGE_4X`, `LARGE_8X`, `LARGE_12X`, `T2_SMALL`, `T2_MEDIUM`, `R4_LARGE`, `R4_XLARGE`, `R4_2XLARGE`, `R4_4XLARGE`, `R4_8XLARGE`."
  type        = string
  default     = "SMALL"
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
}

variable "log_field_log_level" {
  description = "Field-level logging level. Valid values: `ALL`, `ERROR`, `NONE`."
  type        = string
  default     = "ERROR"
}

variable "log_exclude_verbose_content" {
  description = "Whether to exclude verbose content (headers, context, evaluated mapping templates) from logs."
  type        = bool
  default     = true
}
