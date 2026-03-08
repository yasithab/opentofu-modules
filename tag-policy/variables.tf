

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

variable "description" {
  default     = null
  description = "Description of the tag policy"
  type        = string
}

variable "attach_ous" {
  type        = list(string)
  description = "List of OU IDs to attach the tag policies to"
  default     = []

  validation {
    condition     = var.attach_to_org || length(var.attach_ous) > 0
    error_message = "attach_ous must have at least one OU if attach_to_org is false."
  }

  validation {
    condition     = var.attach_to_org || length([for ou in var.attach_ous : ou if can(regex("^ou-[0-9a-z]+-[0-9a-z]+$", ou))]) == length(var.attach_ous)
    error_message = "Each OU ID must match the pattern 'ou-' followed by alphanumeric characters with an optional hyphen."
  }
}

variable "attach_to_org" {
  default     = false
  description = "Whether to attach the tag policy to the organization (set to false if you want to attach to OUs)"
  type        = bool
}

variable "skip_destroy" {
  description = "If set to true, the policy will not be deleted when the resource is destroyed. This is useful to prevent accidental deletion of tag policies attached to the organization."
  type        = bool
  default     = false
}

variable "tag_policy" {
  description = "List of tag policies to create"
  type = map(object({
    enforced_for                                      = optional(list(string), [])
    enforced_for_operator                             = optional(string)
    enforced_for_operators_allowed_for_child_policies = optional(list(string))
    tag_key                                           = string
    tag_key_operator                                  = optional(string)
    tag_key_operators_allowed_for_child_policies      = optional(list(string))
    values                                            = optional(list(string))
    values_operator                                   = optional(string)
    values_operators_allowed_for_child_policies       = optional(list(string))
  }))
  default = {}

  validation {
    condition     = length(var.tag_policy) > 0
    error_message = "At least one tag policy must be specified."
  }

  # Validate enforced_for contains valid service:resource format
  validation {
    condition = alltrue([
      for policy in values(var.tag_policy) :
      (policy.enforced_for != null) && (
        length(coalesce(policy.enforced_for, [])) == 0 ||
        alltrue([
          for target in coalesce(policy.enforced_for, []) :
          can(regex("^[a-zA-Z0-9\\-]+:[a-zA-Z0-9\\-/]*[a-zA-Z0-9*]$", target))
        ])
      )
    ])
    error_message = "Invalid 'enforced_for': must be an empty list or contain valid 'service:resource' targets."
  }

  # Validate tag key is not empty
  validation {
    condition = alltrue([
      for policy in values(var.tag_policy) :
      length(trimspace(policy.tag_key)) > 0
    ])
    error_message = "Tag key must be a non-empty string."
  }
}
