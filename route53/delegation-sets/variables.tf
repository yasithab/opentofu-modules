variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "delegation_sets" {
  description = "Map of Route53 delegation set parameters"
  type = map(object({
    reference_name = optional(string)
  }))
  default = {}
}
