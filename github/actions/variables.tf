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
  description = "List of GitHub repository names allowed to assume the role"
  type        = list(string)

  validation {
    condition     = length(var.repo_names) > 0
    error_message = "repo_names must contain at least one repository name."
  }

  validation {
    condition     = alltrue([for repo in var.repo_names : length(trimspace(repo)) > 0])
    error_message = "repo_names entries must be non-empty."
  }
}

variable "github_organization_name" {
  description = "The GitHub organization name"
  type        = string

  validation {
    condition     = length(trimspace(var.github_organization_name)) > 0
    error_message = "github_organization_name must be non-empty."
  }
}

variable "github_oidc_arn" {
  description = "The GitHub openid connect provider arn"
  type        = string

  validation {
    condition     = can(regex("^arn:", var.github_oidc_arn))
    error_message = "The github_oidc_arn must be a valid ARN starting with 'arn:'."
  }
}

variable "github_ref" {
  description = "Optional git ref to constrain the OIDC subject claim to (e.g. 'refs/heads/main' or 'refs/tags/v*'). When set, only workflows running on this ref can assume the role. Strongly recommended for roles with write access."
  type        = string
  default     = null
}

variable "github_environment" {
  description = "Optional GitHub Actions environment name to constrain the OIDC subject claim to (e.g. 'production'). When set, only workflows targeting this environment can assume the role. Strongly recommended for roles with write access."
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

  validation {
    condition     = length(trimspace(var.iam_role_name)) > 0
    error_message = "iam_role_name must be non-empty."
  }
}

variable "iam_role_description" {
  description = "The description of the GitHub actions IAM role"
  type        = string
  default     = "GitHub Actions Role"
}

variable "iam_policy_document" {
  description = "The JSON formatted policy document"
  type        = string
  default     = null
}

variable "iam_role_path" {
  description = "Path for the IAM role"
  type        = string
  default     = "/"

  validation {
    condition     = can(regex("^/", var.iam_role_path))
    error_message = "The iam_role_path must begin with '/'."
  }
}

variable "iam_role_max_session_duration" {
  description = "Maximum session duration (in seconds) for the IAM role. Value between 3600 and 43200."
  type        = number
  default     = 3600

  validation {
    condition     = var.iam_role_max_session_duration >= 3600 && var.iam_role_max_session_duration <= 43200
    error_message = "The iam_role_max_session_duration must be between 3600 and 43200 seconds."
  }
}

variable "iam_role_permissions_boundary" {
  description = "ARN of the policy used as permissions boundary for the IAM role"
  type        = string
  default     = null

  validation {
    condition     = var.iam_role_permissions_boundary == null || can(regex("^arn:", var.iam_role_permissions_boundary))
    error_message = "The iam_role_permissions_boundary must be null or a valid ARN starting with 'arn:'."
  }
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

  validation {
    condition     = can(regex("^/", var.iam_policy_path))
    error_message = "The iam_policy_path must begin with '/'."
  }
}

variable "iam_policy_delay_after_creation_in_ms" {
  description = "Number of milliseconds to wait between creating the policy and setting its version as default"
  type        = number
  default     = null
}
