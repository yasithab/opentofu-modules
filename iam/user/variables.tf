variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}


variable "name" {
  description = "The name of the IAM user."
  type        = string

  validation {
    condition     = length(var.name) > 0
    error_message = "The name must not be empty."
  }
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "path" {
  description = "Path in which to create the user."
  type        = string
  default     = "/"

  validation {
    condition     = can(regex("^/", var.path))
    error_message = "The path must begin with '/'."
  }
}

variable "permissions_boundary" {
  description = "The ARN of the policy that is used to set the permissions boundary for the user."
  type        = string
  default     = null

  validation {
    condition     = var.permissions_boundary == null || can(regex("^arn:", var.permissions_boundary))
    error_message = "The permissions_boundary must be null or a valid ARN starting with 'arn:'."
  }
}

variable "force_destroy" {
  description = "When destroying this user, destroy even if it has non-OpenTofu-managed IAM access keys, login profile, or MFA devices."
  type        = bool
  default     = false
}

# --- Login Profile (Console Access) ---

variable "create_login_profile" {
  description = "Whether to create an IAM user login profile (console access)."
  type        = bool
  default     = false
}

variable "password_length" {
  description = "The length of the generated password on resource creation."
  type        = number
  default     = 20

  validation {
    condition     = var.password_length >= 8 && var.password_length <= 128
    error_message = "The password_length must be between 8 and 128."
  }
}

variable "password_reset_required" {
  description = "Whether the user should be forced to reset the generated password on resource creation."
  type        = bool
  default     = true
}

variable "pgp_key" {
  description = "A PGP key (base-64 encoded) or a Keybase username in the form keybase:username. Used to encrypt the password and access key secret."
  type        = string
  default     = null
}

# --- Access Key (Programmatic Access) ---

variable "create_access_key" {
  description = "Whether to create an IAM access key for the user."
  type        = bool
  default     = false
}

variable "access_key_status" {
  description = "Access key status. Active or Inactive."
  type        = string
  default     = "Active"

  validation {
    condition     = contains(["Active", "Inactive"], var.access_key_status)
    error_message = "The access_key_status must be 'Active' or 'Inactive'."
  }
}

# --- Policy Attachments ---

variable "managed_policy_arns" {
  description = "Set of managed policy ARNs to attach to the user."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for arn in var.managed_policy_arns : can(regex("^arn:", arn))])
    error_message = "Each managed_policy_arns entry must be a valid ARN starting with 'arn:'."
  }
}

variable "inline_policies" {
  description = "Map of inline policy names to their JSON policy documents."
  type        = map(string)
  default     = {}
}

# --- Group Membership ---

variable "groups" {
  description = "Set of IAM group names to add the user to."
  type        = set(string)
  default     = []
}

# --- SSH Public Key ---

variable "ssh_public_key" {
  description = "SSH public key (for CodeCommit). Must be encoded in SSH authorized_keys format."
  type        = string
  default     = null
}

variable "ssh_key_encoding" {
  description = "The public key encoding format. Valid values are SSH and PEM."
  type        = string
  default     = "SSH"

  validation {
    condition     = contains(["SSH", "PEM"], var.ssh_key_encoding)
    error_message = "The ssh_key_encoding must be 'SSH' or 'PEM'."
  }
}

variable "ssh_key_status" {
  description = "The status of the SSH public key. Active or Inactive."
  type        = string
  default     = "Active"

  validation {
    condition     = contains(["Active", "Inactive"], var.ssh_key_status)
    error_message = "The ssh_key_status must be 'Active' or 'Inactive'."
  }
}

# --- Virtual MFA Device ---

variable "create_virtual_mfa_device" {
  description = "Whether to create a virtual MFA device for the user."
  type        = bool
  default     = false
}

variable "virtual_mfa_device_path" {
  description = "The path for the virtual MFA device."
  type        = string
  default     = "/"

  validation {
    condition     = can(regex("^/", var.virtual_mfa_device_path))
    error_message = "The virtual_mfa_device_path must begin with '/'."
  }
}
