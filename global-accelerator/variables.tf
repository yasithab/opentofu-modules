variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
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
  default     = false

  validation {
    condition     = !var.flow_logs_enabled || var.flow_logs_s3_bucket != null
    error_message = "flow_logs_s3_bucket must be set when flow_logs_enabled is true."
  }
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
  type = map(object({
    client_affinity = optional(string, "NONE")
    protocol        = optional(string, "TCP")
    port_ranges = optional(list(object({
      from_port = number
      to_port   = optional(number)
    })), [{ from_port = 80, to_port = 80 }])
  }))
  default = {}
}

################################################################################
# Endpoint Groups
################################################################################

variable "endpoint_groups" {
  description = "Map of endpoint group configurations including health checks and endpoint configurations."
  type = map(object({
    listener_key                  = optional(string)
    listener_arn                  = optional(string)
    endpoint_group_region         = optional(string)
    health_check_interval_seconds = optional(number, 30)
    health_check_path             = optional(string, "/")
    health_check_port             = optional(number, 80)
    health_check_protocol         = optional(string, "HTTP")
    threshold_count               = optional(number, 3)
    traffic_dial_percentage       = optional(number, 100)
    endpoint_configurations = optional(list(object({
      client_ip_preservation_enabled = optional(bool, true)
      endpoint_id                    = string
      weight                         = optional(number, 128)
    })), [])
    port_overrides = optional(list(object({
      endpoint_port = number
      listener_port = number
    })), [])
  }))
  default = {}
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
  type = map(object({
    port_ranges = optional(list(object({
      from_port = number
      to_port   = optional(number)
    })), [{ from_port = 80, to_port = 80 }])
  }))
  default = {}
}

variable "custom_routing_endpoint_groups" {
  description = "Map of custom routing endpoint group configurations with destination configurations."
  type = map(object({
    listener_key          = optional(string)
    listener_arn          = optional(string)
    endpoint_group_region = optional(string)
    destination_configurations = optional(list(object({
      from_port = number
      to_port   = number
      protocols = list(string)
    })), [])
    endpoint_configurations = optional(list(object({
      endpoint_id = string
    })), [])
  }))
  default = {}
}

################################################################################
# Cross-Account Attachments
################################################################################

variable "cross_account_attachments" {
  description = "Map of cross-account attachment configurations for sharing endpoints across AWS accounts."
  type = map(object({
    name       = string
    principals = optional(list(string), [])
    resources = optional(list(object({
      endpoint_id = string
      region      = optional(string)
    })), [])
  }))
  default = {}
}
