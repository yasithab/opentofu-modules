variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Log Group
################################################################################

variable "log_group_name" {
  description = "The name of the CloudWatch Log Group to create."
  type        = string
}

variable "use_name_prefix" {
  description = "Determines whether `log_group_name` is used as a prefix."
  type        = bool
  default     = false
}

variable "retention_in_days" {
  description = "Number of days to retain log events in the log group. Use 0 for infinite retention (never expire). Defaults to 90."
  type        = number
  default     = 90

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.retention_in_days)
    error_message = "retention_in_days must be one of: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653."
  }
}

variable "kms_key_id" {
  description = "The ARN of the KMS key to use for encrypting log data."
  type        = string
  default     = null
}

variable "log_group_class" {
  description = "The log class of the log group. Valid values: STANDARD, INFREQUENT_ACCESS."
  type        = string
  default     = null

  validation {
    condition     = var.log_group_class == null || contains(["STANDARD", "INFREQUENT_ACCESS"], var.log_group_class)
    error_message = "log_group_class must be either STANDARD or INFREQUENT_ACCESS."
  }
}

variable "skip_destroy" {
  description = "Set to true if you do not wish the log group to be deleted at destroy time, and instead just remove the log group from the OpenTofu state."
  type        = bool
  default     = null
}

variable "deletion_protection_enabled" {
  description = "Whether to enable deletion protection on the log group. When enabled, the log group cannot be deleted."
  type        = bool
  default     = true
}

################################################################################
# Log Stream(s)
################################################################################

variable "create_log_streams" {
  description = "Whether to create CloudWatch Log Streams."
  type        = bool
  default     = false
}

variable "log_streams" {
  description = "A map of log stream definitions to create. Each key is the log stream name. Optionally set `name` to override the key."
  type = map(object({
    name = optional(string)
  }))
  default = {}
}
