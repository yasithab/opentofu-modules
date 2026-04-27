variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}


variable "name" {
  description = "The name of the IAM group."
  type        = string

  validation {
    condition     = length(var.name) > 0
    error_message = "The name must not be empty."
  }
}

variable "path" {
  description = "Path in which to create the group."
  type        = string
  default     = "/"

  validation {
    condition     = can(regex("^/", var.path))
    error_message = "The path must begin with '/'."
  }
}

variable "managed_policy_arns" {
  description = "Set of managed policy ARNs to attach to the group."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for arn in var.managed_policy_arns : can(regex("^arn:", arn))])
    error_message = "Each managed_policy_arns entry must be a valid ARN starting with 'arn:'."
  }
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
