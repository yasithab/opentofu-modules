variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "region" {
  description = "AWS region. If specified, overrides the provider's default region."
  type        = string
  default     = null
}

variable "name" {
  description = "The name of the IAM group."
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "path" {
  description = "Path in which to create the group."
  type        = string
  default     = "/"
}

variable "managed_policy_arns" {
  description = "Set of managed policy ARNs to attach to the group."
  type        = set(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of inline policy names to their JSON policy documents."
  type        = map(string)
  default     = {}
}

variable "users" {
  description = "Set of IAM user names to add as members of the group."
  type        = set(string)
  default     = []
}
