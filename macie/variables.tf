variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}


variable "name" {
  description = "Name identifier for the Macie deployment, used for naming and tagging conventions"
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Macie Account
################################################################################

variable "finding_publishing_frequency" {
  description = "Frequency at which Macie publishes updates to policy findings. Valid values: FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS"
  type        = string
  default     = "FIFTEEN_MINUTES"

  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.finding_publishing_frequency)
    error_message = "finding_publishing_frequency must be FIFTEEN_MINUTES, ONE_HOUR, or SIX_HOURS."
  }
}

################################################################################
# Organization Support
################################################################################

variable "create_organization_admin_account" {
  description = "Whether to designate a delegated Macie administrator account for the organization. Apply from the organization management account"
  type        = bool
  default     = false
}

variable "admin_account_id" {
  description = "AWS account ID to designate as the Macie delegated administrator. Required when create_organization_admin_account is true"
  type        = string
  default     = null

  validation {
    condition     = var.admin_account_id == null || can(regex("^[0-9]{12}$", var.admin_account_id))
    error_message = "admin_account_id must be a 12-digit AWS account ID."
  }
}

variable "create_organization_configuration" {
  description = "Whether to manage the organization-wide Macie configuration. Apply from the delegated administrator account"
  type        = bool
  default     = false
}

variable "auto_enable_organization_members" {
  description = "Whether to automatically enable Macie for new accounts that join the organization"
  type        = bool
  default     = true
}

################################################################################
# Classification Jobs
################################################################################

variable "classification_jobs" {
  description = "Map of classification job configurations. Each key is the job name. Job type must be ONE_TIME or SCHEDULED"
  type = map(object({
    job_type = string
    bucket_definitions = list(object({
      account_id = string
      buckets    = list(string)
    }))
    description         = optional(string)
    sampling_percentage = optional(number, 100)
    initial_run         = optional(bool, true)
    scoping = optional(object({
      excludes = optional(object({
        and = optional(list(object({
          simple_scope_term = optional(object({
            comparator = string
            key        = string
            values     = list(string)
          }))
        })), [])
      }))
      includes = optional(object({
        and = optional(list(object({
          simple_scope_term = optional(object({
            comparator = string
            key        = string
            values     = list(string)
          }))
        })), [])
      }))
    }))
    schedule_frequency = optional(object({
      monthly_schedule = optional(number)
      weekly_schedule  = optional(string)
    }))
  }))
  default = {}
}

################################################################################
# Custom Data Identifiers
################################################################################

variable "custom_data_identifiers" {
  description = "Map of custom data identifier configurations. Each key is the identifier name. At least one of regex or keywords must be specified"
  type = map(object({
    regex                  = optional(string)
    keywords               = optional(list(string))
    ignore_words           = optional(list(string))
    maximum_match_distance = optional(number)
    description            = optional(string)
  }))
  default = {}
}

################################################################################
# Member Accounts
################################################################################

variable "member_accounts" {
  description = "Map of member account configurations to associate with Macie. Each key is a friendly identifier"
  type = map(object({
    account_id                 = string
    email                      = string
    invite                     = optional(bool, true)
    invitation_message         = optional(string, "Macie member invitation")
    disable_email_notification = optional(bool, true)
    status                     = optional(string, "ENABLED")
  }))
  default = {}
}

################################################################################
# Classification Export Configuration
################################################################################

variable "classification_export_bucket_name" {
  description = "S3 bucket name for exporting Macie classification results. Set to null to skip export configuration"
  type        = string
  default     = null
}

variable "classification_export_key_prefix" {
  description = "S3 key prefix for exported Macie classification results"
  type        = string
  default     = null
}

variable "classification_export_kms_key_arn" {
  description = "ARN of the KMS key to encrypt exported Macie classification results in S3"
  type        = string
  default     = null
}
