variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}


variable "name" {
  description = "The name of the IAM policy."
  type        = string

  validation {
    condition     = length(var.name) > 0
    error_message = "The name must not be empty."
  }
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "name_prefix" {
  description = "Creates a unique name beginning with the specified prefix. Conflicts with name."
  type        = string
  default     = null
}

variable "description" {
  description = "Description of the IAM policy."
  type        = string
  default     = null
}

variable "path" {
  description = "Path in which to create the policy. See IAM Identifiers for more information."
  type        = string
  default     = "/"

  validation {
    condition     = can(regex("^/", var.path))
    error_message = "The path must begin with '/'."
  }
}

variable "policy" {
  description = "The policy document JSON string. Provide exactly one of `policy` or `policy_documents`."
  type        = string
  default     = null

  validation {
    condition     = (var.policy != null) != (length(var.policy_documents) > 0)
    error_message = "Exactly one of `policy` or `policy_documents` must be provided (non-empty)."
  }
}

variable "policy_documents" {
  description = "List of JSON policy document strings to merge into a single policy. Provide exactly one of `policy` or `policy_documents`."
  type        = list(string)
  default     = []
}
