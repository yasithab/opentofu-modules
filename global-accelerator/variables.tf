variable "enabled" {
  description = "Whether to create the Global Accelerator resources."
  type        = bool
  default     = true
}

variable "region" {
  description = "AWS region override. Uses provider region when null."
  type        = string
  default     = null
}

variable "name" {
  description = "Name of the Global Accelerator."
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
# Accelerator
################################################################################

variable "ip_address_type" {
  description = "IP address type for the accelerator. Valid values: `IPV4`, `DUAL_STACK`."
  type        = string
  default     = "IPV4"

  validation {
    condition     = contains(["IPV4", "DUAL_STACK"], var.ip_address_type)
    error_message = "The ip_address_type must be 'IPV4' or 'DUAL_STACK'."
  }
}

variable "ip_addresses" {
  description = "List of IP addresses to use as static addresses for the accelerator. Up to 2 addresses."
  type        = list(string)
  default     = null
}

variable "accelerator_enabled" {
  description = "Whether the accelerator is enabled. Even when disabled, it still incurs charges."
  type        = bool
  default     = true
}

################################################################################
# Flow Logs
################################################################################

variable "flow_logs_enabled" {
  description = "Whether flow logs are enabled for the accelerator."
  type        = bool
  default     = true
}

variable "flow_logs_s3_bucket" {
  description = "S3 bucket name for storing flow logs."
  type        = string
  default     = null
}

variable "flow_logs_s3_prefix" {
  description = "S3 key prefix for flow log objects."
  type        = string
  default     = null
}

################################################################################
# Standard Listeners
################################################################################

variable "listeners" {
  description = "Map of listener configurations. Each listener defines port ranges and protocol."
  type        = any
  default     = {}
}

################################################################################
# Endpoint Groups
################################################################################

variable "endpoint_groups" {
  description = "Map of endpoint group configurations including health checks and endpoint configurations."
  type        = any
  default     = {}
}

################################################################################
# Custom Routing
################################################################################

variable "create_custom_routing_accelerator" {
  description = "Whether to create a custom routing accelerator instead of a standard accelerator."
  type        = bool
  default     = false
}

variable "custom_routing_listeners" {
  description = "Map of custom routing listener configurations."
  type        = any
  default     = {}
}

variable "custom_routing_endpoint_groups" {
  description = "Map of custom routing endpoint group configurations with destination configurations."
  type        = any
  default     = {}
}

################################################################################
# Cross-Account Attachments
################################################################################

variable "cross_account_attachments" {
  description = "Map of cross-account attachment configurations for sharing endpoints across AWS accounts."
  type        = any
  default     = {}
}
