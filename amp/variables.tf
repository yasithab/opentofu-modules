variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "region" {
  description = "Region where resources will be managed. Defaults to the Region set in the provider configuration."
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Workspace
################################################################################

variable "create_workspace" {
  description = "Determines whether a workspace will be created or to use an existing workspace"
  type        = bool
  default     = true
}

variable "workspace_id" {
  description = "The ID of an existing workspace to use when `create_workspace` is `false`"
  type        = string
  default     = null
}

variable "workspace_alias" {
  description = "The alias of the prometheus workspace. See more in the [AWS Docs](https://docs.aws.amazon.com/prometheus/latest/userguide/AMP-onboard-create-workspace.html)"
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "The ARN of the KMS Key to for encryption at rest"
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:aws[a-z-]*:kms:", var.kms_key_arn))
    error_message = "kms_key_arn must be a valid KMS key ARN (starting with 'arn:aws:kms:') or null."
  }
}

################################################################################
# Alert Manager Definition
################################################################################

variable "alert_manager_definition" {
  description = "The alert manager definition that you want to be applied. See more in the [AWS Docs](https://docs.aws.amazon.com/prometheus/latest/userguide/AMP-alert-manager.html)"
  type        = string
  default     = <<-EOT
    alertmanager_config: |
      route:
        receiver: 'default'
      receivers:
        - name: 'default'
  EOT
}

################################################################################
# Rule Group Namespace
################################################################################

variable "rule_group_namespaces" {
  description = "A map of one or more rule group namespace definitions"
  type        = map(any)
  default     = {}
}

################################################################################
# CloudWatch Log Group
################################################################################

variable "enable_cloudwatch_logging" {
  description = "Determines whether CloudWatch logging is configured"
  type        = bool
  default     = true
}

variable "create_cloudwatch_log_group" {
  description = "Determines whether a log group is created by this module"
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_name" {
  description = "Custom name of CloudWatch log group"
  type        = string
  default     = null
}

variable "cloudwatch_log_group_use_name_prefix" {
  description = "Determines whether the log group name should be used as a prefix"
  type        = bool
  default     = false
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain log events. Default is 30 days"
  type        = number
  default     = 30

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_log_group_retention_in_days)
    error_message = "cloudwatch_log_group_retention_in_days must be one of the allowed CloudWatch Logs retention values: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653."
  }
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "If a KMS Key ARN is set, this key will be used to encrypt the corresponding log group. Please be sure that the KMS Key has an appropriate key policy (https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html)"
  type        = string
  default     = null
}

variable "cloudwatch_log_group_skip_destroy" {
  description = "Set to true if you do not wish the log group (and any logs it may contain) to be deleted at destroy time, and instead just remove the log group from the Terraform state."
  type        = bool
  default     = false
}

variable "cloudwatch_log_group_class" {
  description = "Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT_ACCESS."
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "INFREQUENT_ACCESS"], var.cloudwatch_log_group_class)
    error_message = "cloudwatch_log_group_class must be STANDARD or INFREQUENT_ACCESS."
  }
}

################################################################################
# Prometheus Scraper
################################################################################

variable "scrapers" {
  description = "Map of Prometheus scraper configurations. Each key is a unique scraper name."
  type = map(object({
    alias                = optional(string)
    scrape_configuration = string
    eks_cluster_arn      = string
    security_group_ids   = optional(list(string), [])
    subnet_ids           = list(string)
    workspace_arn        = optional(string)
    role_configuration = optional(object({
      source_role_arn = optional(string)
      target_role_arn = optional(string)
    }))
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }))
  }))
  default = {}
}

################################################################################
