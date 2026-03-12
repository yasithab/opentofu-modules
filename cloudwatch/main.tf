################################################################################
# Log Group
################################################################################

locals {
  enabled = var.enabled
  name    = var.log_group_name

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

resource "aws_cloudwatch_log_group" "this" {
  name              = var.use_name_prefix ? null : local.name
  name_prefix       = var.use_name_prefix ? "${local.name}-" : null
  retention_in_days = var.retention_in_days
  kms_key_id        = var.kms_key_id
  log_group_class   = var.log_group_class
  skip_destroy      = var.skip_destroy

  deletion_protection_enabled = var.deletion_protection_enabled

  tags = local.tags

  lifecycle {
    enabled         = local.enabled
    prevent_destroy = true
  }
}

################################################################################
# Log Stream(s)
################################################################################

resource "aws_cloudwatch_log_stream" "this" {
  for_each = { for k, v in var.log_streams : k => v if local.enabled && var.create_log_streams }

  name           = try(each.value.name, each.key)
  log_group_name = aws_cloudwatch_log_group.this.name
}
