variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}


variable "name" {
  description = "Name used for the CUR report and as a default for related resources."
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Report Definition
################################################################################

variable "report_name" {
  description = "Name of the Cost and Usage Report. If null, uses var.name."
  type        = string
  default     = null
}

variable "time_unit" {
  description = "The frequency at which report data is measured and displayed. Valid values: HOURLY, DAILY, MONTHLY."
  type        = string
  default     = "DAILY"

  validation {
    condition     = contains(["HOURLY", "DAILY", "MONTHLY"], var.time_unit)
    error_message = "time_unit must be one of: HOURLY, DAILY, MONTHLY."
  }
}

variable "format" {
  description = "The format for the report. Valid values: textORcsv, Parquet."
  type        = string
  default     = "Parquet"

  validation {
    condition     = contains(["textORcsv", "Parquet"], var.format)
    error_message = "format must be one of: textORcsv, Parquet."
  }
}

variable "compression" {
  description = "Compression format for the report. Valid values: ZIP, GZIP, Parquet."
  type        = string
  default     = "Parquet"

  validation {
    condition     = contains(["ZIP", "GZIP", "Parquet"], var.compression)
    error_message = "compression must be one of: ZIP, GZIP, Parquet."
  }
}

variable "additional_schema_elements" {
  description = "List of additional schema elements. Valid values: RESOURCES, SPLIT_COST_ALLOCATION_DATA."
  type        = list(string)
  default     = ["RESOURCES"]
}

variable "additional_artifacts" {
  description = "List of additional artifacts. Valid values: REDSHIFT, QUICKSIGHT, ATHENA."
  type        = list(string)
  default     = ["ATHENA"]
}

variable "refresh_closed_reports" {
  description = "Whether AWS updates the report after it has been finalized if AWS applies refunds, credits, or support fees to the account."
  type        = bool
  default     = true
}

variable "report_versioning" {
  description = "Whether to overwrite previous report versions or create new versions. Valid values: CREATE_NEW_REPORT, OVERWRITE_REPORT."
  type        = string
  default     = "OVERWRITE_REPORT"

  validation {
    condition     = contains(["CREATE_NEW_REPORT", "OVERWRITE_REPORT"], var.report_versioning)
    error_message = "report_versioning must be one of: CREATE_NEW_REPORT, OVERWRITE_REPORT."
  }
}

################################################################################
# S3 Bucket
################################################################################

variable "create_s3_bucket" {
  description = "Whether to create an S3 bucket for report delivery."
  type        = bool
  default     = true
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for CUR delivery. Required when create_s3_bucket is false."
  type        = string
}

variable "s3_region" {
  description = "The region of the S3 bucket for CUR delivery."
  type        = string
  default     = "us-east-1"
}

variable "s3_prefix" {
  description = "S3 key prefix for the report delivery location."
  type        = string
  default     = "cur/"
}

variable "s3_bucket_force_destroy" {
  description = "Whether to force destroy the S3 bucket when removing the module (deletes all objects)."
  type        = bool
  default     = false
}

variable "s3_sse_algorithm" {
  description = "Server-side encryption algorithm for the S3 bucket. Valid values: aws:kms, AES256."
  type        = string
  default     = "AES256"
}

variable "s3_kms_key_id" {
  description = "ARN of the KMS key to use for S3 bucket encryption. Only used when s3_sse_algorithm is aws:kms."
  type        = string
  default     = null
}

variable "s3_bucket_key_enabled" {
  description = "Whether to use an S3 Bucket Key for SSE-KMS encryption."
  type        = bool
  default     = true
}

variable "create_s3_bucket_policy" {
  description = "Whether to create the S3 bucket policy allowing CUR service to write reports."
  type        = bool
  default     = true
}

variable "enable_s3_lifecycle" {
  description = "Whether to enable S3 lifecycle rules for transitioning and expiring report data."
  type        = bool
  default     = false
}

variable "s3_lifecycle_glacier_transition_days" {
  description = "Number of days before transitioning report objects to Glacier storage."
  type        = number
  default     = 365
}

variable "s3_lifecycle_expiration_days" {
  description = "Number of days before expiring (deleting) report objects."
  type        = number
  default     = 2555
}
