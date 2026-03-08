locals {
  enabled                       = var.enabled
  parameter_write               = local.enabled && !var.ignore_value_changes ? { for e in var.parameter_write : e.name => merge(var.parameter_write_defaults, e) } : {}
  parameter_write_ignore_values = local.enabled && var.ignore_value_changes ? { for e in var.parameter_write : e.name => merge(var.parameter_write_defaults, e) } : {}
  parameter_read                = local.enabled ? var.parameter_read : []

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

data "aws_ssm_parameter" "read" {
  count = length(local.parameter_read)
  name  = element(local.parameter_read, count.index)
}

resource "aws_ssm_parameter" "default" {
  for_each = local.parameter_write
  name     = each.key

  description     = each.value.description
  type            = each.value.type
  tier            = each.value.tier
  key_id          = each.value.type == "SecureString" && var.kms_arn != null && var.kms_arn != "" ? var.kms_arn : null
  value           = each.value.type == "SecureString" ? each.value.value : null
  insecure_value  = each.value.type != "SecureString" ? each.value.value : null
  overwrite       = each.value.overwrite
  allowed_pattern = each.value.allowed_pattern
  data_type       = each.value.data_type

  tags = local.tags
}

resource "aws_ssm_parameter" "ignore_value_changes" {
  for_each = local.parameter_write_ignore_values
  name     = each.key

  description     = each.value.description
  type            = each.value.type
  tier            = each.value.tier
  key_id          = each.value.type == "SecureString" && var.kms_arn != null && var.kms_arn != "" ? var.kms_arn : null
  value           = each.value.type == "SecureString" ? each.value.value : null
  insecure_value  = each.value.type != "SecureString" ? each.value.value : null
  overwrite       = each.value.overwrite
  allowed_pattern = each.value.allowed_pattern
  data_type       = each.value.data_type

  tags = local.tags

  lifecycle {
    ignore_changes = [
      value,
      insecure_value,
    ]
  }
}
