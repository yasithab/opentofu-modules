variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name identifier for the GuardDuty deployment, used for naming and tagging conventions"
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Detector Configuration
################################################################################

variable "finding_publishing_frequency" {
  description = "Frequency of notifications sent about subsequent finding occurrences. Valid values: FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS"
  type        = string
  default     = "FIFTEEN_MINUTES"

  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.finding_publishing_frequency)
    error_message = "finding_publishing_frequency must be FIFTEEN_MINUTES, ONE_HOUR, or SIX_HOURS."
  }
}

################################################################################
# Protection Features
################################################################################

variable "enable_s3_protection" {
  description = "Enable S3 data event monitoring for GuardDuty to detect suspicious activities in S3 buckets"
  type        = bool
  default     = true
}

variable "enable_eks_protection" {
  description = "Enable EKS audit log monitoring for GuardDuty to detect suspicious activities in EKS clusters"
  type        = bool
  default     = true
}

variable "enable_malware_protection" {
  description = "Enable malware scanning for EC2 instances with EBS volumes when a GuardDuty finding indicates potential malware"
  type        = bool
  default     = true
}

variable "enable_rds_protection" {
  description = "Enable RDS login activity monitoring for GuardDuty to detect suspicious login attempts to RDS databases"
  type        = bool
  default     = true
}

variable "enable_lambda_protection" {
  description = "Enable Lambda network activity monitoring for GuardDuty to detect suspicious network traffic from Lambda functions"
  type        = bool
  default     = true
}

variable "enable_runtime_monitoring" {
  description = "Enable runtime monitoring for GuardDuty to detect threats at the operating system level on EKS, ECS, and EC2"
  type        = bool
  default     = true
}

variable "enable_eks_addon_management" {
  description = "Enable automatic management of the GuardDuty security agent add-on for EKS clusters"
  type        = bool
  default     = true
}

variable "enable_ecs_fargate_agent_management" {
  description = "Enable automatic management of the GuardDuty security agent for ECS Fargate tasks"
  type        = bool
  default     = true
}

variable "enable_ec2_agent_management" {
  description = "Enable automatic management of the GuardDuty security agent for EC2 instances"
  type        = bool
  default     = true
}

################################################################################
# Publishing Destination
################################################################################

variable "publishing_destination" {
  description = "Configuration for exporting GuardDuty findings to an S3 bucket. Requires destination_arn and kms_key_arn"
  type = object({
    destination_arn  = string
    kms_key_arn      = string
    destination_type = optional(string, "S3")
  })
  default = null
}

################################################################################
# IPSet
################################################################################

variable "ipsets" {
  description = "Map of IPSet configurations. Each key is the IPSet name. Format must be one of: TXT, STIX, OTX_CSV, ALIEN_VAULT, PROOF_POINT, FIRE_EYE"
  type = map(object({
    activate = optional(bool, true)
    format   = string
    location = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for v in values(var.ipsets) : contains(["TXT", "STIX", "OTX_CSV", "ALIEN_VAULT", "PROOF_POINT", "FIRE_EYE"], v.format)
    ])
    error_message = "Each ipsets entry format must be one of: TXT, STIX, OTX_CSV, ALIEN_VAULT, PROOF_POINT, FIRE_EYE."
  }
}

################################################################################
# ThreatIntelSet
################################################################################

variable "threat_intel_sets" {
  description = "Map of ThreatIntelSet configurations. Each key is the ThreatIntelSet name. Format must be one of: TXT, STIX, OTX_CSV, ALIEN_VAULT, PROOF_POINT, FIRE_EYE"
  type = map(object({
    activate = optional(bool, true)
    format   = string
    location = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for v in values(var.threat_intel_sets) : contains(["TXT", "STIX", "OTX_CSV", "ALIEN_VAULT", "PROOF_POINT", "FIRE_EYE"], v.format)
    ])
    error_message = "Each threat_intel_sets entry format must be one of: TXT, STIX, OTX_CSV, ALIEN_VAULT, PROOF_POINT, FIRE_EYE."
  }
}

################################################################################
# Filters
################################################################################

variable "filters" {
  description = "Map of GuardDuty filter configurations. Each key is the filter name. Action must be ARCHIVE or NOOP"
  type = map(object({
    action      = string
    description = optional(string)
    rank        = optional(number, 1)
    criteria = list(object({
      field                 = string
      equals                = optional(list(string))
      not_equals            = optional(list(string))
      greater_than          = optional(string)
      greater_than_or_equal = optional(string)
      less_than             = optional(string)
      less_than_or_equal    = optional(string)
    }))
  }))
  default = {}
}

################################################################################
# Organization Support
################################################################################

variable "create_organization_admin_account" {
  description = "Whether to designate a delegated GuardDuty administrator account for the organization. Apply from the organization management account"
  type        = bool
  default     = false
}

variable "admin_account_id" {
  description = "AWS account ID to designate as the GuardDuty delegated administrator. Required when create_organization_admin_account is true"
  type        = string
  default     = null

  validation {
    condition     = var.admin_account_id == null || can(regex("^[0-9]{12}$", var.admin_account_id))
    error_message = "admin_account_id must be a 12-digit AWS account ID."
  }
}

variable "create_organization_configuration" {
  description = "Whether to manage the organization-wide GuardDuty configuration. Apply from the delegated administrator account"
  type        = bool
  default     = false
}

variable "auto_enable_organization_members" {
  description = "How GuardDuty is auto-enabled for organization member accounts. Valid values: ALL, NEW, NONE"
  type        = string
  default     = "NEW"

  validation {
    condition     = contains(["ALL", "NEW", "NONE"], var.auto_enable_organization_members)
    error_message = "auto_enable_organization_members must be ALL, NEW, or NONE."
  }
}

variable "organization_configuration_features" {
  description = <<-EOT
    Map of GuardDuty detector features to auto-enable for organization member accounts.
    Each key is the feature name (e.g. S3_DATA_EVENTS, EKS_AUDIT_LOGS, EBS_MALWARE_PROTECTION,
    RDS_LOGIN_EVENTS, LAMBDA_NETWORK_LOGS, RUNTIME_MONITORING). auto_enable must be ALL, NEW,
    or NONE. additional_configuration supports nested agent-management settings for
    RUNTIME_MONITORING (EKS_ADDON_MANAGEMENT, ECS_FARGATE_AGENT_MANAGEMENT, EC2_AGENT_MANAGEMENT).
  EOT
  type = map(object({
    auto_enable = string
    additional_configuration = optional(list(object({
      name        = string
      auto_enable = string
    })), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for v in values(var.organization_configuration_features) : contains(["ALL", "NEW", "NONE"], v.auto_enable)
    ])
    error_message = "Each organization_configuration_features entry auto_enable must be ALL, NEW, or NONE."
  }
}

################################################################################
# Member Accounts
################################################################################

variable "member_accounts" {
  description = "Map of member account configurations to associate with the GuardDuty detector. Each key is a friendly identifier"
  type = map(object({
    account_id                 = string
    email                      = string
    invite                     = optional(bool, true)
    invitation_message         = optional(string, "GuardDuty member invitation")
    disable_email_notification = optional(bool, true)
  }))
  default = {}
}
