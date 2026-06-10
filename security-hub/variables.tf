variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}


variable "name" {
  description = "Optional name prefix for Security Hub resources. When set, custom action target names are prefixed with it"
  type        = string
  default     = null

  validation {
    condition     = var.name == null || length(coalesce(var.name, "x")) > 0
    error_message = "The name must not be empty."
  }
}

variable "tags" {
  description = "Map of tags for module convention. Security Hub resources do not currently support tags; kept for forward compatibility"
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

  validation {
    condition     = contains(["SECURITY_CONTROL", "STANDARD_CONTROL"], var.control_finding_generator)
    error_message = "The control_finding_generator must be 'SECURITY_CONTROL' or 'STANDARD_CONTROL'."
  }
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

  validation {
    condition     = contains(["ALL_REGIONS", "ALL_REGIONS_EXCEPT_SPECIFIED", "SPECIFIED_REGIONS"], var.finding_aggregator_linking_mode)
    error_message = "The finding_aggregator_linking_mode must be 'ALL_REGIONS', 'ALL_REGIONS_EXCEPT_SPECIFIED', or 'SPECIFIED_REGIONS'."
  }
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

  validation {
    condition     = contains(["DEFAULT", "NONE"], var.organization_auto_enable_standards)
    error_message = "The organization_auto_enable_standards must be 'DEFAULT' or 'NONE'."
  }
}

variable "organization_configuration_type" {
  description = "Organization configuration type. Valid values: CENTRAL, LOCAL. Set to null to skip the organization_configuration block"
  type        = string
  default     = null

  validation {
    condition     = var.organization_configuration_type == null || contains(["CENTRAL", "LOCAL"], var.organization_configuration_type)
    error_message = "The organization_configuration_type must be 'CENTRAL', 'LOCAL', or null."
  }
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

################################################################################
# Automation Rules
################################################################################

variable "automation_rules" {
  description = <<-EOT
    Map of Security Hub automation rules. Each rule matches findings against `criteria`
    (string filters with `comparison` of EQUALS, NOT_EQUALS, PREFIX, PREFIX_NOT_EQUALS, or CONTAINS)
    and applies the finding-field updates in `actions`. `rule_name` defaults to the map key.
    Lower `rule_order` values run first; set `is_terminal = true` to stop processing subsequent rules.
  EOT
  type = map(object({
    rule_name   = optional(string)
    rule_order  = number
    description = string
    rule_status = optional(string, "ENABLED")
    is_terminal = optional(bool, false)
    criteria = object({
      aws_account_id                 = optional(list(object({ comparison = string, value = string })), [])
      compliance_status              = optional(list(object({ comparison = string, value = string })), [])
      compliance_security_control_id = optional(list(object({ comparison = string, value = string })), [])
      generator_id                   = optional(list(object({ comparison = string, value = string })), [])
      product_name                   = optional(list(object({ comparison = string, value = string })), [])
      record_state                   = optional(list(object({ comparison = string, value = string })), [])
      resource_type                  = optional(list(object({ comparison = string, value = string })), [])
      severity_label                 = optional(list(object({ comparison = string, value = string })), [])
      title                          = optional(list(object({ comparison = string, value = string })), [])
      type                           = optional(list(object({ comparison = string, value = string })), [])
      workflow_status                = optional(list(object({ comparison = string, value = string })), [])
    })
    actions = object({
      severity_label      = optional(string)
      workflow_status     = optional(string)
      verification_state  = optional(string)
      confidence          = optional(number)
      criticality         = optional(number)
      types               = optional(list(string))
      user_defined_fields = optional(map(string))
      note_text           = optional(string)
      note_updated_by     = optional(string, "opentofu")
    })
  }))
  default = {}

  validation {
    condition     = alltrue([for v in values(var.automation_rules) : contains(["ENABLED", "DISABLED"], v.rule_status)])
    error_message = "automation_rules rule_status must be ENABLED or DISABLED."
  }

  validation {
    condition     = alltrue([for v in values(var.automation_rules) : v.actions.severity_label == null || contains(["INFORMATIONAL", "LOW", "MEDIUM", "HIGH", "CRITICAL"], coalesce(v.actions.severity_label, "_"))])
    error_message = "automation_rules actions.severity_label must be one of: INFORMATIONAL, LOW, MEDIUM, HIGH, CRITICAL."
  }

  validation {
    condition     = alltrue([for v in values(var.automation_rules) : v.actions.workflow_status == null || contains(["NEW", "NOTIFIED", "RESOLVED", "SUPPRESSED"], coalesce(v.actions.workflow_status, "_"))])
    error_message = "automation_rules actions.workflow_status must be one of: NEW, NOTIFIED, RESOLVED, SUPPRESSED."
  }
}

################################################################################
# Insights
################################################################################

variable "insights" {
  description = <<-EOT
    Map of Security Hub custom insights. Each insight groups findings matching `filters`
    (string filters with `comparison` of EQUALS, NOT_EQUALS, PREFIX, PREFIX_NOT_EQUALS, or CONTAINS)
    by `group_by_attribute` (e.g. ResourceId, AwsAccountId, SeverityLabel, Type).
    `name` defaults to the map key.
  EOT
  type = map(object({
    name               = optional(string)
    group_by_attribute = string
    filters = object({
      aws_account_id    = optional(list(object({ comparison = string, value = string })), [])
      compliance_status = optional(list(object({ comparison = string, value = string })), [])
      generator_id      = optional(list(object({ comparison = string, value = string })), [])
      product_name      = optional(list(object({ comparison = string, value = string })), [])
      record_state      = optional(list(object({ comparison = string, value = string })), [])
      resource_type     = optional(list(object({ comparison = string, value = string })), [])
      severity_label    = optional(list(object({ comparison = string, value = string })), [])
      title             = optional(list(object({ comparison = string, value = string })), [])
      type              = optional(list(object({ comparison = string, value = string })), [])
      workflow_status   = optional(list(object({ comparison = string, value = string })), [])
    })
  }))
  default = {}
}
