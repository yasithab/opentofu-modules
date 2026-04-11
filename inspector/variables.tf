variable "enabled" {
  description = "Controls if Inspector and associated resources are created"
  type        = bool
  default     = true
}

variable "region" {
  description = "AWS region where Inspector resources will be created. If null, uses the provider default region"
  type        = string
  default     = null
}

variable "name" {
  description = "Name prefix for Inspector resources used in naming and tagging"
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all Inspector resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Inspector Enabler
################################################################################

variable "account_ids" {
  description = "List of AWS account IDs to enable Inspector for. Use the current account ID for single-account deployments"
  type        = list(string)
}

variable "resource_types" {
  description = "List of resource types to enable scanning for. Valid values: EC2, ECR, LAMBDA, LAMBDA_CODE"
  type        = list(string)
  default     = ["EC2", "ECR", "LAMBDA"]
}

################################################################################
# Delegated Admin
################################################################################

variable "delegated_admin_account_id" {
  description = "AWS account ID to designate as the delegated administrator for Inspector. Set to null to skip"
  type        = string
  default     = null
}

################################################################################
# Organization Configuration
################################################################################

variable "enable_organization_configuration" {
  description = "Whether to enable the organization-level Inspector configuration for auto-enabling scanning on new member accounts"
  type        = bool
  default     = false
}

variable "auto_enable_ec2" {
  description = "Whether to automatically enable EC2 scanning for new member accounts in the organization"
  type        = bool
  default     = true
}

variable "auto_enable_ecr" {
  description = "Whether to automatically enable ECR scanning for new member accounts in the organization"
  type        = bool
  default     = true
}

variable "auto_enable_lambda" {
  description = "Whether to automatically enable Lambda scanning for new member accounts in the organization"
  type        = bool
  default     = true
}

################################################################################
# Member Associations
################################################################################

variable "member_account_ids" {
  description = "List of AWS account IDs to associate as Inspector members"
  type        = list(string)
  default     = []
}

################################################################################
# Filters (Suppression Rules)
################################################################################

variable "filters" {
  description = "Map of Inspector filter (suppression rule) configurations. Each key is the filter name. Action must be NONE or SUPPRESS"
  type = map(object({
    action = string
    reason = optional(string)
    criteria = optional(object({
      aws_account_id = optional(list(object({
        comparison = string
        value      = string
      })), [])
      finding_type = optional(list(object({
        comparison = string
        value      = string
      })), [])
      severity = optional(list(object({
        comparison = string
        value      = string
      })), [])
      vulnerability_id = optional(list(object({
        comparison = string
        value      = string
      })), [])
      resource_type = optional(list(object({
        comparison = string
        value      = string
      })), [])
      ecr_image_repository_name = optional(list(object({
        comparison = string
        value      = string
      })), [])
      title = optional(list(object({
        comparison = string
        value      = string
      })), [])
    }), {})
  }))
  default = {}
}

