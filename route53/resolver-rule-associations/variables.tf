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
  description = "Default VPC ID for all the Route53 Resolver rule associations"
  type        = string
  default     = null
}

variable "resolver_rules" {
  description = "Map of Route53 Resolver rules to create"
  type = map(object({
    domain_name          = string
    rule_type            = string
    name                 = optional(string)
    resolver_endpoint_id = optional(string)
    target_ips = optional(list(object({
      ip       = optional(string)
      ipv6     = optional(string)
      port     = optional(number, 53)
      protocol = optional(string, "Do53")
    })), [])
  }))
  default = {}
}

variable "resolver_rule_associations" {
  description = "Map of Route53 Resolver rule associations parameters. Use resolver_rule_id to reference an existing rule, or the key must match a resolver_rules key to use a rule created by this module."
  type = map(object({
    name             = optional(string)
    vpc_id           = optional(string)
    resolver_rule_id = optional(string)
  }))
  default = {}
}
