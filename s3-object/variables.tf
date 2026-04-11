variable "enabled" {
  description = "Determines whether resources will be created (affects all resources)"
  type        = bool
  default     = true
}

variable "region" {
  description = "AWS region. If null, uses the provider's region."
  type        = string
  default     = null
}

variable "name" {
  description = "Name prefix used for resources (used in tags)"
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# S3 Object
################################################################################

variable "create_object" {
  description = "Whether to create the S3 object"
  type        = bool
  default     = true
}

variable "bucket" {
  description = "Name of the S3 bucket to put the object in"
  type        = string
}

variable "key" {
  description = "Key (path) of the object in the bucket"
  type        = string
}

variable "source_file" {
  description = "Path to a local file to upload. Conflicts with `content` and `content_base64`."
  type        = string
  default     = null
}

variable "content" {
  description = "Inline string content for the object. Conflicts with `source_file` and `content_base64`."
  type        = string
  default     = null
}

variable "content_base64" {
  description = "Base64-encoded content for the object. Conflicts with `source_file` and `content`."
  type        = string
  default     = null
}

variable "content_type" {
  description = "Standard MIME type of the object (e.g., `application/json`, `text/html`)"
  type        = string
  default     = null
}

variable "content_disposition" {
  description = "Content-Disposition header value (e.g., `attachment; filename=\"file.txt\"`)"
  type        = string
  default     = null
}

variable "content_encoding" {
  description = "Content-Encoding header value (e.g., `gzip`)"
  type        = string
  default     = null
}

variable "content_language" {
  description = "Content-Language header value (e.g., `en-US`)"
  type        = string
  default     = null
}

variable "cache_control" {
  description = "Cache-Control header value (e.g., `max-age=86400, public`)"
  type        = string
  default     = null
}

variable "etag" {
  description = "ETag of the object. Triggers replacement when changed. Use `filemd5()` for file sources."
  type        = string
  default     = null
}

variable "source_hash" {
  description = "Hash of the source content. Triggers replacement when changed."
  type        = string
  default     = null
}

################################################################################
# Storage Class
################################################################################

variable "storage_class" {
  description = "Storage class for the object. One of: `STANDARD`, `REDUCED_REDUNDANCY`, `ONEZONE_IA`, `INTELLIGENT_TIERING`, `GLACIER`, `DEEP_ARCHIVE`, `GLACIER_IR`"
  type        = string
  default     = "STANDARD"
}

################################################################################
# Server-Side Encryption
################################################################################

variable "server_side_encryption" {
  description = "Server-side encryption algorithm. `AES256` (SSE-S3), `aws:kms` (SSE-KMS), or `aws:kms:dsse` (DSSE-KMS)"
  type        = string
  default     = "AES256"
}

variable "kms_key_id" {
  description = "ARN of the KMS key for SSE-KMS encryption. Required when `server_side_encryption` is `aws:kms` or `aws:kms:dsse`."
  type        = string
  default     = null
}

variable "bucket_key_enabled" {
  description = "Whether to use S3 Bucket Keys for SSE-KMS, reducing KMS request costs"
  type        = bool
  default     = true
}

variable "customer_algorithm" {
  description = "SSE-C encryption algorithm (e.g., `AES256`). Used for customer-provided encryption keys."
  type        = string
  default     = null
}

variable "customer_key" {
  description = "Base64-encoded 256-bit customer-provided encryption key for SSE-C"
  type        = string
  default     = null
  sensitive   = true
}

################################################################################
# Object Tagging
################################################################################

variable "object_tags" {
  description = "Map of tags to apply to the S3 object (separate from resource tags)"
  type        = map(string)
  default     = {}
}

################################################################################
# Metadata
################################################################################

variable "metadata" {
  description = "Map of custom metadata key-value pairs to store with the object"
  type        = map(string)
  default     = {}
}

variable "website_redirect" {
  description = "Target URL for website redirect on the object"
  type        = string
  default     = null
}

################################################################################
# Object Lock
################################################################################

variable "object_lock_mode" {
  description = "Object lock retention mode. `GOVERNANCE` or `COMPLIANCE`."
  type        = string
  default     = null
}

variable "object_lock_retain_until_date" {
  description = "Date and time (RFC3339) until which the object lock applies"
  type        = string
  default     = null
}

variable "object_lock_legal_hold_status" {
  description = "Legal hold status. `ON` or `OFF`."
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Whether to allow the object to be deleted by removing any legal hold and adjusting retention"
  type        = bool
  default     = false
}

################################################################################
# S3 Object Copy
################################################################################

variable "create_object_copy" {
  description = "Whether to create an S3 object copy"
  type        = bool
  default     = false
}

variable "copy_source" {
  description = "Source object for the copy in the format `bucket/key`"
  type        = string
  default     = null
}

variable "copy_grant" {
  description = "ACL grant configuration for the copied object"
  type = list(object({
    email       = optional(string)
    id          = optional(string)
    permissions = list(string)
    type        = string
    uri         = optional(string)
  }))
  default = []
}

variable "copy_metadata_directive" {
  description = "Whether to COPY or REPLACE metadata from the source object"
  type        = string
  default     = "COPY"
}

################################################################################
# Bucket Notification
################################################################################

variable "create_bucket_notification" {
  description = "Whether to create bucket notification configuration"
  type        = bool
  default     = false
}

variable "notification_bucket" {
  description = "Name of the bucket for notification configuration. Defaults to `var.bucket`."
  type        = string
  default     = null
}

variable "notification_eventbridge" {
  description = "Whether to enable EventBridge notifications"
  type        = bool
  default     = false
}

variable "notification_lambda_functions" {
  description = "Map of Lambda function notification configurations"
  type = map(object({
    lambda_function_arn = string
    events              = list(string)
    filter_prefix       = optional(string)
    filter_suffix       = optional(string)
  }))
  default = {}
}

variable "notification_queues" {
  description = "Map of SQS queue notification configurations"
  type = map(object({
    queue_arn     = string
    events        = list(string)
    filter_prefix = optional(string)
    filter_suffix = optional(string)
  }))
  default = {}
}

variable "notification_topics" {
  description = "Map of SNS topic notification configurations"
  type = map(object({
    topic_arn     = string
    events        = list(string)
    filter_prefix = optional(string)
    filter_suffix = optional(string)
  }))
  default = {}
}
