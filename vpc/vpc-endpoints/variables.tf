variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}


variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "The ID of the VPC in which the endpoint will be used"
  type        = string
  default     = null

  validation {
    condition     = var.vpc_id == null || can(regex("^vpc-", var.vpc_id))
    error_message = "The vpc_id must start with 'vpc-'."
  }
}

variable "endpoints" {
  description = "A map of interface and/or gateway endpoints containing their properties and configurations"
  type = map(object({
    create                     = optional(bool, true)
    service                    = optional(string)
    service_name               = optional(string)
    service_endpoint           = optional(string)
    service_region             = optional(string)
    service_type               = optional(string, "Interface")
    auto_accept                = optional(bool)
    resource_configuration_arn = optional(string)
    service_network_arn        = optional(string)
    security_group_ids         = optional(list(string), [])
    subnet_ids                 = optional(list(string), [])
    route_table_ids            = optional(list(string))
    policy                     = optional(string)
    private_dns_enabled        = optional(bool)
    ip_address_type            = optional(string)
    dns_options = optional(object({
      dns_record_ip_type                             = optional(string)
      private_dns_only_for_inbound_resolver_endpoint = optional(bool)
      private_dns_preference                         = optional(string)
      private_dns_specified_domains                  = optional(list(string))
    }))
    subnet_configuration = optional(list(object({
      ipv4      = optional(string)
      ipv6      = optional(string)
      subnet_id = string
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "security_group_ids" {
  description = "Default security group IDs to associate with the VPC endpoints"
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "Default subnets IDs to associate with the VPC endpoints"
  type        = list(string)
  default     = []
}

variable "timeouts" {
  description = "Define maximum timeout for creating, updating, and deleting VPC endpoint resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Security Group
################################################################################

variable "create_security_group" {
  description = "Determines if a security group is created"
  type        = bool
  default     = false
}

variable "security_group_name" {
  description = "Name to use on security group created. Conflicts with `security_group_name_prefix`"
  type        = string
  default     = null
}

variable "security_group_name_prefix" {
  description = "Name prefix to use on security group created. Conflicts with `security_group_name`"
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "Description of the security group created"
  type        = string
  default     = null
}

variable "security_group_rules" {
  description = "Security group rules to add to the security group created"
  type = map(object({
    type                         = optional(string, "ingress")
    ip_protocol                  = optional(string, "tcp")
    from_port                    = optional(number)
    to_port                      = optional(number)
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    description                  = optional(string)
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
    tags                         = optional(map(string), {})
  }))
  default = {}
}

variable "security_group_tags" {
  description = "A map of additional tags to add to the security group created"
  type        = map(string)
  default     = {}
}
