variable "enabled" {
  description = "Controls if GuardDuty detector and associated resources are created"
  type        = bool
  default     = true
}

variable "region" {
  description = "AWS region where GuardDuty resources will be created. If null, uses the provider default region"
  type        = string
  default     = null
}

variable "name" {
  description = "Name prefix for GuardDuty resources used in naming and tagging"
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all GuardDuty resources"
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
