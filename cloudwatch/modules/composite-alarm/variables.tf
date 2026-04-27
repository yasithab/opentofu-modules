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
# Composite Alarm
################################################################################

variable "alarm_name" {
  description = "The name for the composite alarm. Must be unique within the region."
  type        = string

  validation {
    condition     = length(var.alarm_name) > 0
    error_message = "alarm_name must not be empty."
  }
}

variable "alarm_description" {
  description = "The description for the composite alarm."
  type        = string
  default     = null
}

variable "alarm_rule" {
  description = "An expression that specifies which other alarms are to be evaluated to determine this composite alarm's state (e.g. ALARM(my-alarm-1) OR ALARM(my-alarm-2))."
  type        = string

  validation {
    condition     = length(var.alarm_rule) > 0
    error_message = "alarm_rule must not be empty."
  }
}

variable "actions_enabled" {
  description = "Indicates whether actions should be executed during any changes to the alarm's state."
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "The set of actions to execute when this alarm transitions into an ALARM state from any other state. Maximum 5 ARNs."
  type        = list(string)
  default     = null

  validation {
    condition     = var.alarm_actions == null || length(var.alarm_actions) <= 5
    error_message = "alarm_actions supports a maximum of 5 ARNs."
  }
}

variable "ok_actions" {
  description = "The set of actions to execute when this alarm transitions into an OK state from any other state. Maximum 5 ARNs."
  type        = list(string)
  default     = null

  validation {
    condition     = var.ok_actions == null || length(var.ok_actions) <= 5
    error_message = "ok_actions supports a maximum of 5 ARNs."
  }
}

variable "insufficient_data_actions" {
  description = "The set of actions to execute when this alarm transitions into an INSUFFICIENT_DATA state from any other state. Maximum 5 ARNs."
  type        = list(string)
  default     = null

  validation {
    condition     = var.insufficient_data_actions == null || length(var.insufficient_data_actions) <= 5
    error_message = "insufficient_data_actions supports a maximum of 5 ARNs."
  }
}

variable "actions_suppressor" {
  description = "Configuration for actions suppression."
  type = object({
    alarm            = string
    extension_period = number
    wait_period      = number
  })
  default = null
}
