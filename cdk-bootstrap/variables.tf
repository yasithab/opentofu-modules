variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "qualifier" {
  description = "The CDK bootstrap qualifier. This is used to namespace bootstrap resources."
  type        = string
  default     = "hnb659fds"

  validation {
    condition     = can(regex("^[a-z0-9]{1,10}$", var.qualifier))
    error_message = "Qualifier must be 1-10 lowercase alphanumeric characters."
  }
}

variable "region" {
  description = "AWS region override. When null, uses the current provider region."
  type        = string
  default     = null

  validation {
    condition     = var.region == null || can(regex("^[a-z]{2}(-[a-z]+-[0-9]+)+$", var.region))
    error_message = "region must be a valid AWS region identifier (e.g. us-east-1, eu-west-1)."
  }
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "force_destroy" {
  description = "Allow destruction of the S3 bucket and ECR repository even when they contain objects/images."
  type        = bool
  default     = false
}

variable "create_kms_key" {
  description = "Create a dedicated KMS key for S3 and ECR encryption. When false, uses default SSE (AES256)."
  type        = bool
  default     = false
}

variable "kms_key_deletion_window" {
  description = "Number of days before the KMS key is permanently deleted after destruction."
  type        = number
  default     = 30

  validation {
    condition     = var.kms_key_deletion_window >= 7 && var.kms_key_deletion_window <= 30
    error_message = "KMS key deletion window must be between 7 and 30 days."
  }
}

variable "cloudformation_execution_policy_arns" {
  description = "List of IAM policy ARNs for the CloudFormation execution role. Defaults to AdministratorAccess."
  type        = list(string)
  default     = null
  nullable    = true
}

variable "trust_account_ids" {
  description = "AWS account IDs trusted for cross-account CDK deployments (deploy, file publishing, image publishing roles)."
  type        = list(string)
  default     = []
}

variable "trust_account_ids_for_lookup" {
  description = "Additional AWS account IDs trusted for the lookup role only (read-only context lookups)."
  type        = list(string)
  default     = []
}

variable "bootstrap_version" {
  description = "CDK bootstrap template version number stored in SSM."
  type        = number
  default     = 32
}
