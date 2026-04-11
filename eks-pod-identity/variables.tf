variable "enabled" {
  description = "Determines whether resources will be created (affects all resources)"
  type        = bool
  default     = true
}

variable "region" {
  description = "AWS region. If null, uses the provider's region."
  type        = string
  default     = null
}

variable "name" {
  description = "Name prefix used for IAM role and related resources"
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# IAM Role
################################################################################

variable "create_role" {
  description = "Whether to create the IAM role for pod identity"
  type        = bool
  default     = true
}

variable "role_name" {
  description = "Name of the IAM role. If null, uses `var.name`."
  type        = string
  default     = null
}

variable "role_path" {
  description = "Path for the IAM role"
  type        = string
  default     = "/"
}

variable "role_description" {
  description = "Description of the IAM role"
  type        = string
  default     = null
}

variable "role_permissions_boundary_arn" {
  description = "ARN of the permissions boundary policy to attach to the IAM role"
  type        = string
  default     = null
}

variable "role_max_session_duration" {
  description = "Maximum session duration (in seconds) for the IAM role. Value can be between 3600 and 43200."
  type        = number
  default     = 3600
}

variable "additional_trust_policy_statements" {
  description = "Additional IAM policy statements to add to the trust policy"
  type        = list(any)
  default     = []
}

################################################################################
# IAM Policies
################################################################################

variable "managed_policy_arns" {
  description = "List of IAM managed policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of inline policy names to policy JSON documents to attach to the role"
  type        = map(string)
  default     = {}
}

################################################################################
# Pod Identity Association
################################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "associations" {
  description = <<-EOT
    Map of pod identity associations to create. Each association maps a service account to the IAM role.
    Key is used as an identifier. Value object:
      - namespace       : Kubernetes namespace
      - service_account : Kubernetes service account name
  EOT
  type = map(object({
    namespace       = string
    service_account = string
  }))
  default = {}
}

variable "existing_role_arn" {
  description = "ARN of an existing IAM role to use instead of creating one. When set, `create_role` is ignored for the association."
  type        = string
  default     = null
}
