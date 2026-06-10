variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}


variable "name" {
  description = "Name of the Timestream database."
  type        = string

  validation {
    condition     = length(var.name) > 0
    error_message = "The name must not be empty."
  }
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Database
################################################################################

variable "kms_key_id" {
  description = "ARN of the KMS key used to encrypt data in the Timestream database. If null, the default AWS-managed key is used."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_id == null || can(regex("^arn:", var.kms_key_id))
    error_message = "The kms_key_id must be a valid ARN starting with 'arn:'."
  }
}

################################################################################
# Tables
################################################################################

variable "tables" {
  description = "Map of Timestream table configurations. Each entry creates a table with retention policies and optional schema/magnetic store settings."
  type = map(object({
    table_name                    = string
    memory_store_retention_hours  = optional(number)
    magnetic_store_retention_days = optional(number)
    magnetic_store_write_properties = optional(object({
      enable_magnetic_store_writes = optional(bool, true)
      magnetic_store_rejected_data_location = optional(object({
        s3_bucket_name       = optional(string)
        s3_encryption_option = optional(string)
        s3_kms_key_id        = optional(string)
        s3_object_key_prefix = optional(string)
      }))
    }))
    schema = optional(object({
      composite_partition_key = optional(object({
        enforcement_in_record = optional(string)
        name                  = optional(string)
        type                  = optional(string, "DIMENSION")
      }))
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "default_memory_store_retention_hours" {
  description = "Default number of hours data is retained in the memory store before being moved to magnetic store."
  type        = number
  default     = 24

  validation {
    condition     = var.default_memory_store_retention_hours >= 1
    error_message = "The default_memory_store_retention_hours must be at least 1."
  }
}

variable "default_magnetic_store_retention_days" {
  description = "Default number of days data is retained in the magnetic store. Defaults to 365; raise it explicitly for longer retention (max 73000)."
  type        = number
  default     = 365

  validation {
    condition     = var.default_magnetic_store_retention_days >= 1
    error_message = "The default_magnetic_store_retention_days must be at least 1."
  }
}

variable "enable_magnetic_store_writes" {
  description = "Whether to enable magnetic store writes by default for tables that do not specify their own magnetic_store_write_properties."
  type        = bool
  default     = false
}
