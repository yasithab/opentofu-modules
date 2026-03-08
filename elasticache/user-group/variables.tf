variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "region" {
  description = "Region where the resource(s) will be managed. Defaults to the region set in the provider configuration"
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Group
################################################################################

variable "create_group" {
  description = "Determines whether a user group will be created"
  type        = bool
  default     = true
}

variable "engine" {
  description = "The current supported value is `REDIS`"
  type        = string
  default     = "REDIS"
}

variable "user_group_id" {
  description = "The ID of the user group"
  type        = string
  default     = null
}

################################################################################
# User(s)
################################################################################

variable "users" {
  description = "A map of users to create"
  type        = any
  default     = {}
}

variable "create_default_user" {
  description = "Determines whether a default user will be created"
  type        = bool
  default     = true
}

variable "default_user" {
  description = "A map of default user attributes"
  type        = any
  default     = {}
}

variable "default_user_id" {
  description = "The ID of the default user"
  type        = string
  default     = "default"
}
