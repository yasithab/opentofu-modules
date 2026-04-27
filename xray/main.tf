locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}


################################################################################
# Encryption Configuration
################################################################################

resource "aws_xray_encryption_config" "this" {
  type   = var.kms_key_id != null ? "KMS" : "NONE"
  key_id = var.kms_key_id
  region = var.region

  lifecycle {
    enabled = local.enabled && var.create_encryption_config
  }
}

################################################################################
# Sampling Rules
################################################################################

resource "aws_xray_sampling_rule" "this" {
  for_each = local.enabled ? var.sampling_rules : {}

  rule_name      = each.key
  priority       = each.value.priority
  version        = try(each.value.version, 1)
  reservoir_size = each.value.reservoir_size
  fixed_rate     = each.value.fixed_rate
  url_path       = try(each.value.url_path, "*")
  host           = try(each.value.host, "*")
  http_method    = try(each.value.http_method, "*")
  service_type   = try(each.value.service_type, "*")
  service_name   = try(each.value.service_name, "*")
  resource_arn   = try(each.value.resource_arn, "*")
  attributes     = try(each.value.attributes, {})
  region         = var.region

  tags = local.tags
}

################################################################################
# Groups
################################################################################

resource "aws_xray_group" "this" {
  for_each = local.enabled ? var.groups : {}

  group_name        = each.key
  filter_expression = each.value.filter_expression
  region            = var.region

  dynamic "insights_configuration" {
    for_each = try(each.value.insights_configuration, null) != null ? [each.value.insights_configuration] : []

    content {
      insights_enabled      = try(insights_configuration.value.insights_enabled, true)
      notifications_enabled = try(insights_configuration.value.notifications_enabled, true)
    }
  }

  tags = local.tags
}

################################################################################
# Resource Policies
################################################################################

resource "aws_xray_resource_policy" "this" {
  for_each = local.enabled ? var.resource_policies : {}

  policy_name                 = each.key
  policy_document             = each.value.policy_document
  bypass_policy_lockout_check = try(each.value.bypass_policy_lockout_check, false)
  region                      = var.region
}

################################################################################
