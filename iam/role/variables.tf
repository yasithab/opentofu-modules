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

variable "name" {
  description = "IAM role name"
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "IAM role name prefix"
  type        = string
  default     = null
}

variable "principals" {
  type        = any
  description = <<-EOT
    Map of principal type (e.g. `AWS`, `Service`, `Federated`) to either:
      - a list of identifiers (legacy shape), e.g. `{ Service = ["ec2.amazonaws.com"] }`, or
      - an object `{ identifiers = list(string), conditions = optional(list(object({ test, variable, values }))) }`
        where `conditions` apply only to that principal's assume-role statement.
    Global `assume_role_conditions` apply to all principal statements.
  EOT
  default     = {}

  validation {
    condition     = !var.enabled || length(var.principals) > 0
    error_message = "`principals` must contain at least one principal type when `enabled` is true; the role's assume-role policy cannot be empty."
  }

  validation {
    condition = alltrue([
      for type, principal in var.principals :
      can(tolist(principal)) || can(tolist(principal.identifiers))
    ])
    error_message = "Each `principals` value must be a list of identifier strings or an object with `identifiers` (list(string)) and optional `conditions`."
  }
}

variable "policy_documents" {
  type        = list(string)
  description = "List of JSON IAM policy documents. When non-empty, an IAM policy is created from the merged documents and attached to the role"
  default     = []
}

variable "managed_policy_arns" {
  type        = set(string)
  description = "List of managed policies to attach to created role"
  default     = []
}

variable "max_session_duration" {
  type        = number
  default     = 3600
  description = "The maximum session duration (in seconds) for the role. Can have a value from 1 hour to 12 hours"

  validation {
    condition     = var.max_session_duration == null || (var.max_session_duration >= 3600 && var.max_session_duration <= 43200)
    error_message = "max_session_duration must be between 3600 (1 hour) and 43200 (12 hours) seconds."
  }
}

variable "permissions_boundary" {
  type        = string
  default     = null
  description = "ARN of the policy that is used to set the permissions boundary for the role"
}

variable "role_description" {
  type        = string
  description = "The description of the IAM role that is visible in the IAM role manager"
}

variable "policy_name" {
  type        = string
  description = "The name of the IAM policy that is visible in the IAM policy manager"
  default     = null
}

variable "policy_name_prefix" {
  type        = string
  description = "The name prefix of the IAM policy that is visible in the IAM policy manager"
  default     = null
}

variable "policy_description" {
  type        = string
  default     = null
  description = "The description of the IAM policy that is visible in the IAM policy manager"
}

variable "assume_role_actions" {
  type        = list(string)
  default     = ["sts:AssumeRole", "sts:TagSession"]
  description = "The IAM action to be granted by the AssumeRole policy"
}

variable "assume_role_conditions" {
  type = list(object({
    test     = string
    variable = string
    values   = list(string)
  }))
  description = "List of conditions for the assume role policy"
  default     = []
}

variable "instance_profile_enabled" {
  type        = bool
  default     = false
  description = "Create EC2 Instance Profile for the role"
}

variable "instance_profile_name" {
  description = "EC2 Instance Profile name"
  type        = string
  default     = null
}

variable "instance_profile_name_prefix" {
  description = "EC2 Instance Profile name prefix"
  type        = string
  default     = null
}

variable "path" {
  type        = string
  description = "Path to the role and policy. See [IAM Identifiers](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html) for more information."
  default     = "/"

  validation {
    condition     = can(regex("^/", var.path))
    error_message = "path must start with a forward slash (/)."
  }
}

variable "tags_enabled" {
  type        = bool
  description = "Enable/disable tags on IAM roles and policies"
  default     = true
}

variable "force_detach_policies" {
  type        = bool
  description = "Whether to force detaching any policies the role has before destroying it"
  default     = false
}

variable "policy_delay_after_creation_in_ms" {
  type        = number
  description = "Number of milliseconds to wait between creating the policy and setting its version as default. Only applies when policy_documents is non-empty."
  default     = null
}
