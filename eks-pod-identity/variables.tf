variable "enabled" {
  description = "Determines whether resources will be created (affects all resources)"
  type        = bool
  default     = true
}


variable "name" {
  description = "Name prefix used for IAM role and related resources"
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

  validation {
    condition     = can(regex("^/", var.role_path))
    error_message = "The role_path must begin with '/'."
  }
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

  validation {
    condition     = var.role_permissions_boundary_arn == null || can(regex("^arn:", var.role_permissions_boundary_arn))
    error_message = "The role_permissions_boundary_arn must be null or a valid ARN starting with 'arn:'."
  }
}

variable "role_max_session_duration" {
  description = "Maximum session duration (in seconds) for the IAM role. Value can be between 3600 and 43200."
  type        = number
  default     = 3600

  validation {
    condition     = var.role_max_session_duration >= 3600 && var.role_max_session_duration <= 43200
    error_message = "The role_max_session_duration must be between 3600 and 43200 seconds."
  }
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

  validation {
    condition     = alltrue([for arn in var.managed_policy_arns : can(regex("^arn:", arn))])
    error_message = "Each managed_policy_arns entry must be a valid ARN starting with 'arn:'."
  }
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

  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "The cluster_name must not be empty."
  }
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

  validation {
    condition     = var.existing_role_arn == null || can(regex("^arn:", var.existing_role_arn))
    error_message = "The existing_role_arn must be null or a valid ARN starting with 'arn:'."
  }
}
