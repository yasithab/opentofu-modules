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

################################################################################
# VPC Attachment
################################################################################


variable "vpc_attachments" {
  description = "Map of VPC attachment configurations. Each entry requires tgw_id, vpc_id, and subnet_ids."
  type = map(object({
    tgw_id                                          = string
    vpc_id                                          = string
    subnet_ids                                      = list(string)
    dns_support                                     = optional(bool, true)
    ipv6_support                                    = optional(bool, false)
    appliance_mode_support                          = optional(bool, false)
    security_group_referencing_support              = optional(bool, false)
    transit_gateway_default_route_table_association = optional(bool, true)
    transit_gateway_default_route_table_propagation = optional(bool, true)
    tags                                            = optional(map(string), {})
  }))
  default = {}
}
