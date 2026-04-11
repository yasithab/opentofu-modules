variable "enabled" {
  description = "Controls if Security Hub and associated resources are created"
  type        = bool
  default     = true
}

variable "region" {
  description = "AWS region where Security Hub resources will be created. If null, uses the provider default region"
  type        = string
  default     = null
}

variable "name" {
  description = "Name prefix for Security Hub resources used in naming and tagging"
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all Security Hub resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Hub Configuration
################################################################################

variable "enable_default_standards" {
  description = "Whether to enable the default security standards when Security Hub is enabled. Set to false to manually control which standards to enable"
  type        = bool
  default     = false
}

variable "control_finding_generator" {
  description = "Updates whether the calling account has consolidated control findings turned on. Valid values: SECURITY_CONTROL, STANDARD_CONTROL"
  type        = string
  default     = "SECURITY_CONTROL"
}

variable "auto_enable_controls" {
  description = "Whether to automatically enable new controls when they are added to standards that are enabled"
  type        = bool
  default     = true
}

################################################################################
# Standards Subscriptions
################################################################################

variable "standards_arns" {
  description = "List of security standard ARNs to enable. Common standards: AWS Foundational Security Best Practices, CIS AWS Foundations Benchmark, PCI DSS, NIST 800-53"
  type        = list(string)
  default     = []
}

################################################################################
# Member Accounts
################################################################################

variable "member_accounts" {
  description = "Map of member account configurations to associate with Security Hub. Each key is a friendly identifier"
  type = map(object({
    account_id = string
    email      = optional(string)
    invite     = optional(bool, true)
  }))
  default = {}
}

################################################################################
# Finding Aggregator
################################################################################

variable "enable_finding_aggregator" {
  description = "Whether to enable the finding aggregator for cross-region finding aggregation"
  type        = bool
  default     = false
}

variable "finding_aggregator_linking_mode" {
  description = "Linking mode for the finding aggregator. Valid values: ALL_REGIONS, ALL_REGIONS_EXCEPT_SPECIFIED, SPECIFIED_REGIONS"
  type        = string
  default     = "ALL_REGIONS"
}

variable "finding_aggregator_regions" {
  description = "List of regions to include or exclude based on the linking mode. Only used when linking_mode is SPECIFIED_REGIONS or ALL_REGIONS_EXCEPT_SPECIFIED"
  type        = list(string)
  default     = []
}

################################################################################
# Organization Configuration
################################################################################

variable "enable_organization_configuration" {
  description = "Whether to enable the organization-level Security Hub configuration"
  type        = bool
  default     = false
}

variable "organization_auto_enable" {
  description = "Whether to automatically enable Security Hub for new member accounts in the organization"
  type        = bool
  default     = true
}

variable "organization_auto_enable_standards" {
  description = "Whether to automatically enable default standards for new member accounts. Valid values: DEFAULT, NONE"
  type        = string
  default     = "DEFAULT"
}

variable "organization_configuration_type" {
  description = "Organization configuration type. Valid values: CENTRAL, LOCAL. Set to null to skip the organization_configuration block"
  type        = string
  default     = null
}

################################################################################
# Action Targets
################################################################################

variable "action_targets" {
  description = "Map of custom action targets. Each key is the action target name. Identifier must be alphanumeric (max 20 chars)"
  type = map(object({
    identifier  = string
    description = string
  }))
  default = {}
}
