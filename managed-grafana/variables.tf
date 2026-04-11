variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "region" {
  description = "Region where resources will be managed. Defaults to the Region set in the provider configuration."
  type        = string
  default     = null
}

variable "name" {
  description = "Name of the Amazon Managed Grafana workspace."
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Workspace
################################################################################

variable "workspace_description" {
  description = "Description of the Grafana workspace."
  type        = string
  default     = null
}

variable "account_access_type" {
  description = "Type of account access for the workspace. Valid values are CURRENT_ACCOUNT and ORGANIZATION."
  type        = string
  default     = "CURRENT_ACCOUNT"

  validation {
    condition     = contains(["CURRENT_ACCOUNT", "ORGANIZATION"], var.account_access_type)
    error_message = "account_access_type must be CURRENT_ACCOUNT or ORGANIZATION."
  }
}

variable "authentication_providers" {
  description = "List of authentication providers for the workspace. Valid values are AWS_SSO and SAML."
  type        = list(string)
  default     = ["AWS_SSO"]

  validation {
    condition     = alltrue([for p in var.authentication_providers : contains(["AWS_SSO", "SAML"], p)])
    error_message = "authentication_providers must contain only AWS_SSO and/or SAML."
  }
}

variable "permission_type" {
  description = "Permission type for the workspace. Valid values are SERVICE_MANAGED and CUSTOMER_MANAGED."
  type        = string
  default     = "SERVICE_MANAGED"

  validation {
    condition     = contains(["SERVICE_MANAGED", "CUSTOMER_MANAGED"], var.permission_type)
    error_message = "permission_type must be SERVICE_MANAGED or CUSTOMER_MANAGED."
  }
}

variable "grafana_version" {
  description = "Version of Grafana to deploy. Defaults to the latest version available."
  type        = string
  default     = null
}

variable "data_sources" {
  description = "List of data sources for the workspace. Valid values include CLOUDWATCH, PROMETHEUS, XRAY, TIMESTREAM, SITEWISE, ATHENA, REDSHIFT."
  type        = list(string)
  default     = ["CLOUDWATCH", "PROMETHEUS", "XRAY"]
}

variable "notification_destinations" {
  description = "List of notification destinations. Valid values are SNS."
  type        = list(string)
  default     = ["SNS"]
}

variable "organizational_units" {
  description = "List of AWS Organizations organizational unit IDs."
  type        = list(string)
  default     = []
}

variable "organization_role_name" {
  description = "Role name used to access resources through AWS Organizations."
  type        = string
  default     = null
}

variable "stack_set_name" {
  description = "Name of the AWS CloudFormation stack set used to generate IAM roles for the workspace."
  type        = string
  default     = null
}

variable "workspace_configuration" {
  description = "Configuration for the workspace as a map (will be JSON-encoded). Supports plugins, unifiedAlerting, etc."
  type        = any
  default     = null
}

################################################################################
# VPC Configuration
################################################################################

variable "vpc_configuration" {
  description = "VPC configuration for the workspace for private access. Provide security_group_ids and subnet_ids."
  type = object({
    security_group_ids = list(string)
    subnet_ids         = list(string)
  })
  default = null
}

variable "network_access_control" {
  description = "Network access control configuration. Provide prefix_list_ids and vpce_ids."
  type = object({
    prefix_list_ids = list(string)
    vpce_ids        = list(string)
  })
  default = null
}

################################################################################
# License
################################################################################

variable "license_type" {
  description = "License type for the workspace. Valid values are ENTERPRISE and ENTERPRISE_FREE_TRIAL."
  type        = string
  default     = "ENTERPRISE_FREE_TRIAL"

  validation {
    condition     = contains(["ENTERPRISE", "ENTERPRISE_FREE_TRIAL"], var.license_type)
    error_message = "license_type must be ENTERPRISE or ENTERPRISE_FREE_TRIAL."
  }
}

################################################################################
# SAML Configuration
################################################################################

variable "enable_saml_configuration" {
  description = "Determines whether SAML configuration is created for the workspace."
  type        = bool
  default     = false
}

variable "saml_editor_role_values" {
  description = "List of SAML attribute values to match for the editor role."
  type        = list(string)
  default     = []
}

variable "saml_admin_role_values" {
  description = "List of SAML attribute values to match for the admin role."
  type        = list(string)
  default     = []
}

variable "saml_idp_metadata_url" {
  description = "URL for the SAML identity provider metadata."
  type        = string
  default     = null
}

variable "saml_idp_metadata_xml" {
  description = "XML metadata for the SAML identity provider. Used when a URL is not available."
  type        = string
  default     = null
}

variable "saml_login_assertion" {
  description = "SAML login assertion attribute mapping configuration."
  type = object({
    email  = optional(string)
    groups = optional(string)
    login  = optional(string)
    name   = optional(string)
    org    = optional(string)
    role   = optional(string)
  })
  default = null
}

################################################################################
# API Keys
################################################################################

variable "api_keys" {
  description = "Map of API key configurations. Each key name maps to a configuration with key_role and seconds_to_live."
  type = map(object({
    key_role        = string
    seconds_to_live = number
  }))
  default = {}
}

################################################################################
# IAM Role
################################################################################

variable "create_iam_role" {
  description = "Determines whether an IAM role is created for the Grafana workspace."
  type        = bool
  default     = true
}

variable "iam_role_arn" {
  description = "ARN of an existing IAM role to use when create_iam_role is false."
  type        = string
  default     = null
}

variable "iam_role_name" {
  description = "Name of the IAM role. Defaults to grafana-{name}."
  type        = string
  default     = null
}

variable "iam_role_use_name_prefix" {
  description = "Determines whether to use the IAM role name as a prefix."
  type        = bool
  default     = false
}

variable "iam_role_path" {
  description = "Path for the IAM role."
  type        = string
  default     = "/"
}

variable "iam_role_inline_policies" {
  description = "Map of inline policy names to policy JSON documents to attach to the IAM role."
  type        = map(string)
  default     = {}
}

variable "iam_role_policy_arns" {
  description = "Map of IAM policy ARNs to attach to the IAM role."
  type        = map(string)
  default     = {}
}

################################################################################
# SNS
################################################################################

variable "sns_topic_arns" {
  description = "List of SNS topic ARNs that Grafana is allowed to publish notifications to."
  type        = list(string)
  default     = []
}

################################################################################
