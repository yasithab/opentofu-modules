
variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}


variable "name" {
  description = "Name of the AppConfig application"
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 64
    error_message = "Name must be between 1 and 64 characters."
  }
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Application
################################################################################

variable "application_description" {
  description = "Description of the AppConfig application"
  type        = string
  default     = null
}

################################################################################
# Environments
################################################################################

variable "environments" {
  description = "Map of AppConfig environments to create. Each entry supports `name` (defaults to the map key), `description`, and `monitors` (list of objects with `alarm_arn` and optional `alarm_role_arn`)."
  type = map(object({
    name        = optional(string)
    description = optional(string)
    monitors = optional(list(object({
      alarm_arn      = string
      alarm_role_arn = optional(string)
    })), [])
  }))
  default = {}
}

################################################################################
# Configuration Profiles
################################################################################

variable "configuration_profiles" {
  description = "Map of configuration profiles to create. Each entry supports `name` (defaults to the map key), `description`, `type` (`AWS.Freeform` or `AWS.AppConfig.FeatureFlags`), `location_uri`, and `validators` (list of objects with `type` and optional `content`)."
  type = map(object({
    name         = optional(string)
    description  = optional(string)
    type         = optional(string, "AWS.Freeform")
    location_uri = optional(string, "hosted")
    validators = optional(list(object({
      type    = string
      content = optional(string)
    })), [])
  }))
  default = {}
}

################################################################################
# Hosted Configuration Versions
################################################################################

variable "hosted_configuration_versions" {
  description = "Map of hosted configuration versions. Key must match a key in `configuration_profiles`. Each entry supports `content`, `content_type`, and `description`. Do NOT put secrets in `content` — hosted configuration content is stored in OpenTofu state and in AppConfig; use SSM SecureString / Secrets Manager references instead."
  type = map(object({
    content      = string
    content_type = optional(string, "application/json")
    description  = optional(string)
  }))
  default   = {}
  sensitive = true
}

################################################################################
# Deployment Strategy
################################################################################

variable "deployment_strategies" {
  description = "Map of deployment strategies to create. Each entry supports `name` (defaults to the map key), `description`, `deployment_duration_in_minutes`, `growth_factor`, `growth_type`, `replicate_to`, and `final_bake_time_in_minutes`."
  type = map(object({
    name                           = optional(string)
    description                    = optional(string)
    deployment_duration_in_minutes = number
    growth_factor                  = number
    growth_type                    = optional(string, "LINEAR")
    replicate_to                   = optional(string, "NONE")
    final_bake_time_in_minutes     = optional(number, 0)
  }))
  default = {}
}

################################################################################
# Deployments
################################################################################

variable "deployments" {
  description = "Map of deployments to trigger. Each entry requires `environment_key` (key from `environments`), `configuration_profile_key` (key from `configuration_profiles`), `configuration_version_key` (key from `hosted_configuration_versions`), and `deployment_strategy_key` (key from `deployment_strategies`) or `deployment_strategy_id` for a predefined strategy. Optional `kms_key_identifier` (KMS key ID, alias, or ARN) encrypts the configuration data at rest."
  type = map(object({
    environment_key           = string
    configuration_profile_key = string
    configuration_version_key = string
    deployment_strategy_key   = optional(string)
    deployment_strategy_id    = optional(string)
    description               = optional(string)
    kms_key_identifier        = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for d in values(var.deployments) : d.deployment_strategy_key != null || d.deployment_strategy_id != null])
    error_message = "Each deployment must set either deployment_strategy_key or deployment_strategy_id."
  }
}

################################################################################
# Extensions
################################################################################

variable "extensions" {
  description = "Map of AppConfig extensions. Each entry supports `name` (defaults to the map key), `description`, `action_points` (map keyed by action point name, each a list of actions with `name`, `uri`, and optional `role_arn`), and `parameters` (map keyed by parameter name with optional `required` and `description`)."
  type = map(object({
    name        = optional(string)
    description = optional(string)
    action_points = optional(map(list(object({
      name     = string
      uri      = string
      role_arn = optional(string)
    }))), {})
    parameters = optional(map(object({
      required    = optional(bool, false)
      description = optional(string)
    })), {})
  }))
  default = {}
}

variable "extension_associations" {
  description = "Map of extension associations. Each entry requires `extension_key` (key from `extensions`) and either `resource_type` (`environment` or `configuration_profile`) with `resource_key`, or a literal `resource_arn`."
  type = map(object({
    extension_key = string
    resource_type = optional(string)
    resource_key  = optional(string)
    resource_arn  = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for a in values(var.extension_associations) :
      contains(["environment", "configuration_profile"], coalesce(a.resource_type, "none")) ? a.resource_key != null : a.resource_arn != null
    ])
    error_message = "Each extension association must set resource_type ('environment' or 'configuration_profile') with resource_key, or provide resource_arn."
  }
}
