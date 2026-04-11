variable "enabled" {
  description = "Controls if EMR Serverless application and associated resources are created"
  type        = bool
  default     = true
}

variable "region" {
  description = "AWS region override. If not specified, the provider default region is used"
  type        = string
  default     = null
}

variable "name" {
  description = "Name of the EMR Serverless application"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Application Configuration
################################################################################

variable "release_label" {
  description = "EMR release label (e.g., 'emr-7.1.0')"
  type        = string
  default     = "emr-7.1.0"
}

variable "application_type" {
  description = "Type of EMR Serverless application. Valid values: Spark, Hive"
  type        = string
  default     = "Spark"

  validation {
    condition     = contains(["Spark", "Hive"], var.application_type)
    error_message = "application_type must be either Spark or Hive."
  }
}

variable "architecture" {
  description = "CPU architecture for the application. Valid values: ARM64, X86_64"
  type        = string
  default     = "X86_64"

  validation {
    condition     = contains(["ARM64", "X86_64"], var.architecture)
    error_message = "architecture must be ARM64 or X86_64."
  }
}

################################################################################
# Auto Start / Stop
################################################################################

variable "auto_start_enabled" {
  description = "Whether to enable automatic start of the application when a job is submitted. Set to null to omit"
  type        = bool
  default     = true
}

variable "auto_stop_enabled" {
  description = "Whether to enable automatic stop of the application when idle. Set to null to omit"
  type        = bool
  default     = true
}

variable "auto_stop_idle_timeout_minutes" {
  description = "Number of idle minutes before the application is automatically stopped"
  type        = number
  default     = 15
}

################################################################################
# Capacity Configuration
################################################################################

variable "initial_capacity" {
  description = "Map of initial capacity configurations keyed by worker type (e.g., 'Driver', 'Executor'). Each value needs 'worker_count' and optional 'worker_configuration' with cpu, memory, disk"
  type = map(object({
    worker_count = number
    worker_configuration = optional(object({
      cpu    = string
      memory = string
      disk   = optional(string)
    }))
  }))
  default = {}
}

variable "maximum_capacity" {
  description = "Maximum capacity configuration for the application. Object with 'cpu', 'memory', and optional 'disk'"
  type = object({
    cpu    = string
    memory = string
    disk   = optional(string)
  })
  default = null
}

################################################################################
# Network Configuration
################################################################################

variable "subnet_ids" {
  description = "List of subnet IDs to run the EMR Serverless application in. Required for VPC-connected applications"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "List of security group IDs for the EMR Serverless application ENIs"
  type        = list(string)
  default     = []
}

################################################################################
# Image Configuration
################################################################################

variable "image_uri" {
  description = "Custom container image URI for the EMR Serverless application"
  type        = string
  default     = null
}

################################################################################
# Interactive Configuration
################################################################################

variable "interactive_enabled" {
  description = "Whether to enable interactive (EMR Studio) endpoints. Set to null to omit"
  type        = bool
  default     = null
}

variable "livy_endpoint_enabled" {
  description = "Whether to enable Livy endpoint for interactive sessions"
  type        = bool
  default     = false
}

################################################################################
# IAM Execution Role
################################################################################

variable "create_execution_role" {
  description = "Whether to create an IAM execution role for EMR Serverless jobs"
  type        = bool
  default     = true
}

variable "execution_role_source_account_id" {
  description = "AWS account ID to restrict the execution role trust policy via aws:SourceAccount condition"
  type        = string
  default     = null
}

variable "execution_role_s3_bucket_arns" {
  description = "List of S3 bucket ARNs the execution role is allowed to access"
  type        = list(string)
  default     = []
}

variable "execution_role_glue_access_enabled" {
  description = "Whether to grant the execution role access to AWS Glue Data Catalog"
  type        = bool
  default     = true
}

variable "execution_role_additional_policy_arns" {
  description = "List of additional IAM policy ARNs to attach to the execution role"
  type        = list(string)
  default     = []
}
