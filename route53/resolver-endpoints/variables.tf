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

variable "protocols" {
  description = "The resolver endpoint protocols. Valid values are DoH, Do53, DoH-FIPS."
  type        = list(string)
  default     = ["Do53"]
  validation {
    condition     = length(var.protocols) == 0 || alltrue([for p in var.protocols : contains(["DoH", "Do53", "DoH-FIPS"], p)])
    error_message = "Valid protocols are: DoH, Do53, DoH-FIPS."
  }
}

variable "direction" {
  description = "The resolver endpoint flow direction. Valid values are INBOUND, OUTBOUND, or BIDIRECTIONAL."
  type        = string
  default     = "INBOUND"
  validation {
    condition     = contains(["INBOUND", "OUTBOUND", "BIDIRECTIONAL"], var.direction)
    error_message = "direction must be one of: INBOUND, OUTBOUND, BIDIRECTIONAL."
  }
}

variable "type" {
  description = "The resolver endpoint IP address type. Valid values are IPV4, IPV6, or DUALSTACK."
  type        = string
  default     = "IPV4"
  validation {
    condition     = contains(["IPV4", "IPV6", "DUALSTACK"], var.type)
    error_message = "type must be one of: IPV4, IPV6, DUALSTACK."
  }
}

variable "ip_addresses" {
  description = "A list of IP address configurations for the resolver endpoint. Each entry requires subnet_id and optionally ip (IPv4) or ipv6."
  type = list(object({
    subnet_id = string
    ip        = optional(string)
    ipv6      = optional(string)
  }))
  default = []
}

variable "security_group_ids" {
  description = "A list of security group IDs"
  type        = list(string)
  default     = []
}

# Security Group

variable "create_security_group" {
  description = "Whether to create Security Groups for Route53 Resolver Endpoints"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "The VPC ID for all the Route53 Resolver Endpoints"
  type        = string
  default     = null
}

variable "security_group_name" {
  description = "The name of the security group"
  type        = string
  default     = null
}

variable "security_group_name_prefix" {
  description = "The prefix of the security group"
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "The security group description"
  type        = string
  default     = null
}

variable "security_group_ingress_cidr_blocks" {
  description = "A list of CIDR blocks to allow on security group"
  type        = list(string)
  default     = []
}

variable "rni_enhanced_metrics_enabled" {
  description = "(Optional) Specifies whether Resolver Query Logging enhanced metrics are enabled for the resolver endpoint. Default is false."
  type        = bool
  default     = false
}

variable "target_name_server_metrics_enabled" {
  description = "(Optional) Specifies whether target name server metrics are enabled for outbound resolver endpoints. Default is false."
  type        = bool
  default     = false
}
