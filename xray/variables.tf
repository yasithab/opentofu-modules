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
  description = "Name prefix used for identifying X-Ray resources."
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Encryption Configuration
################################################################################

variable "create_encryption_config" {
  description = "Determines whether to create an X-Ray encryption configuration. When enabled, traces are encrypted with the specified KMS key."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "ID or ARN of a KMS key used for encrypting X-Ray traces. When null, X-Ray uses its default encryption (NONE type)."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_id == null || can(regex("^(arn:aws[a-z-]*:kms:|[a-f0-9-]{36}$)", var.kms_key_id))
    error_message = "kms_key_id must be a valid KMS key ARN, key ID, or null."
  }
}

################################################################################
# Sampling Rules
################################################################################

variable "sampling_rules" {
  description = "Map of X-Ray sampling rule configurations. Each key is the rule name."
  type = map(object({
    priority       = number
    version        = optional(number, 1)
    reservoir_size = number
    fixed_rate     = number
    url_path       = optional(string, "*")
    host           = optional(string, "*")
    http_method    = optional(string, "*")
    service_type   = optional(string, "*")
    service_name   = optional(string, "*")
    resource_arn   = optional(string, "*")
    attributes     = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.sampling_rules : v.fixed_rate >= 0 && v.fixed_rate <= 1])
    error_message = "fixed_rate must be between 0 and 1 (inclusive)."
  }

  validation {
    condition     = alltrue([for k, v in var.sampling_rules : v.priority >= 1 && v.priority <= 9999])
    error_message = "priority must be between 1 and 9999."
  }
}

################################################################################
# Groups
################################################################################

variable "groups" {
  description = "Map of X-Ray group configurations. Each key is the group name, with a required filter_expression and optional insights configuration."
  type = map(object({
    filter_expression = string
    insights_configuration = optional(object({
      insights_enabled      = optional(bool, true)
      notifications_enabled = optional(bool, true)
    }))
  }))
  default = {}
}

################################################################################
# Resource Policies
################################################################################

variable "resource_policies" {
  description = "Map of X-Ray resource policy configurations. Each key is the policy name."
  type = map(object({
    policy_document             = string
    bypass_policy_lockout_check = optional(bool, false)
  }))
  default = {}
}

################################################################################
