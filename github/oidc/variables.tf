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

variable "openid_providers" {
  description = "Map of OpenID Connect Providers"
  type = map(object({
    url             = string
    client_id_list  = list(string)
    thumbprint_list = optional(list(string), [])
    tags            = optional(map(string), {})
  }))
  default = {}
}
