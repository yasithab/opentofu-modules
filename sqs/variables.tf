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

variable "sqs_queue_name" {
  description = "Name of the SQS queue"
  type        = string
  default     = null
}

variable "visibility_timeout_seconds" {
  description = "The visibility timeout for the queue. An integer from 0 to 43200 (12 hours)"
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "The number of seconds Amazon SQS retains a message. Integer representing seconds, from 60 (1 minute) to 1209600 (14 days)"
  type        = number
  default     = 604800
}

variable "max_message_size" {
  description = "The limit of how many bytes a message can contain before Amazon SQS rejects it. An integer from 1024 bytes (1 KiB) up to 262144 bytes (256 KiB)"
  type        = number
  default     = 262144
}

variable "delay_seconds" {
  description = "The time in seconds that the delivery of all messages in the queue will be delayed. An integer from 0 to 900 (15 minutes)"
  type        = number
  default     = 0
}

variable "receive_wait_time_seconds" {
  description = "The time for which a ReceiveMessage call will wait for a message to arrive (long polling) before returning. An integer from 0 to 20 (seconds)"
  type        = number
  default     = 0
}

variable "create_queue_policy" {
  description = "Whether to create SQS queue policy"
  type        = bool
  default     = false
}

variable "source_queue_policy_documents" {
  description = "List of IAM policy documents that are merged together into the exported document. Statements must have unique `sid`s"
  type        = list(string)
  default     = []
}

variable "override_queue_policy_documents" {
  description = "List of IAM policy documents that are merged together into the exported document. In merging, statements with non-blank `sid`s will override statements with the same `sid`"
  type        = list(string)
  default     = []
}

variable "queue_policy_statements" {
  description = "A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage"
  type        = any
  default     = {}
}

variable "redrive_policy" {
  description = "The JSON policy to set up the Dead Letter Queue, see AWS docs. Note: when specifying maxReceiveCount, you must specify it as an integer (5), and not a string (\"5\")"
  type        = string
  default     = null
}

variable "deadletter_queue_enabled" {
  description = "Option whether to enable deadletter queue, This option overides `var.redrive_policy`"
  type        = bool
  default     = false
}

variable "deadletter_queue_count" {
  description = "Deadletter queue max receive count when `var.deadletter_queue_enabled` is true"
  type        = number
  default     = 5
}

variable "fifo_queue" {
  description = "Boolean designating a FIFO queue"
  type        = bool
  default     = false
}

variable "high_throughput_fifo_queue" {
  description = "Boolean designating a high-throughput FIFO queue"
  type        = bool
  default     = false
}

variable "fifo_high_throughput_deduplication_scope" {
  description = "(Optional) Specifies whether message deduplication occurs at the message group or queue level. Valid values are messageGroup and queue (default)"
  type        = string
  default     = "messageGroup"
}

variable "fifo_high_throughput_limit" {
  description = "(Optional) Specifies whether the FIFO queue throughput quota applies to the entire queue or per message group. Valid values are perQueue (default) and perMessageGroupId"
  type        = string
  default     = "perMessageGroupId"
}

variable "content_based_deduplication" {
  description = "Enables content-based deduplication for FIFO queues"
  type        = bool
  default     = false
}

variable "sqs_managed_sse_enabled" {
  description = "Enable server-side encryption (SSE) of message content with SQS-owned encryption keys"
  type        = bool
  default     = true
}

variable "kms_master_key_id" {
  description = "The ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK"
  type        = string
  default     = null
}

variable "kms_data_key_reuse_period_seconds" {
  description = "The length of time, in seconds, for which Amazon SQS can reuse a data key to encrypt or decrypt messages before calling AWS KMS again. An integer representing seconds, between 60 seconds (1 minute) and 86,400 seconds (24 hours)"
  type        = number
  default     = 300
}

variable "deadletter_queue_policy_enabled" {
  description = "Whether to create a policy for the dead letter queue. When true and no custom DLQ statements are provided, the source queue policy is automatically copied to the DLQ."
  type        = bool
  default     = false
}

variable "deadletter_queue_policy_statements" {
  description = "Custom IAM policy statements for the dead letter queue. When empty and deadletter_queue_policy_enabled is true, the main queue's policy statements are used instead."
  type        = any
  default     = []
}

variable "deadletter_source_policy_documents" {
  description = "List of IAM policy documents to merge for the dead letter queue policy (only used when deadletter_queue_policy_statements is provided)"
  type        = list(string)
  default     = []
}

variable "deadletter_override_policy_documents" {
  description = "List of IAM policy documents that override for the dead letter queue policy (only used when deadletter_queue_policy_statements is provided)"
  type        = list(string)
  default     = []
}

variable "create_redrive_allow_policy" {
  description = "Whether to create an SQS queue redrive allow policy to control which source queues can use this queue as a dead-letter queue"
  type        = bool
  default     = false
}

variable "redrive_allow_policy_permission" {
  description = "Permission type for the redrive allow policy. Valid values: allowAll, denyAll, byQueue"
  type        = string
  default     = "denyAll"
}

variable "redrive_allow_policy_source_queue_arns" {
  description = "List of source queue ARNs allowed to use this queue as a dead-letter queue. Only used when redrive_allow_policy_permission is byQueue"
  type        = list(string)
  default     = []
}
