locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  logging_config_firehose_arn     = jsonencode({ logDestinationConfigs : [var.firehose_arn], redactedFields : [{ redactedFieldType : "SingleHeader", redactedFieldValue : "Cookies" }, { redactedFieldType : "Method" }] })
  logging_config_firehose_enabled = jsonencode({ logDestinationConfigs : [var.firehose_kinesis_id], redactedFields : [{ redactedFieldType : "SingleHeader", redactedFieldValue : "Cookies" }, { redactedFieldType : "Method" }] })

  logging_configuration = var.logging_configuration_enabled ? (var.firehose_enabled ? local.logging_config_firehose_enabled : (var.firehose_arn != null ? local.logging_config_firehose_arn : null)) : null

  waf_v2_policies = local.enabled && length(var.waf_v2_policies) > 0 ? { for policy in flatten(var.waf_v2_policies) : policy.name => policy } : {}
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
