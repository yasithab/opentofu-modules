locals {
  enabled = var.enabled
  name    = var.name

  type = var.type != null ? var.type : (
    length(var.parameter_values) > 0 ? "StringList" : (var.secure_type ? "SecureString" : "String")
  )
  secure_type = local.type == "SecureString"
  list_type   = local.type == "StringList"
  string_type = local.type == "String"
  value       = local.list_type ? (length(var.parameter_values) > 0 ? jsonencode(var.parameter_values) : var.parameter_value) : var.parameter_value

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

resource "aws_ssm_parameter" "this" {
  name        = local.name
  type        = local.type
  description = var.parameter_description

  value            = local.secure_type && var.value_wo_version == null ? local.value : null
  value_wo         = local.secure_type ? var.value_wo : null
  value_wo_version = local.secure_type ? var.value_wo_version : null
  insecure_value   = local.list_type || local.string_type ? local.value : null

  tier            = var.tier
  key_id          = local.secure_type ? var.key_id : null
  allowed_pattern = var.allowed_pattern
  data_type       = var.data_type

  tags = local.tags

  lifecycle {
    enabled = local.enabled && !var.ignore_value_changes
  }
}

resource "aws_ssm_parameter" "ignore_value" {
  name        = local.name
  type        = local.type
  description = var.parameter_description

  value            = local.secure_type && var.value_wo_version == null ? local.value : null
  value_wo         = local.secure_type ? var.value_wo : null
  value_wo_version = local.secure_type ? var.value_wo_version : null
  insecure_value   = local.list_type || local.string_type ? local.value : null

  tier            = var.tier
  key_id          = local.secure_type ? var.key_id : null
  allowed_pattern = var.allowed_pattern
  data_type       = var.data_type

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.ignore_value_changes
    ignore_changes = [
      insecure_value,
      value
    ]
  }
}
