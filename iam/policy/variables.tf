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
  description = "The name of the IAM policy."
  type        = string
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
}

variable "policy" {
  description = "The policy document JSON string. Provide this or use policy_documents to merge multiple statements."
  type        = string
  default     = null
}

variable "policy_documents" {
  description = "List of JSON policy document strings to merge into a single policy. Ignored if policy is set."
  type        = list(string)
  default     = []
}
