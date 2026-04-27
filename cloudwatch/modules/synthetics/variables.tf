variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}


variable "name" {
  description = "Name prefix used for naming resources (IAM role, S3 bucket, etc.)."
  type        = string

  validation {
    condition     = length(var.name) > 0
    error_message = "name must not be empty."
  }
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Canaries
################################################################################

variable "canaries" {
  description = "Map of canary configurations. Each key is a unique identifier for the canary."
  type = map(object({
    name                         = string
    handler                      = string
    runtime_version              = string
    schedule_expression          = string
    schedule_duration_in_seconds = optional(number)
    zip_file                     = optional(string)
    s3_bucket                    = optional(string)
    s3_key                       = optional(string)
    s3_version                   = optional(string)
    start_canary                 = optional(bool, true)
    delete_lambda                = optional(bool, true)
    execution_role_arn           = optional(string)
    artifact_s3_location         = optional(string)
    success_retention_period     = optional(number)
    failure_retention_period     = optional(number)
    run_config = optional(object({
      timeout_in_seconds    = optional(number, 60)
      memory_in_mb          = optional(number)
      active_tracing        = optional(bool, false)
      environment_variables = optional(map(string))
    }))
    vpc_config = optional(object({
      security_group_ids = list(string)
      subnet_ids         = list(string)
    }))
    artifact_config = optional(object({
      encryption_mode = optional(string, "SSE_S3")
      kms_key_arn     = optional(string)
    }))
    create_alarm              = optional(bool)
    alarm_name                = optional(string)
    alarm_description         = optional(string)
    alarm_comparison_operator = optional(string)
    alarm_evaluation_periods  = optional(number)
    alarm_period              = optional(number)
    alarm_threshold           = optional(number)
    alarm_treat_missing_data  = optional(string)
    alarm_actions             = optional(list(string))
    ok_actions                = optional(list(string))
    insufficient_data_actions = optional(list(string))
  }))
  default = {}
}

variable "default_success_retention_period" {
  description = "Default number of days to retain successful canary run data."
  type        = number
  default     = 31

  validation {
    condition     = var.default_success_retention_period >= 1 && var.default_success_retention_period <= 455
    error_message = "default_success_retention_period must be between 1 and 455 days."
  }
}

variable "default_failure_retention_period" {
  description = "Default number of days to retain failed canary run data."
  type        = number
  default     = 31

  validation {
    condition     = var.default_failure_retention_period >= 1 && var.default_failure_retention_period <= 455
    error_message = "default_failure_retention_period must be between 1 and 455 days."
  }
}

################################################################################
# Canary Groups
################################################################################

variable "canary_groups" {
  description = "Map of canary group configurations. Each key is the group name, with canary_keys listing which canaries belong to it."
  type = map(object({
    canary_keys = optional(list(string), [])
  }))
  default = {}
}

################################################################################
# S3 Artifact Bucket
################################################################################

variable "create_artifact_bucket" {
  description = "Determines whether an S3 bucket is created for canary artifacts."
  type        = bool
  default     = true
}

variable "artifact_s3_bucket_name" {
  description = "Name of the S3 bucket for canary artifacts. Used as bucket name when creating, or as existing bucket reference."
  type        = string
  default     = null
}

variable "artifact_s3_bucket_use_name_prefix" {
  description = "Determines whether to use the S3 bucket name as a prefix."
  type        = bool
  default     = false
}

variable "artifact_s3_bucket_force_destroy" {
  description = "Allow destruction of the S3 bucket even if it contains objects."
  type        = bool
  default     = false
}

variable "artifact_s3_kms_key_arn" {
  description = "ARN of a KMS key to use for encrypting canary artifacts in S3. Defaults to AES256 if not set."
  type        = string
  default     = null

  validation {
    condition     = var.artifact_s3_kms_key_arn == null || can(regex("^arn:", var.artifact_s3_kms_key_arn))
    error_message = "artifact_s3_kms_key_arn must be a valid ARN starting with 'arn:'."
  }
}

variable "artifact_s3_expiration_days" {
  description = "Number of days after which canary artifacts in S3 are automatically deleted. Set to 0 to disable."
  type        = number
  default     = 90

  validation {
    condition     = var.artifact_s3_expiration_days >= 0
    error_message = "artifact_s3_expiration_days must be 0 (disabled) or a positive number of days."
  }
}

################################################################################
# IAM Role
################################################################################

variable "create_iam_role" {
  description = "Determines whether an IAM execution role is created for the canaries."
  type        = bool
  default     = true
}

variable "iam_role_name" {
  description = "Name of the IAM role. Defaults to synthetics-{name}."
  type        = string
  default     = null
}

variable "iam_role_use_name_prefix" {
  description = "Determines whether to use the IAM role name as a prefix."
  type        = bool
  default     = false
}

variable "iam_role_path" {
  description = "Path for the IAM role."
  type        = string
  default     = "/"
}

variable "iam_role_policy_arns" {
  description = "Map of additional IAM policy ARNs to attach to the canary execution role."
  type        = map(string)
  default     = {}
}

variable "enable_vpc_policy" {
  description = "Determines whether VPC networking permissions are added to the IAM role. Enable when any canary uses vpc_config."
  type        = bool
  default     = false
}

################################################################################
# CloudWatch Alarms
################################################################################

variable "create_canary_alarms" {
  description = "Default value for whether to create CloudWatch alarms for canaries. Can be overridden per canary."
  type        = bool
  default     = true
}

variable "default_alarm_actions" {
  description = "Default list of ARNs to notify when a canary alarm transitions to ALARM state."
  type        = list(string)
  default     = []
}

variable "default_ok_actions" {
  description = "Default list of ARNs to notify when a canary alarm transitions to OK state."
  type        = list(string)
  default     = []
}

################################################################################
