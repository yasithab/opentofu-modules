variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name to use for resource naming and tagging."
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Slack Channel Configuration
################################################################################

variable "slack_channel_configuration_name" {
  description = "The name of the Slack channel configuration. Required when enabled = true."
  type        = string
  default     = null
}

variable "slack_channel_id" {
  description = "The ID of the Slack channel. Required when enabled = true."
  type        = string
  default     = null
}

variable "slack_workspace_id" {
  description = "The ID of the Slack workspace (team) authorized with AWS Chatbot. Maps to the slack_team_id argument in the AWS provider (e.g., T07EA123LEP). Required when enabled = true."
  type        = string
  default     = null
}

variable "chatbot_role_name" {
  description = "Override for the Chatbot IAM role name. Defaults to <name>-chatbot or chatbot-role."
  type        = string
  default     = null
}

variable "sns_topic_arns" {
  description = "ARNs of SNS topics which deliver notifications to AWS Chatbot, for example CloudWatch alarm notifications"
  type        = list(string)
  default     = null
}

variable "guardrail_policies" {
  description = "The list of IAM policy ARNs that are applied as channel guardrails. The AWS managed 'AdministratorAccess' policy is applied as a default if this is not set"
  type        = list(string)
  default     = null
}

variable "user_role_required" {
  description = "Enables use of a user role requirement in your chat configuration"
  type        = bool
  default     = false
}

variable "logging_level" {
  description = "Specifies the logging level for this configuration: ERROR, INFO or NONE. This property affects the log entries pushed to Amazon CloudWatch logs"
  type        = string
  default     = "NONE"

  validation {
    condition     = contains(["ERROR", "INFO", "NONE"], var.logging_level)
    error_message = "logging_level must be ERROR, INFO, or NONE."
  }
}

################################################################################
# Microsoft Teams Channel Configuration (optional)
################################################################################

variable "create_teams_configuration" {
  description = "Whether to create a Microsoft Teams channel configuration alongside the Slack configuration"
  type        = bool
  default     = false
}

variable "teams_channel_id" {
  description = "The ID of the Microsoft Teams channel"
  type        = string
  default     = null
}

variable "teams_channel_name" {
  description = "The name of the Microsoft Teams channel"
  type        = string
  default     = null
}

variable "teams_configuration_name" {
  description = "The name of the Microsoft Teams channel configuration"
  type        = string
  default     = null
}

variable "teams_team_id" {
  description = "The ID of the Microsoft Teams team"
  type        = string
  default     = null
}

variable "teams_team_name" {
  description = "The name of the Microsoft Teams team"
  type        = string
  default     = null
}

variable "teams_tenant_id" {
  description = "The ID of the Microsoft Teams tenant"
  type        = string
  default     = null
}

variable "teams_sns_topic_arns" {
  description = "ARNs of SNS topics for the Teams channel configuration"
  type        = list(string)
  default     = null
}

variable "teams_guardrail_policies" {
  description = "List of IAM policy ARNs applied as guardrails for the Teams channel"
  type        = list(string)
  default     = null
}

variable "teams_logging_level" {
  description = "Logging level for the Teams channel configuration: ERROR, INFO or NONE"
  type        = string
  default     = "NONE"

  validation {
    condition     = contains(["ERROR", "INFO", "NONE"], var.teams_logging_level)
    error_message = "teams_logging_level must be ERROR, INFO, or NONE."
  }
}

variable "teams_user_role_required" {
  description = "Enables use of a user role requirement in your Teams chat configuration"
  type        = bool
  default     = false
}
