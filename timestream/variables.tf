variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "region" {
  description = "AWS region override. If null, the provider default region is used."
  type        = string
  default     = null
}

variable "name" {
  description = "Name of the Timestream database."
  type        = string
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
}

################################################################################
# Tables
################################################################################

variable "tables" {
  description = "Map of Timestream table configurations. Each entry creates a table with retention policies and optional schema/magnetic store settings."
  type        = any
  default     = {}
}

variable "default_memory_store_retention_hours" {
  description = "Default number of hours data is retained in the memory store before being moved to magnetic store."
  type        = number
  default     = 24
}

variable "default_magnetic_store_retention_days" {
  description = "Default number of days data is retained in the magnetic store."
  type        = number
  default     = 73000
}

variable "enable_magnetic_store_writes" {
  description = "Whether to enable magnetic store writes by default for tables that do not specify their own magnetic_store_write_properties."
  type        = bool
  default     = false
}
