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
# Metric Alarm
################################################################################

variable "alarm_name" {
  description = "The descriptive name for the alarm."
  type        = string
}

variable "alarm_description" {
  description = "The description for the alarm."
  type        = string
  default     = null
}

variable "comparison_operator" {
  description = "The arithmetic operation to use when comparing the specified statistic and threshold."
  type        = string

  validation {
    condition = contains([
      "GreaterThanOrEqualToThreshold",
      "GreaterThanThreshold",
      "GreaterThanUpperThreshold",
      "LessThanLowerOrGreaterThanUpperThreshold",
      "LessThanLowerThreshold",
      "LessThanOrEqualToThreshold",
      "LessThanThreshold",
    ], var.comparison_operator)
    error_message = "comparison_operator must be one of: GreaterThanOrEqualToThreshold, GreaterThanThreshold, GreaterThanUpperThreshold, LessThanLowerOrGreaterThanUpperThreshold, LessThanLowerThreshold, LessThanOrEqualToThreshold, LessThanThreshold."
  }
}

variable "evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
}

variable "threshold" {
  description = "The value against which the specified statistic is compared. Required if metric_query is not provided."
  type        = number
  default     = null
}

variable "threshold_metric_id" {
  description = "If this is an alarm based on an anomaly detection model, make this value match the ID of the ANOMALY_DETECTION_BAND function."
  type        = string
  default     = null
}

variable "unit" {
  description = "The unit for the alarm's associated metric."
  type        = string
  default     = null
}

variable "metric_name" {
  description = "The name for the alarm's associated metric."
  type        = string
  default     = null
}

variable "namespace" {
  description = "The namespace for the alarm's associated metric."
  type        = string
  default     = null
}

variable "period" {
  description = "The period in seconds over which the specified statistic is applied."
  type        = number
  default     = null
}

variable "statistic" {
  description = "The statistic to apply to the alarm's associated metric. Valid values: SampleCount, Average, Sum, Minimum, Maximum."
  type        = string
  default     = null

  validation {
    condition     = var.statistic == null || contains(["SampleCount", "Average", "Sum", "Minimum", "Maximum"], var.statistic)
    error_message = "statistic must be one of: SampleCount, Average, Sum, Minimum, Maximum."
  }
}

variable "extended_statistic" {
  description = "The percentile statistic for the metric associated with the alarm (e.g. p99.9)."
  type        = string
  default     = null
}

variable "dimensions" {
  description = "The dimensions for the alarm's associated metric."
  type        = map(string)
  default     = null
}

variable "actions_enabled" {
  description = "Indicates whether actions should be executed during any changes to the alarm's state."
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "The list of actions to execute when this alarm transitions into an ALARM state from any other state."
  type        = list(string)
  default     = null
}

variable "ok_actions" {
  description = "The list of actions to execute when this alarm transitions into an OK state from any other state."
  type        = list(string)
  default     = null
}

variable "insufficient_data_actions" {
  description = "The list of actions to execute when this alarm transitions into an INSUFFICIENT_DATA state from any other state."
  type        = list(string)
  default     = null
}

variable "datapoints_to_alarm" {
  description = "The number of datapoints that must be breaching to trigger the alarm."
  type        = number
  default     = null
}

variable "treat_missing_data" {
  description = "Sets how this alarm is to handle missing data points."
  type        = string
  default     = "missing"

  validation {
    condition     = contains(["missing", "ignore", "breaching", "notBreaching"], var.treat_missing_data)
    error_message = "treat_missing_data must be one of: missing, ignore, breaching, notBreaching."
  }
}

variable "evaluate_low_sample_count_percentiles" {
  description = "Used only for alarms based on percentiles. Valid values: evaluate, ignore."
  type        = string
  default     = null

  validation {
    condition     = var.evaluate_low_sample_count_percentiles == null || contains(["evaluate", "ignore"], var.evaluate_low_sample_count_percentiles)
    error_message = "evaluate_low_sample_count_percentiles must be either evaluate or ignore."
  }
}

variable "metric_query" {
  description = "Enables you to create an alarm based on a metric math expression. A list of metric query objects."
  type        = any
  default     = []
}
