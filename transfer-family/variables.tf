variable "enabled" {
  description = "Whether to create the Transfer Family resources."
  type        = bool
  default     = true
}


variable "name" {
  description = "Name used as a prefix for all Transfer Family resources."
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
# Server
################################################################################

variable "protocols" {
  description = "List of file transfer protocols. Valid values: `SFTP`, `FTPS`, `FTP`, `AS2`."
  type        = list(string)
  default     = ["SFTP"]
}

variable "identity_provider_type" {
  description = "Identity provider type. Valid values: `SERVICE_MANAGED`, `API_GATEWAY`, `AWS_DIRECTORY_SERVICE`, `AWS_LAMBDA`."
  type        = string
  default     = "SERVICE_MANAGED"

  validation {
    condition     = contains(["SERVICE_MANAGED", "API_GATEWAY", "AWS_DIRECTORY_SERVICE", "AWS_LAMBDA"], var.identity_provider_type)
    error_message = "The identity_provider_type must be 'SERVICE_MANAGED', 'API_GATEWAY', 'AWS_DIRECTORY_SERVICE', or 'AWS_LAMBDA'."
  }
}

variable "endpoint_type" {
  description = "Endpoint type. Valid values: `PUBLIC`, `VPC`."
  type        = string
  default     = "PUBLIC"

  validation {
    condition     = contains(["PUBLIC", "VPC"], var.endpoint_type)
    error_message = "The endpoint_type must be 'PUBLIC' or 'VPC'."
  }
}

variable "domain" {
  description = "Storage domain. Valid values: `S3`, `EFS`."
  type        = string
  default     = "S3"

  validation {
    condition     = contains(["S3", "EFS"], var.domain)
    error_message = "The domain must be 'S3' or 'EFS'."
  }
}

variable "security_policy_name" {
  description = "Name of the security policy attached to the server. See AWS documentation for valid values."
  type        = string
  default     = "TransferSecurityPolicy-2024-01"
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for FTPS protocol."
  type        = string
  default     = null

  validation {
    condition     = var.certificate_arn == null || can(regex("^arn:", var.certificate_arn))
    error_message = "The certificate_arn must be a valid ARN starting with 'arn:'."
  }
}

variable "host_key" {
  description = "RSA, ECDSA, or ED25519 private key for the server."
  type        = string
  default     = null
  sensitive   = true
}

variable "force_destroy" {
  description = "Whether to force-destroy the server even if it contains users."
  type        = bool
  default     = false
}

variable "pre_authentication_login_banner" {
  description = "Banner message displayed before authentication."
  type        = string
  default     = null
}

variable "post_authentication_display_banner" {
  description = "Banner message displayed after authentication."
  type        = string
  default     = null
}

################################################################################
# Identity Provider
################################################################################

variable "identity_provider_function_arn" {
  description = "ARN of the Lambda function for custom identity provider (AWS_LAMBDA type)."
  type        = string
  default     = null

  validation {
    condition     = var.identity_provider_function_arn == null || can(regex("^arn:", var.identity_provider_function_arn))
    error_message = "The identity_provider_function_arn must be a valid ARN starting with 'arn:'."
  }
}

variable "identity_provider_url" {
  description = "URL of the API Gateway for custom identity provider (API_GATEWAY type)."
  type        = string
  default     = null
}

variable "identity_provider_invocation_role_arn" {
  description = "IAM role ARN for invoking the API Gateway identity provider."
  type        = string
  default     = null

  validation {
    condition     = var.identity_provider_invocation_role_arn == null || can(regex("^arn:", var.identity_provider_invocation_role_arn))
    error_message = "The identity_provider_invocation_role_arn must be a valid ARN starting with 'arn:'."
  }
}

variable "directory_id" {
  description = "Directory ID for AWS Directory Service identity provider."
  type        = string
  default     = null
}

################################################################################
# VPC Endpoint
################################################################################

variable "vpc_id" {
  description = "VPC ID for VPC endpoint type. Required when `endpoint_type` is `VPC`."
  type        = string
  default     = null

  validation {
    condition     = var.vpc_id == null || can(regex("^vpc-", var.vpc_id))
    error_message = "The vpc_id must start with 'vpc-'."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs for VPC endpoint."
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "List of security group IDs for VPC endpoint."
  type        = list(string)
  default     = []
}

variable "address_allocation_ids" {
  description = "List of Elastic IP allocation IDs for VPC endpoint."
  type        = list(string)
  default     = []
}

################################################################################
# Protocol Details
################################################################################

variable "protocol_details" {
  description = "Protocol-specific settings including passive IP, SetStat option, TLS session resumption, and AS2 transports."
  type        = any
  default     = null
}

################################################################################
# S3 Storage Options
################################################################################

variable "s3_storage_options" {
  description = "S3 storage options including directory listing optimization."
  type        = any
  default     = null
}

################################################################################
# Workflow
################################################################################

variable "workflow_on_upload" {
  description = "Workflow configuration triggered on file upload."
  type = object({
    execution_role = string
    workflow_id    = string
  })
  default = null
}

variable "workflow_on_partial_upload" {
  description = "Workflow configuration triggered on partial file upload."
  type = object({
    execution_role = string
    workflow_id    = string
  })
  default = null
}

variable "workflows" {
  description = "Map of workflow configurations with steps and exception handling."
  type        = any
  default     = {}
}

################################################################################
# Users
################################################################################

variable "users" {
  description = "Map of Transfer Family user configurations including home directory, policy, and SSH keys."
  type        = any
  default     = {}
}

################################################################################
# Logging
################################################################################

variable "create_logging_role" {
  description = "Whether to create an IAM role for CloudWatch logging."
  type        = bool
  default     = true
}

variable "logging_role_arn" {
  description = "ARN of an existing IAM role for CloudWatch logging. Used when `create_logging_role` is false."
  type        = string
  default     = null

  validation {
    condition     = var.logging_role_arn == null || can(regex("^arn:", var.logging_role_arn))
    error_message = "The logging_role_arn must be a valid ARN starting with 'arn:'."
  }
}

variable "structured_log_destinations" {
  description = "List of CloudWatch Log Group ARNs for structured JSON logging."
  type        = list(string)
  default     = []
}

################################################################################
# Route53
################################################################################

variable "route53_records" {
  description = "Map of Route53 record configurations for custom hostnames."
  type        = any
  default     = {}
}
