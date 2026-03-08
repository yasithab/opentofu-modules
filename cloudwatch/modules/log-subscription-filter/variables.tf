variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

################################################################################
# Log Subscription Filter
################################################################################

variable "name" {
  description = "The name of the CloudWatch Log Subscription Filter."
  type        = string
}

variable "destination_arn" {
  description = "The ARN of the destination to deliver matching log events to (Kinesis stream, Lambda function, or Kinesis Data Firehose delivery stream)."
  type        = string
}

variable "filter_pattern" {
  description = "A valid CloudWatch Logs filter pattern for subscribing to a filtered stream of log events. Use empty string to match everything."
  type        = string
  default     = ""
}

variable "log_group_name" {
  description = "The name of the log group to associate the subscription filter with."
  type        = string
}

variable "role_arn" {
  description = "The ARN of an IAM role that grants CloudWatch Logs permissions to deliver ingested log events to the destination. Required for Kinesis stream/Firehose destinations."
  type        = string
  default     = null
}

variable "distribution" {
  description = "The method used to distribute log data to the destination."
  type        = string
  default     = null

  validation {
    condition     = var.distribution == null || contains(["Random", "ByLogStream"], var.distribution)
    error_message = "distribution must be either Random or ByLogStream."
  }
}
