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
# Metric Stream
################################################################################

variable "name" {
  description = "The name of the CloudWatch Metric Stream. Conflicts with `name_prefix`. At least one of `name` or `name_prefix` must be specified."
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "Creates a unique name beginning with the specified prefix. Conflicts with `name`. At least one of `name` or `name_prefix` must be specified."
  type        = string
  default     = null
}

variable "firehose_arn" {
  description = "ARN of the Amazon Kinesis Firehose delivery stream to use for this metric stream."
  type        = string
}

variable "role_arn" {
  description = "ARN of the IAM role that this metric stream will use to access Amazon Kinesis Firehose resources."
  type        = string
}

variable "output_format" {
  description = "Output format for the metric stream."
  type        = string

  validation {
    condition     = contains(["json", "opentelemetry0.7", "opentelemetry1.0"], var.output_format)
    error_message = "output_format must be one of: json, opentelemetry0.7, opentelemetry1.0."
  }
}

variable "exclude_filter" {
  description = "Map of exclusive metric filters. Each key is the namespace (e.g. AWS/EC2), and the value is a map with an optional `metric_names` list. Conflicts with `include_filter`."
  type        = any
  default     = {}
}

variable "include_filter" {
  description = "Map of inclusive metric filters. Each key is the namespace (e.g. AWS/EC2), and the value is a map with an optional `metric_names` list. Conflicts with `exclude_filter`."
  type        = any
  default     = {}
}

variable "statistics_configuration" {
  description = "List of statistics configurations for additional statistics to stream. Each element is a map with `additional_statistics` (list) and `include_metric` (list of maps with `metric_name` and `namespace`)."
  type        = any
  default     = []
}
