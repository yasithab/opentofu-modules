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

################################################################################
# Prefix Lists
################################################################################

variable "prefix_lists" {
  description = "Map of prefix list configurations. Each entry in cidr_list must be an object with a 'cidr' key (required) and optional 'description' key."
  type = map(object({
    name           = string
    cidr_list      = list(object({ cidr = string, description = optional(string) }))
    address_family = optional(string, "IPv4")
    tags           = optional(map(string), {})
  }))
  default = null
}

################################################################################
# Resource Access Manager
################################################################################

variable "enable_ram_share" {
  description = "Whether to enable RAM sharing for prefix lists"
  type        = bool
  default     = false
}

variable "ram_allow_external_principals" {
  description = "Indicates whether principals outside your organization can be associated with a resource share"
  type        = bool
  default     = false
}

variable "ram_permission_arns" {
  description = "Specifies the ARNs of the RAM permissions to associate with the resource share. If not specified, RAM automatically attaches the default version of the permission for each resource type."
  type        = list(string)
  default     = null
}

variable "ram_principals" {
  description = "A list of principals to share prefix lists with"
  type        = set(string)
  default     = []
}

variable "ram_tags" {
  description = "Additional tags for the RAM resource share"
  type        = map(string)
  default     = {}
}


################################################################################
