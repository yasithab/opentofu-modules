
variable "enabled" {
  description = "Determines whether resources will be created (affects all resources)"
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
  description = "Map of AppConfig environments to create. Each entry supports `description` and `monitors` (list of objects with `alarm_arn` and optional `alarm_role_arn`)."
  type        = any
  default     = {}
}

################################################################################
# Configuration Profiles
################################################################################

variable "configuration_profiles" {
  description = "Map of configuration profiles to create. Each entry supports `description`, `type` (`AWS.Freeform` or `AWS.AppConfig.FeatureFlags`), `location_uri`, and `validators`."
  type        = any
  default     = {}
}

################################################################################
# Hosted Configuration Versions
################################################################################

variable "hosted_configuration_versions" {
  description = "Map of hosted configuration versions. Key must match a key in `configuration_profiles`. Each entry supports `content`, `content_type`, and `description`."
  type        = any
  default     = {}
}

################################################################################
# Deployment Strategy
################################################################################

variable "deployment_strategies" {
  description = "Map of deployment strategies to create. Each entry supports `deployment_duration_in_minutes`, `growth_factor`, `growth_type`, `replicate_to`, `final_bake_time_in_minutes`, and `description`."
  type        = any
  default     = {}
}

################################################################################
# Deployments
################################################################################

variable "deployments" {
  description = "Map of deployments to trigger. Each entry requires `environment_key` (key from `environments`), `configuration_profile_key` (key from `configuration_profiles`), `configuration_version_key` (key from `hosted_configuration_versions`), and `deployment_strategy_key` (key from `deployment_strategies`) or `deployment_strategy_id` for a predefined strategy."
  type        = any
  default     = {}
}

################################################################################
# Extensions
################################################################################

variable "extensions" {
  description = "Map of AppConfig extensions. Each entry supports `description`, `action_points` (map with `point_name` key and list of actions), and `parameters`."
  type        = any
  default     = {}
}

variable "extension_associations" {
  description = "Map of extension associations. Each entry requires `extension_key` (key from `extensions`) and `resource_type` (`environment` or `configuration_profile`) and `resource_key`."
  type        = any
  default     = {}
}
