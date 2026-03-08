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

variable "repo_names" {
  description = "List of GitHub repository names"
  type        = list(string)
  default     = null
}

variable "github_organization_name" {
  description = "The GitHub organization name"
  type        = string
  default     = null
}

variable "github_oidc_arn" {
  description = "The GitHub openid connect provider arn"
  type        = string
  default     = null
}

variable "iam_policy_name" {
  description = "The name of the GitHub actions IAM policy"
  type        = string
  default     = null
}

variable "iam_policy_description" {
  description = "The description of the GitHub actions IAM policy"
  type        = string
  default     = "GitHub Actions Policy"
}

variable "iam_role_name" {
  description = "The name of the GitHub actions IAM role"
  type        = string
  default     = null
}

variable "iam_role_description" {
  description = "The description of the GitHub actions IAM role"
  type        = string
  default     = "GitHub Actions Role"
}

variable "iam_policy_document" {
  description = "The JSON formatted policy document"
  type        = any
  default     = null
}

variable "iam_role_path" {
  description = "Path for the IAM role"
  type        = string
  default     = "/"
}

variable "iam_role_max_session_duration" {
  description = "Maximum session duration (in seconds) for the IAM role. Value between 3600 and 43200."
  type        = number
  default     = 3600
}

variable "iam_role_permissions_boundary" {
  description = "ARN of the policy used as permissions boundary for the IAM role"
  type        = string
  default     = null
}

variable "iam_role_force_detach_policies" {
  description = "Whether to force-detach any policies the role has before destroying it"
  type        = bool
  default     = false
}

variable "iam_policy_path" {
  description = "Path for the IAM policy"
  type        = string
  default     = "/"
}

variable "iam_policy_delay_after_creation_in_ms" {
  description = "Number of milliseconds to wait between creating the policy and setting its version as default"
  type        = number
  default     = null
}
