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

variable "ram_resource_share_name" {
  type        = string
  description = "(Required) The name of the resource share"
  nullable    = false

  validation {
    condition     = length(var.ram_resource_share_name) > 0
    error_message = "The ram_resource_share_name must not be empty."
  }
}

variable "ram_resource_arn" {
  type        = string
  description = "(Required) Amazon Resource Name (ARN) of the resource to associate with the RAM Resource Share"
  nullable    = false

  validation {
    condition     = can(regex("^arn:", var.ram_resource_arn))
    error_message = "The ram_resource_arn must be a valid ARN starting with 'arn:'."
  }
}

variable "ram_principals" {
  type        = list(string)
  default     = []
  description = <<-EOT
    A list of principals to associate with the resource share. Possible values
    are:

    * AWS account ID
    * Organization ARN
    * Organization Unit ARN

    If this is not provided and
    `ram_resource_share_enabled` is `true`, the Organization ARN will be used.
  EOT
}

variable "allow_external_principals" {
  type        = bool
  default     = false
  description = "Indicates whether principals outside your organization can be associated with a resource share"
}

variable "permission_arns" {
  type        = list(string)
  default     = []
  description = "Specifies the Amazon Resource Names (ARNs) of the RAM permission to associate with the resource share. If you do not specify an ARN for the permission, RAM automatically attaches the default version of the permission for each resource type. You can associate only one permission with each resource type included in the resource share."
}

variable "enable_sharing_with_organization" {
  type        = bool
  default     = false
  description = "Whether to enable sharing resources with AWS Organizations. When enabled, allows principals within the organization to access shared resources without individual invitations"
}

