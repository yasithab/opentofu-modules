variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "region" {
  description = "AWS region. If specified, overrides the provider's default region."
  type        = string
  default     = null
}

variable "name" {
  description = "The name of the IAM user."
  type        = string
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
}

variable "permissions_boundary" {
  description = "The ARN of the policy that is used to set the permissions boundary for the user."
  type        = string
  default     = null
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
}

# --- Policy Attachments ---

variable "managed_policy_arns" {
  description = "Set of managed policy ARNs to attach to the user."
  type        = set(string)
  default     = []
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
}

variable "ssh_key_status" {
  description = "The status of the SSH public key. Active or Inactive."
  type        = string
  default     = "Active"
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
}
