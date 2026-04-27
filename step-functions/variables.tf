
variable "enabled" {
  description = "Determines whether resources will be created (affects all resources)"
  type        = bool
  default     = true
}


variable "name" {
  description = "Name of the Step Functions state machine"
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
# State Machine
################################################################################

variable "definition" {
  description = "The Amazon States Language (ASL) definition of the state machine in JSON format"
  type        = string

  validation {
    condition     = length(var.definition) > 0
    error_message = "The definition must not be empty."
  }
}

variable "type" {
  description = "Type of the state machine. Valid values: `STANDARD`, `EXPRESS`."
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "EXPRESS"], var.type)
    error_message = "The type must be 'STANDARD' or 'EXPRESS'."
  }
}

variable "publish" {
  description = "Whether to publish a version of the state machine during creation"
  type        = bool
  default     = false
}

################################################################################
# IAM Role
################################################################################

variable "create_role" {
  description = "Whether to create an IAM role for the state machine"
  type        = bool
  default     = true
}

variable "role_arn" {
  description = "ARN of an existing IAM role to use. Required if `create_role` is false."
  type        = string
  default     = null

  validation {
    condition     = var.role_arn == null || can(regex("^arn:", var.role_arn))
    error_message = "The role_arn must be a valid ARN starting with 'arn:'."
  }
}

variable "role_name" {
  description = "Name of the IAM role. Defaults to the state machine name with `-role` suffix."
  type        = string
  default     = null
}

variable "role_description" {
  description = "Description of the IAM role"
  type        = string
  default     = null
}

variable "role_path" {
  description = "Path for the IAM role"
  type        = string
  default     = null
}

variable "role_permissions_boundary" {
  description = "ARN of the permissions boundary policy to attach to the IAM role"
  type        = string
  default     = null

  validation {
    condition     = var.role_permissions_boundary == null || can(regex("^arn:", var.role_permissions_boundary))
    error_message = "The role_permissions_boundary must be a valid ARN starting with 'arn:'."
  }
}

variable "role_force_detach_policies" {
  description = "Whether to force detaching any policies the IAM role has before destroying it"
  type        = bool
  default     = true
}

variable "trusted_service_principals" {
  description = "List of AWS service principals that can assume the role. Defaults to `states.amazonaws.com`."
  type        = list(string)
  default     = ["states.amazonaws.com"]
}

variable "trusted_account_arns" {
  description = "List of trusted AWS account ARNs that can assume the role"
  type        = list(string)
  default     = []
}

variable "role_policy_arns" {
  description = "Map of IAM policy ARNs to attach to the role"
  type        = map(string)
  default     = {}
}

variable "role_inline_policies" {
  description = "Map of inline IAM policies to attach to the role. Key is the policy name, value is the JSON policy document."
  type        = map(string)
  default     = {}
}

################################################################################
# Logging
################################################################################

variable "logging_enabled" {
  description = "Whether to enable logging for the state machine"
  type        = bool
  default     = true
}

variable "logging_level" {
  description = "Defines which category of execution history events are logged. Valid values: `ALL`, `ERROR`, `FATAL`, `OFF`."
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "ERROR", "FATAL", "OFF"], var.logging_level)
    error_message = "The logging_level must be 'ALL', 'ERROR', 'FATAL', or 'OFF'."
  }
}

variable "logging_include_execution_data" {
  description = "Whether the execution data is included in the log output"
  type        = bool
  default     = true
}

variable "create_log_group" {
  description = "Whether to create a CloudWatch log group for the state machine"
  type        = bool
  default     = true
}

variable "log_group_name" {
  description = "Name of the CloudWatch log group. Defaults to `/aws/states/<name>`."
  type        = string
  default     = null
}

variable "log_group_retention_in_days" {
  description = "Number of days to retain log events in the CloudWatch log group"
  type        = number
  default     = 30
}

variable "log_group_kms_key_id" {
  description = "KMS key ARN to use for encrypting the CloudWatch log group"
  type        = string
  default     = null
}

variable "existing_log_group_arn" {
  description = "ARN of an existing CloudWatch log group. Used when `create_log_group` is false."
  type        = string
  default     = null

  validation {
    condition     = var.existing_log_group_arn == null || can(regex("^arn:", var.existing_log_group_arn))
    error_message = "The existing_log_group_arn must be a valid ARN starting with 'arn:'."
  }
}

################################################################################
# Tracing
################################################################################

variable "tracing_enabled" {
  description = "Whether to enable X-Ray tracing for the state machine"
  type        = bool
  default     = false
}

################################################################################
# CloudWatch Alarms
################################################################################

variable "create_alarms" {
  description = "Whether to create CloudWatch alarms for the state machine"
  type        = bool
  default     = false
}

variable "alarm_actions" {
  description = "List of ARNs to notify when the alarm transitions to ALARM state"
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "List of ARNs to notify when the alarm transitions to OK state"
  type        = list(string)
  default     = []
}

variable "alarm_execution_failed_threshold" {
  description = "Threshold for the ExecutionsFailed alarm"
  type        = number
  default     = 1
}

variable "alarm_execution_failed_period" {
  description = "Period in seconds for the ExecutionsFailed alarm"
  type        = number
  default     = 300
}

variable "alarm_execution_failed_evaluation_periods" {
  description = "Number of evaluation periods for the ExecutionsFailed alarm"
  type        = number
  default     = 1
}

variable "alarm_execution_throttled_threshold" {
  description = "Threshold for the ExecutionsThrottled alarm"
  type        = number
  default     = 1
}

variable "alarm_execution_timed_out_threshold" {
  description = "Threshold for the ExecutionsTimedOut alarm"
  type        = number
  default     = 1
}

################################################################################
# Event Source Mapping
################################################################################

variable "event_rules" {
  description = "Map of EventBridge rules to create for triggering the state machine. Each entry supports `description`, `schedule_expression`, `event_pattern`, and `is_enabled`."
  type        = any
  default     = {}
}

variable "event_role_arn" {
  description = "ARN of an existing IAM role for EventBridge to use when invoking the state machine. If not set, a role is created."
  type        = string
  default     = null

  validation {
    condition     = var.event_role_arn == null || can(regex("^arn:", var.event_role_arn))
    error_message = "The event_role_arn must be a valid ARN starting with 'arn:'."
  }
}

variable "create_event_role" {
  description = "Whether to create an IAM role for EventBridge triggers"
  type        = bool
  default     = false
}
