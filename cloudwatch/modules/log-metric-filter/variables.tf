variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

################################################################################
# Log Metric Filter
################################################################################

variable "name" {
  description = "The name of the CloudWatch Log Metric Filter."
  type        = string

  validation {
    condition     = length(var.name) > 0
    error_message = "name must not be empty."
  }
}

variable "pattern" {
  description = "A valid CloudWatch Logs filter pattern for extracting metric data out of ingested log events."
  type        = string
}

variable "log_group_name" {
  description = "The name of the log group to associate the metric filter with."
  type        = string

  validation {
    condition     = length(var.log_group_name) > 0
    error_message = "log_group_name must not be empty."
  }
}

variable "metric_transformation_name" {
  description = "The name of the CloudWatch metric to which the monitored log information should be published."
  type        = string

  validation {
    condition     = length(var.metric_transformation_name) > 0
    error_message = "metric_transformation_name must not be empty."
  }
}

variable "metric_transformation_namespace" {
  description = "The destination namespace of the CloudWatch metric."
  type        = string

  validation {
    condition     = length(var.metric_transformation_namespace) > 0
    error_message = "metric_transformation_namespace must not be empty."
  }
}

variable "metric_transformation_value" {
  description = "The value to publish to the CloudWatch metric. Each log event is assigned this value."
  type        = string
  default     = "1"
}

variable "metric_transformation_default_value" {
  description = "The value to emit when a filter pattern does not match a log event. Conflicts with `metric_transformation_dimensions`."
  type        = string
  default     = null
}

variable "metric_transformation_unit" {
  description = "The unit to assign to the metric."
  type        = string
  default     = null
}

variable "metric_transformation_dimensions" {
  description = "Map of fields to use as dimensions for the metric. Conflicts with `metric_transformation_default_value`."
  type        = map(string)
  default     = null
}
