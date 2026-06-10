variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "region" {
  description = "Region where the resource(s) will be managed. Defaults to the region set in the provider configuration"
  type        = string
  default     = null
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

variable "shard_count" {
  description = "The number of shards that the stream will use"
  type        = number
  default     = 1
}

variable "retention_period" {
  description = "Length of time data records are accessible after they are added to the stream. The maximum value of a stream's retention period is 168 hours. Minimum value is 24. Default is 24."
  type        = number
  default     = 24
}

variable "shard_level_metrics" {
  description = "A list of shard-level CloudWatch metrics which can be enabled for the stream."
  type        = list(string)
  default = [
    "IncomingBytes",
    "OutgoingBytes"
  ]
}

variable "enforce_consumer_deletion" {
  description = "A boolean that indicates all registered consumers should be deregistered from the stream so that the stream can be destroyed without error. Defaults to `false` so streams with registered consumers are not destroyed accidentally."
  type        = bool
  default     = false
}

variable "encryption_type" {
  description = "The encryption type to use. Acceptable values are `NONE` and `KMS`."
  type        = string
  default     = "KMS"
}

variable "kms_key_id" {
  description = "The GUID for the customer-managed KMS key to use for encryption."
  type        = string
  default     = "alias/aws/kinesis"
}

variable "stream_mode" {
  description = "Specifies the capacity mode of the stream. Must be either `PROVISIONED` or `ON_DEMAND`. If `ON_DEMAND` is used, then `shard_count` is ignored."
  type        = string
  default     = null
}

variable "consumer_count" {
  description = "Number of consumers to register with Kinesis stream"
  type        = number
  default     = 0
}

variable "max_record_size_in_kib" {
  description = "The maximum size of a data payload that can be written to the stream in KiB. Defaults to 1024 KiB. Valid values between 1024 and 10240."
  type        = number
  default     = null
}

variable "resource_policy" {
  description = "IAM resource policy (JSON) to attach to the Kinesis stream, e.g. for cross-account read/write access. Set to `null` (default) to skip creating a resource policy."
  type        = string
  default     = null

  validation {
    condition     = var.resource_policy == null || can(jsondecode(var.resource_policy))
    error_message = "resource_policy must be a valid JSON policy document."
  }
}
