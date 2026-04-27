# ============================================================
# Locals
# ============================================================

locals {
  enabled      = var.enabled
  plan_enabled = local.enabled && var.plan_enabled
  vault_name   = coalesce(var.vault_name, var.name)
  plan_name    = var.plan_name_suffix == null ? var.name : format("%s_%s", var.name, var.plan_name_suffix)

  iam_role_name = local.enabled ? coalesce(var.iam_role_name, "${var.name}-backup") : null
  iam_role_arn  = var.iam_role_enabled ? try(aws_iam_role.this.arn, "") : try(data.aws_iam_role.existing[0].arn, "")

  vault_id  = var.vault_enabled ? try(aws_backup_vault.this.id, "") : try(data.aws_backup_vault.existing[0].id, "")
  vault_arn = var.vault_enabled ? try(aws_backup_vault.this.arn, "") : try(data.aws_backup_vault.existing[0].arn, "")

  air_gapped_vault_name = try(var.air_gapped_vault.name, null) != null ? var.air_gapped_vault.name : "${var.name}-airgap"

  _notification_events = try(var.notifications.events, null) != null ? var.notifications.events : [
    "BACKUP_JOB_STARTED",
    "BACKUP_JOB_COMPLETED",
    "BACKUP_JOB_FAILED",
    "COPY_JOB_STARTED",
    "COPY_JOB_FAILED",
    "RESTORE_JOB_COMPLETED",
    "RESTORE_JOB_FAILED",
  ]

  _default_policies = [
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore",
  ]
  _all_policies = distinct(concat(local._default_policies, var.iam_role_extra_policies))

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

data "aws_partition" "current" {}

# ============================================================
# Vault
# ============================================================

resource "aws_backup_vault" "this" {
  name          = local.vault_name
  kms_key_arn   = var.kms_key_arn
  force_destroy = var.vault_force_destroy

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.vault_enabled
  }
}

data "aws_backup_vault" "existing" {
  count = local.enabled && !var.vault_enabled ? 1 : 0
  name  = local.vault_name
}

# ============================================================
# Vault Lock
# ============================================================

resource "aws_backup_vault_lock_configuration" "this" {
  backup_vault_name   = local.vault_id
  changeable_for_days = try(var.vault_lock.changeable_for_days, null)
  max_retention_days  = try(var.vault_lock.max_retention_days, null)
  min_retention_days  = try(var.vault_lock.min_retention_days, null)

  lifecycle {
    enabled = local.enabled && var.vault_enabled && var.vault_lock != null
  }
}

# ============================================================
# Vault Policy
# ============================================================

resource "aws_backup_vault_policy" "this" {
  backup_vault_name = local.vault_id
  policy            = var.vault_policy

  lifecycle {
    enabled = local.enabled && var.vault_enabled && var.vault_policy != null
  }
}

# ============================================================
# Vault Notifications
# ============================================================

resource "aws_backup_vault_notifications" "this" {
  backup_vault_name   = local.vault_id
  sns_topic_arn       = try(var.notifications.sns_topic_arn, "")
  backup_vault_events = local._notification_events

  lifecycle {
    enabled = local.enabled && var.vault_enabled && var.notifications != null
  }
}

# ============================================================
# Air-Gapped Vault
# ============================================================

resource "aws_backup_logically_air_gapped_vault" "this" {
  name               = local.air_gapped_vault_name
  min_retention_days = try(var.air_gapped_vault.min_retention_days, 1)
  max_retention_days = try(var.air_gapped_vault.max_retention_days, 365)
  encryption_key_arn = try(var.air_gapped_vault.encryption_key_arn, null)

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.air_gapped_vault != null
  }
}

# ============================================================
# IAM
# ============================================================

data "aws_iam_policy_document" "assume_role" {
  count = local.enabled && var.iam_role_enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = local.iam_role_name
  assume_role_policy   = try(data.aws_iam_policy_document.assume_role[0].json, "")
  permissions_boundary = var.permissions_boundary

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.iam_role_enabled
  }
}

data "aws_iam_role" "existing" {
  count = local.enabled && !var.iam_role_enabled ? 1 : 0
  name  = local.iam_role_name
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = local.enabled && var.iam_role_enabled ? toset(local._all_policies) : toset([])

  policy_arn = each.value
  role       = aws_iam_role.this.name
}

# ============================================================
# Backup Plan
# ============================================================

resource "aws_backup_plan" "this" {
  name = local.plan_name

  dynamic "rule" {
    for_each = var.rules

    content {
      rule_name         = rule.value.name
      target_vault_name = local.vault_name

      # Use "self" sentinel to reference the module's own air-gapped vault
      target_logically_air_gapped_backup_vault_arn = (
        try(rule.value.target_logically_air_gapped_backup_vault_arn, null) == "self"
        ? try(aws_backup_logically_air_gapped_vault.this.arn, null)
        : try(rule.value.target_logically_air_gapped_backup_vault_arn, null)
      )

      schedule                     = try(rule.value.schedule, null)
      schedule_expression_timezone = try(rule.value.schedule_expression_timezone, null)
      start_window                 = try(rule.value.start_window, null)
      completion_window            = try(rule.value.completion_window, null)
      enable_continuous_backup     = try(rule.value.enable_continuous_backup, null)
      recovery_point_tags          = try(rule.value.recovery_point_tags, local.tags)

      dynamic "lifecycle" {
        for_each = try(rule.value.lifecycle, null) != null ? [rule.value.lifecycle] : []

        content {
          cold_storage_after                        = try(lifecycle.value.cold_storage_after, null)
          delete_after                              = try(lifecycle.value.delete_after, null)
          opt_in_to_archive_for_supported_resources = try(lifecycle.value.opt_in_to_archive_for_supported_resources, null)
        }
      }

      dynamic "copy_action" {
        for_each = try(rule.value.copy_actions, [])

        content {
          destination_vault_arn = copy_action.value.destination_vault_arn

          dynamic "lifecycle" {
            for_each = try(copy_action.value.lifecycle, null) != null ? [copy_action.value.lifecycle] : []

            content {
              cold_storage_after                        = try(lifecycle.value.cold_storage_after, null)
              delete_after                              = try(lifecycle.value.delete_after, null)
              opt_in_to_archive_for_supported_resources = try(lifecycle.value.opt_in_to_archive_for_supported_resources, null)
            }
          }
        }
      }

      dynamic "scan_action" {
        for_each = try(rule.value.scan_action, null) != null ? [rule.value.scan_action] : []

        content {
          malware_scanner = scan_action.value.malware_scanner
          scan_mode       = scan_action.value.scan_mode
        }
      }
    }
  }

  dynamic "advanced_backup_setting" {
    for_each = var.advanced_backup_setting != null ? [var.advanced_backup_setting] : []

    content {
      backup_options = advanced_backup_setting.value.backup_options
      resource_type  = advanced_backup_setting.value.resource_type
    }
  }

  dynamic "scan_setting" {
    for_each = var.scan_setting != null ? [var.scan_setting] : []

    content {
      malware_scanner  = scan_setting.value.malware_scanner
      resource_types   = scan_setting.value.resource_types
      scanner_role_arn = scan_setting.value.scanner_role_arn
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.plan_enabled
  }
}

# ============================================================
# Backup Selections
# ============================================================

resource "aws_backup_selection" "this" {
  for_each = local.plan_enabled ? var.selections : {}

  name          = each.key
  plan_id       = aws_backup_plan.this.id
  iam_role_arn  = try(each.value.iam_role_arn, null) != null ? each.value.iam_role_arn : local.iam_role_arn
  resources     = try(each.value.resources, [])
  not_resources = try(each.value.not_resources, [])

  dynamic "selection_tag" {
    for_each = try(each.value.selection_tags, [])

    content {
      type  = selection_tag.value.type
      key   = selection_tag.value.key
      value = selection_tag.value.value
    }
  }

  condition {
    dynamic "string_equals" {
      for_each = try(each.value.conditions.string_equals, [])
      content {
        key   = string_equals.value.key
        value = string_equals.value.value
      }
    }
    dynamic "string_not_equals" {
      for_each = try(each.value.conditions.string_not_equals, [])
      content {
        key   = string_not_equals.value.key
        value = string_not_equals.value.value
      }
    }
    dynamic "string_like" {
      for_each = try(each.value.conditions.string_like, [])
      content {
        key   = string_like.value.key
        value = string_like.value.value
      }
    }
    dynamic "string_not_like" {
      for_each = try(each.value.conditions.string_not_like, [])
      content {
        key   = string_not_like.value.key
        value = string_not_like.value.value
      }
    }
  }
}

# ============================================================
# Frameworks
# ============================================================

resource "aws_backup_framework" "this" {
  for_each = local.enabled ? var.frameworks : {}

  name        = each.key
  description = try(each.value.description, null)

  dynamic "control" {
    for_each = each.value.controls

    content {
      name = control.value.name

      dynamic "input_parameter" {
        for_each = try(control.value.input_parameters, [])

        content {
          name  = input_parameter.value.name
          value = input_parameter.value.value
        }
      }

      dynamic "scope" {
        for_each = try(control.value.scope, null) != null ? [control.value.scope] : []

        content {
          compliance_resource_ids   = try(scope.value.compliance_resource_ids, null)
          compliance_resource_types = try(scope.value.compliance_resource_types, null)
          tags                      = try(scope.value.tags, null)
        }
      }
    }
  }

  tags = local.tags
}

# ============================================================
# Report Plans
# ============================================================

resource "aws_backup_report_plan" "this" {
  for_each = local.enabled ? var.report_plans : {}

  name        = each.key
  description = try(each.value.description, null)

  report_delivery_channel {
    s3_bucket_name = each.value.s3_bucket_name
    s3_key_prefix  = try(each.value.s3_key_prefix, null)
    formats        = try(each.value.formats, ["CSV"])
  }

  report_setting {
    report_template    = each.value.report_template
    accounts           = try(each.value.accounts, [])
    regions            = try(each.value.regions, [])
    framework_arns     = try(each.value.framework_arns, [])
    organization_units = try(each.value.organization_units, [])
  }

  tags = local.tags
}

# ============================================================
# Region Settings
# ============================================================

resource "aws_backup_region_settings" "this" {
  resource_type_opt_in_preference     = try(var.region_settings.resource_type_opt_in_preference, {})
  resource_type_management_preference = try(var.region_settings.resource_type_management_preference, null)

  lifecycle {
    enabled = local.enabled && var.region_settings != null
  }
}

# ============================================================
# Restore Testing Plan
# ============================================================

resource "aws_backup_restore_testing_plan" "this" {
  name                         = try(var.restore_testing_plan.name, null) != null ? var.restore_testing_plan.name : "${var.name}-restore-test"
  schedule_expression          = try(var.restore_testing_plan.schedule_expression, "cron(0 5 ? * * *)")
  schedule_expression_timezone = try(var.restore_testing_plan.schedule_expression_timezone, null)
  start_window_hours           = try(var.restore_testing_plan.start_window_hours, null)

  recovery_point_selection {
    algorithm             = try(var.restore_testing_plan.recovery_point_selection.algorithm, "LATEST_WITHIN_WINDOW")
    include_vaults        = try(var.restore_testing_plan.recovery_point_selection.include_vaults, [local.vault_arn])
    recovery_point_types  = try(var.restore_testing_plan.recovery_point_selection.recovery_point_types, ["CONTINUOUS"])
    exclude_vaults        = try(var.restore_testing_plan.recovery_point_selection.exclude_vaults, null)
    selection_window_days = try(var.restore_testing_plan.recovery_point_selection.selection_window_days, null)
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.restore_testing_plan != null
  }
}

# ============================================================
# Restore Testing Selections
# ============================================================

resource "aws_backup_restore_testing_selection" "this" {
  for_each = local.enabled && var.restore_testing_plan != null ? var.restore_testing_selections : {}

  name                       = each.key
  restore_testing_plan_name  = aws_backup_restore_testing_plan.this.name
  protected_resource_type    = each.value.protected_resource_type
  iam_role_arn               = try(each.value.iam_role_arn, null) != null ? each.value.iam_role_arn : local.iam_role_arn
  protected_resource_arns    = try(each.value.protected_resource_arns, [])
  restore_metadata_overrides = try(each.value.restore_metadata_overrides, {})
  validation_window_hours    = try(each.value.validation_window_hours, null)

  dynamic "protected_resource_conditions" {
    for_each = (
      length(try(each.value.protected_resource_conditions.string_equals, [])) > 0 ||
      length(try(each.value.protected_resource_conditions.string_not_equals, [])) > 0
    ) ? [each.value.protected_resource_conditions] : []

    content {
      dynamic "string_equals" {
        for_each = try(protected_resource_conditions.value.string_equals, [])
        content {
          key   = string_equals.value.key
          value = string_equals.value.value
        }
      }
      dynamic "string_not_equals" {
        for_each = try(protected_resource_conditions.value.string_not_equals, [])
        content {
          key   = string_not_equals.value.key
          value = string_not_equals.value.value
        }
      }
    }
  }
}
