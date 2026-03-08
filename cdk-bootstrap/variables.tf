variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "region" {
  description = "The AWS region to bootstrap"
  type        = string
}

variable "cloudformation_execution_policy_arns" {
  description = "List of IAM policy ARNs to use as the CloudFormation execution policies for CDK bootstrap. Defaults to AdministratorAccess when not set."
  type        = list(string)
  default     = null
  nullable    = true
}

variable "trust_account_ids" {
  description = "List of AWS account IDs to trust for cross-account deployments (e.g. a central CI/CD account)."
  type        = list(string)
  default     = null
  nullable    = true
}

