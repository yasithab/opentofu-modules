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

###############################################################################################################
# Security group
###############################################################################################################

variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "security_group_id" {
  description = "ID of an existing security group whose rules this module will manage. When set, no security group is created"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "ID of the VPC where to create security group"
  type        = string
  default     = null

  validation {
    condition     = var.vpc_id == null || can(regex("^vpc-", var.vpc_id))
    error_message = "The vpc_id must start with 'vpc-'."
  }
}

variable "use_name_prefix" {
  description = "Whether to use name_prefix or fixed name. Should be true to be able to update the security group name after initial creation"
  type        = bool
  default     = true
}

variable "description" {
  description = "Description of security group. Note: changing the description of an existing security group forces replacement"
  type        = string
  default     = "Security Group managed by OpenTofu"
}

variable "revoke_rules_on_delete" {
  description = "Instruct OpenTofu to revoke all of the security group's attached ingress and egress rules before deleting the group itself. Enable for EMR."
  type        = bool
  default     = false
}

variable "create_timeout" {
  description = "Time to wait for a security group to be created"
  type        = string
  default     = "10m"
}

variable "delete_timeout" {
  description = "Time to wait for a security group to be deleted"
  type        = string
  default     = "15m"
}

###############################################################################################################
# Rules
###############################################################################################################

variable "ingress_rules" {
  description = <<-EOT
    Map of ingress rules keyed by a user-chosen rule name. Each rule fans out to one
    aws_vpc_security_group_ingress_rule per source (per IPv4 CIDR, per IPv6 CIDR, per prefix
    list ID, one for the referenced security group, and one for self). Every rule must define
    at least one source. When ip_protocol is "-1" ports are ignored; otherwise from_port and
    to_port are required.
  EOT
  type = map(object({
    from_port                    = optional(number)
    to_port                      = optional(number)
    ip_protocol                  = optional(string, "tcp")
    description                  = optional(string)
    cidr_ipv4                    = optional(list(string), [])
    cidr_ipv6                    = optional(list(string), [])
    prefix_list_ids              = optional(list(string), [])
    referenced_security_group_id = optional(string)
    self                         = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, rule in var.ingress_rules :
      length(rule.cidr_ipv4) + length(rule.cidr_ipv6) + length(rule.prefix_list_ids) > 0 || rule.referenced_security_group_id != null || rule.self
    ])
    error_message = "Each ingress rule must define at least one source: cidr_ipv4, cidr_ipv6, prefix_list_ids, referenced_security_group_id or self = true."
  }

  validation {
    condition = alltrue([
      for name, rule in var.ingress_rules :
      tostring(rule.ip_protocol) == "-1" || (rule.from_port != null && rule.to_port != null)
    ])
    error_message = "Each ingress rule must set from_port and to_port unless ip_protocol is \"-1\" (all traffic)."
  }
}

variable "egress_rules" {
  description = <<-EOT
    Map of egress rules keyed by a user-chosen rule name. Each rule fans out to one
    aws_vpc_security_group_egress_rule per source (per IPv4 CIDR, per IPv6 CIDR, per prefix
    list ID, one for the referenced security group, and one for self). Every rule must define
    at least one source. When ip_protocol is "-1" ports are ignored; otherwise from_port and
    to_port are required. No egress is opened implicitly - open egress must be opted into
    explicitly.
  EOT
  type = map(object({
    from_port                    = optional(number)
    to_port                      = optional(number)
    ip_protocol                  = optional(string, "tcp")
    description                  = optional(string)
    cidr_ipv4                    = optional(list(string), [])
    cidr_ipv6                    = optional(list(string), [])
    prefix_list_ids              = optional(list(string), [])
    referenced_security_group_id = optional(string)
    self                         = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, rule in var.egress_rules :
      length(rule.cidr_ipv4) + length(rule.cidr_ipv6) + length(rule.prefix_list_ids) > 0 || rule.referenced_security_group_id != null || rule.self
    ])
    error_message = "Each egress rule must define at least one source: cidr_ipv4, cidr_ipv6, prefix_list_ids, referenced_security_group_id or self = true."
  }

  validation {
    condition = alltrue([
      for name, rule in var.egress_rules :
      tostring(rule.ip_protocol) == "-1" || (rule.from_port != null && rule.to_port != null)
    ])
    error_message = "Each egress rule must set from_port and to_port unless ip_protocol is \"-1\" (all traffic)."
  }
}
