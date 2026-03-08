variable "enabled" {
  description = "Whether to enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name tag for the Flow Log resource"
  type        = string
  default     = null
}

# Resource attachment options (mutually exclusive)
variable "vpc_id" {
  description = "The ID of the VPC to attach to (mutually exclusive with other attachment options)"
  type        = string
  default     = null
}

variable "eni_id" {
  description = "Elastic Network Interface ID to attach to (mutually exclusive with other attachment options)"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "Subnet ID to attach to (mutually exclusive with other attachment options)"
  type        = string
  default     = null
}

variable "transit_gateway_id" {
  description = "Transit Gateway ID to attach to (mutually exclusive with other attachment options)"
  type        = string
  default     = null
}

variable "transit_gateway_attachment_id" {
  description = "Transit Gateway Attachment ID to attach to (mutually exclusive with other attachment options)"
  type        = string
  default     = null
}

variable "regional_nat_gateway_id" {
  description = "Regional NAT Gateway ID to attach to (mutually exclusive with other attachment options)"
  type        = string
  default     = null
}

# Logging configuration
variable "log_destination_type" {
  description = "The type of the logging destination. Valid values: cloud-watch-logs, s3, kinesis-data-firehose"
  type        = string
  default     = "cloud-watch-logs"

  validation {
    condition     = contains(["cloud-watch-logs", "s3", "kinesis-data-firehose"], var.log_destination_type)
    error_message = "Valid values are 'cloud-watch-logs', 's3', or 'kinesis-data-firehose'."
  }
}

variable "log_destination" {
  description = "ARN of the logging destination. If not specified, a default destination will be created based on log_destination_type"
  type        = string
  default     = null
}

variable "traffic_type" {
  description = "The type of traffic to capture. Valid values: ACCEPT, REJECT, ALL"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.traffic_type)
    error_message = "Valid values are 'ACCEPT', 'REJECT', or 'ALL'."
  }
}

variable "deliver_cross_account_role" {
  description = "ARN of the IAM role that allows publishing flow logs across accounts"
  type        = string
  default     = null
}

variable "iam_role_arn" {
  description = "ARN of an existing IAM role for posting logs to CloudWatch Logs (only used when log_destination_type is 'cloud-watch-logs')"
  type        = string
  default     = null
}

variable "max_aggregation_interval" {
  description = "The maximum interval of time (in seconds) during which a flow of packets is captured and aggregated into a flow log record. Valid values: 60, 600"
  type        = number
  default     = 60

  validation {
    condition     = contains([60, 600], var.max_aggregation_interval)
    error_message = "Valid values are 60 or 600."
  }
}

variable "log_format" {
  description = "The fields to include in the flow log record. See AWS documentation for format syntax"
  type        = string
  default     = null
}

variable "destination_options" {
  description = "Destination options for flow logs (only applicable when log_destination_type is 's3')"
  type = object({
    file_format                = optional(string, "plain-text")
    hive_compatible_partitions = optional(bool, false)
    per_hour_partition         = optional(bool, false)
  })
  default = null
}

# CloudWatch Logs specific
variable "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group (only used when log_destination_type is 'cloud-watch-logs' and log_destination is not specified)"
  type        = string
  default     = null
}

variable "cloudwatch_log_retention_in_days" {
  description = "Number of days to retain logs in CloudWatch Logs"
  type        = number
  default     = 30
}

variable "cloudwatch_log_kms_key_id" {
  description = "ARN of the KMS key to use for encrypting CloudWatch Logs"
  type        = string
  default     = null
}

variable "cloudwatch_log_group_skip_destroy" {
  description = "Set to true if you do not want to destroy the log group at destroy time, and instead just remove the log group from the Terraform state"
  type        = bool
  default     = false
}

variable "cloudwatch_log_group_class" {
  description = "Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT_ACCESS"
  type        = string
  default     = null

  validation {
    condition     = var.cloudwatch_log_group_class == null || contains(["STANDARD", "INFREQUENT_ACCESS"], var.cloudwatch_log_group_class)
    error_message = "Valid values for cloudwatch_log_group_class are 'STANDARD' or 'INFREQUENT_ACCESS'."
  }
}

# S3 specific
variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket (only used when log_destination_type is 's3' and log_destination is not specified)"
  type        = string
  default     = null
}

# Kinesis Firehose specific
variable "kinesis_firehose_delivery_stream_arn" {
  description = "ARN of the Kinesis Firehose delivery stream (only used when log_destination_type is 'kinesis-data-firehose' and log_destination is not specified)"
  type        = string
  default     = null
}

# IAM specific
variable "iam_role_name" {
  description = "Name of the IAM role to create (only used when log_destination_type is 'cloud-watch-logs' and iam_role_arn is not specified)"
  type        = string
  default     = null
}

variable "iam_policy_name" {
  description = "Name of the IAM policy to create (only used when log_destination_type is 'cloud-watch-logs' and iam_role_arn is not specified)"
  type        = string
  default     = null
}

# General
variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}
