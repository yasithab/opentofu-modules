locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  # camelCase field objects for the WAFv2 managed_service_data logging JSON.
  redacted_fields = [
    for f in var.redacted_fields : merge(
      { redactedFieldType = f.redacted_field_type },
      f.redacted_field_value != null ? { redactedFieldValue = f.redacted_field_value } : {}
    )
  ]

  logging_configuration = var.logging_configuration_enabled ? jsonencode({
    logDestinationConfigs = [var.firehose_arn]
    redactedFields        = local.redacted_fields
  }) : null

  waf_v2_policies = { for policy in var.waf_v2_policies : policy.name => policy if local.enabled }
}

################################################################################
# FMS Admin Account
################################################################################

resource "aws_fms_admin_account" "this" {
  account_id = var.admin_account_id

  lifecycle {
    enabled = local.enabled && var.associate_admin_account
  }
}
