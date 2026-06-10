variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
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
  type = map(object({
    user_name           = string
    role                = string
    home_directory      = optional(string)
    home_directory_type = optional(string)
    policy              = optional(string)
    home_directory_mappings = optional(list(object({
      entry  = string
      target = string
    })), [])
    posix_profile = optional(object({
      gid            = number
      uid            = number
      secondary_gids = optional(list(number))
    }))
    ssh_public_key = optional(string)
  }))
  default = {}
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

################################################################################
# SFTP Connectors
################################################################################

variable "connectors" {
  description = "Map of outbound SFTP connectors used to transfer files to remote SFTP servers. `url` is the remote endpoint (sftp://...), `access_role` is the IAM role the connector assumes, `user_secret_id` is the Secrets Manager secret holding the SFTP credentials, and `trusted_host_keys` pins the remote server's public host keys."
  type = map(object({
    url                  = string
    access_role          = string
    logging_role         = optional(string)
    security_policy_name = optional(string)
    trusted_host_keys    = optional(list(string))
    user_secret_id       = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for v in values(var.connectors) : can(regex("^arn:", v.access_role))])
    error_message = "Each connector access_role must be a valid IAM role ARN starting with 'arn:'."
  }
}
