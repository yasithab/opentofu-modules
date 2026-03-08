variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name for the codeconnections connection. Defaults to '<github_organization_name>-github' when not set."
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}


variable "github_organization_name" {
  description = "The GitHub organization name"
  type        = string
  default     = null
}

variable "provider_type" {
  description = "The provider type"
  type        = string
  default     = "GitHub"
}


variable "host_arn" {
  description = "ARN of the codeconnections host to use for GitHubEnterpriseServer/GitLabSelfManaged connections. When set, provider_type is derived from the host."
  type        = string
  default     = null
}

variable "create_host" {
  description = "Whether to create a codeconnections host (for self-hosted VCS like GitHub Enterprise Server)."
  type        = bool
  default     = false
}

variable "host_name" {
  description = "Name of the codeconnections host."
  type        = string
  default     = null
}

variable "host_provider_endpoint" {
  description = "Endpoint of the infrastructure where the provider type is installed (e.g., https://my-github-enterprise.example.com)."
  type        = string
  default     = null
}

variable "host_provider_type" {
  description = "Provider type for the host. Valid values: GitHubEnterpriseServer, GitLabSelfManaged."
  type        = string
  default     = null

  validation {
    condition     = var.host_provider_type == null || contains(["GitHubEnterpriseServer", "GitLabSelfManaged"], var.host_provider_type)
    error_message = "host_provider_type must be GitHubEnterpriseServer or GitLabSelfManaged."
  }
}

variable "host_vpc_configuration" {
  description = "VPC configuration for the codeconnections host (required for VPC-hosted providers)."
  type = object({
    security_group_ids = list(string)
    subnet_ids         = list(string)
    vpc_id             = string
    tls_certificate    = optional(string)
  })
  default = null
}

variable "connection_timeouts" {
  description = "Timeout configuration for the codeconnections connection resource."
  type = object({
    create = optional(string, "30m")
    delete = optional(string, "30m")
  })
  default = {}
}

variable "host_timeouts" {
  description = "Timeout configuration for the codeconnections host resource."
  type = object({
    create = optional(string, "30m")
    delete = optional(string, "30m")
  })
  default = {}
}
