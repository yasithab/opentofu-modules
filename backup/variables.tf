# ============================================================
# Core
# ============================================================

variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name to use for resource naming and tagging."
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

# ============================================================
# Vault
# ============================================================

variable "vault_enabled" {
  type        = bool
  description = "Set to true to create a new backup vault. Set to false to use an existing vault resolved by vault_name."
  default     = true
}

variable "vault_name" {
  type        = string
  description = "Override the vault name. Defaults to var.name when null."
  default     = null
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the KMS key used to encrypt the backup vault. Uses the AWS-managed key when null."
  default     = null
}

variable "vault_force_destroy" {
  type        = bool
  description = "Allow the vault to be destroyed even when it contains recovery points. All recovery points are deleted before vault deletion."
  default     = false
}

variable "vault_policy" {
  type        = string
  description = "JSON IAM resource policy document to attach to the vault (e.g. for cross-account sharing). No policy is attached when null."
  default     = null
}

variable "vault_lock" {
  type = object({
    changeable_for_days = optional(number)
    max_retention_days  = optional(number)
    min_retention_days  = optional(number)
  })
  description = <<-EOT
    Vault lock configuration. Null disables vault lock.
    - changeable_for_days: Creates compliance-mode lock (irremovable for N days). Omit for governance mode.
    - min_retention_days / max_retention_days: Retention range enforced by the lock.
  EOT
  default     = null
}

# ============================================================
# Notifications
# ============================================================

variable "notifications" {
  type = object({
    sns_topic_arn = string
    events        = optional(list(string))
  })
  description = <<-EOT
    SNS notification configuration. Null disables notifications.
    - sns_topic_arn: ARN of the SNS topic. The topic policy must allow backup.amazonaws.com to publish.
    - events: Vault events to send. Defaults to all job start/complete/fail events when null.
  EOT
  default     = null
}

# ============================================================
# Air-Gapped Vault
# ============================================================

variable "air_gapped_vault" {
  type = object({
    name               = optional(string)
    min_retention_days = number
    max_retention_days = number
    encryption_key_arn = optional(string)
  })
  description = <<-EOT
    Configuration for a logically air-gapped backup vault. No air-gapped vault is created when null.
    - name: Override the vault name. Defaults to "<name>-airgap".
    - min_retention_days / max_retention_days: Required retention bounds (non-optional - AWS requires both).
    - encryption_key_arn: Optional KMS key ARN for encryption.
  EOT
  default     = null
}

# ============================================================
# IAM
# ============================================================

variable "iam_role_enabled" {
  type        = bool
  description = "Set to true to create an IAM role for AWS Backup. Set to false to use an existing role resolved by iam_role_name."
  default     = true
}

variable "iam_role_name" {
  type        = string
  description = "Override the IAM role name. Defaults to \"<name>-backup\" when null."
  default     = null
}

variable "permissions_boundary" {
  type        = string
  description = "ARN of the IAM policy to use as permissions boundary for the backup IAM role."
  default     = null
}

variable "iam_role_extra_policies" {
  type        = list(string)
  description = "Additional policy ARNs to attach to the backup IAM role beyond the four default AWS managed backup policies."
  default     = []
}

# ============================================================
# Backup Plan
# ============================================================

variable "plan_enabled" {
  type        = bool
  description = "Set to true to create a backup plan and backup selections."
  default     = true
}

variable "plan_name_suffix" {
  type        = string
  description = "Optional suffix appended to the plan name as: <name>_<suffix>."
  default     = null
}

variable "rules" {
  type = list(object({
    name                                         = string
    schedule                                     = optional(string)
    schedule_expression_timezone                 = optional(string)
    enable_continuous_backup                     = optional(bool)
    start_window                                 = optional(number)
    completion_window                            = optional(number)
    target_logically_air_gapped_backup_vault_arn = optional(string)
    recovery_point_tags                          = optional(map(string))
    lifecycle = optional(object({
      cold_storage_after                        = optional(number)
      delete_after                              = optional(number)
      opt_in_to_archive_for_supported_resources = optional(bool)
    }))
    copy_actions = optional(list(object({
      destination_vault_arn = string
      lifecycle = optional(object({
        cold_storage_after                        = optional(number)
        delete_after                              = optional(number)
        opt_in_to_archive_for_supported_resources = optional(bool)
      }))
    })), [])
    scan_action = optional(object({
      malware_scanner = string
      scan_mode       = string
    }))
  }))
  description = <<-EOT
    List of backup plan rules. Each rule defines a backup schedule, retention policy, and optional
    cross-region copy actions.
    - scan_mode: "FULL_SCAN" or "INCREMENTAL_SCAN".
    - Use target_logically_air_gapped_backup_vault_arn = "self" to reference the module's own air-gapped vault.
  EOT
  default     = []
}

variable "advanced_backup_setting" {
  type = object({
    backup_options = map(string)
    resource_type  = string
  })
  description = "Advanced backup settings per resource type (e.g. Windows VSS backups for EC2)."
  default     = null
}

variable "scan_setting" {
  type = object({
    malware_scanner  = string
    resource_types   = list(string)
    scanner_role_arn = string
  })
  description = <<-EOT
    Malware scan settings for the backup plan. When set, AWS Backup scans recovery points for
    malware using the specified scanner.
    - malware_scanner: Scanner type identifier.
    - resource_types: Resource types to scan (e.g. ["EC2", "EFS"]).
    - scanner_role_arn: ARN of the IAM role used by the malware scanner.
  EOT
  default     = null
}

# ============================================================
# Backup Selections
# ============================================================

variable "selections" {
  type = map(object({
    iam_role_arn  = optional(string)
    resources     = optional(list(string), [])
    not_resources = optional(list(string), [])
    selection_tags = optional(list(object({
      type  = string
      key   = string
      value = string
    })), [])
    conditions = optional(object({
      string_equals     = optional(list(object({ key = string, value = string })), [])
      string_not_equals = optional(list(object({ key = string, value = string })), [])
      string_like       = optional(list(object({ key = string, value = string })), [])
      string_not_like   = optional(list(object({ key = string, value = string })), [])
    }), {})
  }))
  description = <<-EOT
    Map of backup selections. The map key is used as the selection name. Each selection can
    specify resources by ARN, exclusion patterns, tag-based selection, and tag conditions.
    Condition keys are full paths, e.g. "aws:ResourceTag/MyTag". They are NOT auto-prefixed.
    Uses the module IAM role when iam_role_arn is null.
  EOT
  default     = {}
}

# ============================================================
# Frameworks
# ============================================================

variable "frameworks" {
  type = map(object({
    description = optional(string)
    controls = list(object({
      name = string
      input_parameters = optional(list(object({
        name  = string
        value = string
      })), [])
      scope = optional(object({
        compliance_resource_ids   = optional(list(string))
        compliance_resource_types = optional(list(string))
        tags                      = optional(map(string))
      }))
    }))
  }))
  description = "Map of AWS Backup Frameworks to create. Key is used as the framework name."
  default     = {}
}

# ============================================================
# Report Plans
# ============================================================

variable "report_plans" {
  type = map(object({
    description        = optional(string)
    s3_bucket_name     = string
    s3_key_prefix      = optional(string)
    formats            = optional(list(string), ["CSV"])
    report_template    = string
    accounts           = optional(list(string), [])
    regions            = optional(list(string), [])
    framework_arns     = optional(list(string), [])
    organization_units = optional(list(string), [])
  }))
  description = <<-EOT
    Map of AWS Backup Report Plans to create. Key is used as the report plan name.
    report_template must be one of: RESOURCE_COMPLIANCE_REPORT, CONTROL_COMPLIANCE_REPORT,
    BACKUP_JOB_REPORT, COPY_JOB_REPORT, RESTORE_JOB_REPORT.
  EOT
  default     = {}
}

# ============================================================
# Region Settings
# ============================================================

variable "region_settings" {
  type = object({
    resource_type_opt_in_preference     = map(bool)
    resource_type_management_preference = optional(map(bool))
  })
  description = <<-EOT
    AWS Backup region-level settings. When set, configures which resource types are opted in
    to backup and which use AWS Backup-managed policies. This is a region-wide resource -
    only one configuration exists per region per account.
  EOT
  default     = null
}

# ============================================================
# Restore Testing
# ============================================================

variable "restore_testing_plan" {
  type = object({
    name                         = optional(string)
    schedule_expression          = string
    schedule_expression_timezone = optional(string)
    start_window_hours           = optional(number)
    recovery_point_selection = object({
      algorithm             = string
      include_vaults        = list(string)
      recovery_point_types  = list(string)
      exclude_vaults        = optional(list(string))
      selection_window_days = optional(number)
    })
  })
  description = <<-EOT
    Restore testing plan configuration. When set, creates an aws_backup_restore_testing_plan.
    - name: Defaults to "<name>-restore-test".
    - algorithm: RANDOM_WITHIN_WINDOW or LATEST_WITHIN_WINDOW.
    - recovery_point_types: e.g. ["CONTINUOUS", "SNAPSHOT"].
  EOT
  default     = null
}

variable "restore_testing_selections" {
  type = map(object({
    protected_resource_type    = string
    iam_role_arn               = optional(string)
    protected_resource_arns    = optional(list(string), [])
    restore_metadata_overrides = optional(map(string), {})
    validation_window_hours    = optional(number)
    protected_resource_conditions = optional(object({
      string_equals     = optional(list(object({ key = string, value = string })), [])
      string_not_equals = optional(list(object({ key = string, value = string })), [])
    }), {})
  }))
  description = <<-EOT
    Map of restore testing selections. Key is used as the selection name. Requires
    restore_testing_plan to be configured. Uses the module IAM role when iam_role_arn is null.
  EOT
  default     = {}
}
