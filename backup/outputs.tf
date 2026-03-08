# ============================================================
# Vault
# ============================================================

output "backup_vault_id" {
  description = "Backup vault ID (name)."
  value       = local.vault_id
}

output "backup_vault_arn" {
  description = "Backup vault ARN."
  value       = local.vault_arn
}

output "backup_vault_recovery_points" {
  description = "Number of recovery points stored in the vault."
  value       = var.vault_enabled ? try(aws_backup_vault.this.recovery_points, null) : try(data.aws_backup_vault.existing[0].recovery_points, null)
}

# ============================================================
# Air-Gapped Vault
# ============================================================

output "air_gapped_vault_id" {
  description = "Logically air-gapped vault ID (name). Empty string when not created."
  value       = try(aws_backup_logically_air_gapped_vault.this.id, "")
}

output "air_gapped_vault_arn" {
  description = "Logically air-gapped vault ARN. Empty string when not created."
  value       = try(aws_backup_logically_air_gapped_vault.this.arn, "")
}

# ============================================================
# Backup Plan
# ============================================================

output "backup_plan_id" {
  description = "Backup plan ID."
  value       = try(aws_backup_plan.this.id, "")
}

output "backup_plan_arn" {
  description = "Backup plan ARN."
  value       = try(aws_backup_plan.this.arn, "")
}

output "backup_plan_version" {
  description = "Version UUID of the backup plan, updated on every change."
  value       = try(aws_backup_plan.this.version, "")
}

# ============================================================
# Backup Selections
# ============================================================

output "backup_selection_ids" {
  description = "Map of selection name to selection ID."
  value       = { for k, v in aws_backup_selection.this : k => v.id }
}

# ============================================================
# IAM
# ============================================================

output "iam_role_name" {
  description = "Name of the IAM role used by AWS Backup."
  value       = local.iam_role_name
}

output "iam_role_arn" {
  description = "ARN of the IAM role used by AWS Backup."
  value       = local.iam_role_arn
}

# ============================================================
# Frameworks and Report Plans
# ============================================================

output "framework_arns" {
  description = "Map of framework name to ARN."
  value       = { for k, v in aws_backup_framework.this : k => v.arn }
}

output "report_plan_arns" {
  description = "Map of report plan name to ARN."
  value       = { for k, v in aws_backup_report_plan.this : k => v.arn }
}

# ============================================================
# Restore Testing
# ============================================================

output "restore_testing_plan_arn" {
  description = "Restore testing plan ARN. Null when not created."
  value       = try(aws_backup_restore_testing_plan.this.arn, null)
}
