variable "enabled" {
  description = "Controls if Athena resources are created"
  type        = bool
  default     = true
}


variable "name" {
  description = "Name of the Athena workgroup"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Workgroup
################################################################################

variable "workgroup_description" {
  description = "Description of the Athena workgroup"
  type        = string
  default     = null
}

variable "workgroup_state" {
  description = "State of the workgroup. Valid values are ENABLED or DISABLED"
  type        = string
  default     = "ENABLED"

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.workgroup_state)
    error_message = "workgroup_state must be either ENABLED or DISABLED."
  }
}

variable "force_destroy" {
  description = "Whether to force destroy the workgroup and its named queries"
  type        = bool
  default     = false
}

variable "enforce_workgroup_configuration" {
  description = "Whether users must use workgroup settings when running queries. Enforces security and cost controls"
  type        = bool
  default     = true
}

variable "publish_cloudwatch_metrics_enabled" {
  description = "Whether CloudWatch metrics are enabled for the workgroup"
  type        = bool
  default     = true
}

variable "bytes_scanned_cutoff_per_query" {
  description = "Maximum number of bytes scanned per query. Queries exceeding this limit are cancelled. Set to control costs"
  type        = number
  default     = null
}

variable "requester_pays_enabled" {
  description = "Whether requester pays is enabled for the workgroup. If enabled, the requester pays for data access charges"
  type        = bool
  default     = false
}

variable "execution_role" {
  description = "IAM role ARN used to access the user's resources while running the query"
  type        = string
  default     = null
}

variable "engine_version" {
  description = "The Athena engine version for running queries (e.g., 'Athena engine version 3')"
  type        = string
  default     = null
}

################################################################################
# Result Configuration
################################################################################

variable "result_output_location" {
  description = "S3 location for Athena query results (e.g., 's3://bucket-name/prefix/')"
  type        = string
  default     = null
}

variable "result_encryption_option" {
  description = "Encryption method for query results. Valid values: SSE_S3, SSE_KMS, CSE_KMS"
  type        = string
  default     = "SSE_S3"

  validation {
    condition     = var.result_encryption_option == null || contains(["SSE_S3", "SSE_KMS", "CSE_KMS"], var.result_encryption_option)
    error_message = "result_encryption_option must be SSE_S3, SSE_KMS, or CSE_KMS."
  }
}

variable "result_encryption_kms_key_arn" {
  description = "KMS key ARN used to encrypt query results. Required when encryption_option is SSE_KMS or CSE_KMS"
  type        = string
  default     = null
}

variable "result_acl_s3_owner" {
  description = "S3 ACL option for query results. Valid value: BUCKET_OWNER_FULL_CONTROL"
  type        = string
  default     = null
}

variable "result_expected_bucket_owner" {
  description = "Expected owner of the S3 results bucket (AWS account ID)"
  type        = string
  default     = null
}

################################################################################
# Named Queries
################################################################################

variable "named_queries" {
  description = "Map of named queries to create. Each key is the query name. Values must include 'database' and 'query', optionally 'description'"
  type = map(object({
    database    = string
    query       = string
    description = optional(string)
  }))
  default = {}
}

################################################################################
# Data Catalogs
################################################################################

variable "data_catalogs" {
  description = "Map of data catalogs to create. Each key is the catalog name. Values must include 'type' (LAMBDA, GLUE, HIVE) and 'parameters'"
  type = map(object({
    description = optional(string)
    type        = string
    parameters  = map(string)
  }))
  default = {}
}

################################################################################
# Databases
################################################################################

variable "databases" {
  description = "Map of Athena databases to create. Each key is the database name. Supports optional bucket, comment, encryption, and ACL settings"
  type        = any
  default     = {}
}
