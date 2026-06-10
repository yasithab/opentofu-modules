locals {
  enabled = var.enabled

  # for_each keys cannot be derived from sensitive values. Parameter names are
  # not secret, so they are explicitly unmarked while the entry values (which
  # may contain secrets) stay sensitive.
  parameter_write_names   = local.enabled ? nonsensitive(toset([for e in var.parameter_write : e.name])) : toset([])
  parameter_write_entries = { for e in var.parameter_write : e.name => merge(var.parameter_write_defaults, e) }

  parameter_write               = !var.ignore_value_changes ? local.parameter_write_names : toset([])
  parameter_write_ignore_values = var.ignore_value_changes ? local.parameter_write_names : toset([])
  parameter_read                = local.enabled ? var.parameter_read : []

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

data "aws_ssm_parameter" "read" {
  for_each = toset(local.parameter_read)
  name     = each.value
}

resource "aws_ssm_parameter" "default" {
  for_each = local.parameter_write
  name     = each.key

  description      = local.parameter_write_entries[each.key].description
  type             = local.parameter_write_entries[each.key].type
  tier             = local.parameter_write_entries[each.key].tier
  key_id           = local.parameter_write_entries[each.key].type == "SecureString" && var.kms_arn != null && var.kms_arn != "" ? var.kms_arn : null
  value            = local.parameter_write_entries[each.key].type == "SecureString" && try(local.parameter_write_entries[each.key].value_wo, null) == null ? try(local.parameter_write_entries[each.key].value, null) : null
  insecure_value   = local.parameter_write_entries[each.key].type != "SecureString" && try(local.parameter_write_entries[each.key].value_wo, null) == null ? try(local.parameter_write_entries[each.key].value, null) : null
  value_wo         = try(local.parameter_write_entries[each.key].value_wo, null)
  value_wo_version = try(local.parameter_write_entries[each.key].value_wo_version, null) != null ? tonumber(local.parameter_write_entries[each.key].value_wo_version) : null
  allowed_pattern  = local.parameter_write_entries[each.key].allowed_pattern
  data_type        = local.parameter_write_entries[each.key].data_type

  tags = local.tags
}

resource "aws_ssm_parameter" "ignore_value_changes" {
  for_each = local.parameter_write_ignore_values
  name     = each.key

  description      = local.parameter_write_entries[each.key].description
  type             = local.parameter_write_entries[each.key].type
  tier             = local.parameter_write_entries[each.key].tier
  key_id           = local.parameter_write_entries[each.key].type == "SecureString" && var.kms_arn != null && var.kms_arn != "" ? var.kms_arn : null
  value            = local.parameter_write_entries[each.key].type == "SecureString" && try(local.parameter_write_entries[each.key].value_wo, null) == null ? try(local.parameter_write_entries[each.key].value, null) : null
  insecure_value   = local.parameter_write_entries[each.key].type != "SecureString" && try(local.parameter_write_entries[each.key].value_wo, null) == null ? try(local.parameter_write_entries[each.key].value, null) : null
  value_wo         = try(local.parameter_write_entries[each.key].value_wo, null)
  value_wo_version = try(local.parameter_write_entries[each.key].value_wo_version, null) != null ? tonumber(local.parameter_write_entries[each.key].value_wo_version) : null
  allowed_pattern  = local.parameter_write_entries[each.key].allowed_pattern
  data_type        = local.parameter_write_entries[each.key].data_type

  tags = local.tags

  lifecycle {
    ignore_changes = [
      value,
      insecure_value,
    ]
  }
}
