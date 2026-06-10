locals {
  enabled = var.enabled

  create_encryption_config = local.enabled && var.create_encryption_config

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}


################################################################################
# Encryption Configuration
################################################################################

resource "aws_xray_encryption_config" "this" {
  type   = "KMS"
  key_id = var.kms_key_id
  region = var.region

  lifecycle {
    enabled = local.create_encryption_config
  }
}

################################################################################
# Sampling Rules
################################################################################

resource "aws_xray_sampling_rule" "this" {
  for_each = local.enabled ? var.sampling_rules : {}

  rule_name      = each.key
  priority       = each.value.priority
  version        = each.value.version
  reservoir_size = each.value.reservoir_size
  fixed_rate     = each.value.fixed_rate
  url_path       = each.value.url_path
  host           = each.value.host
  http_method    = each.value.http_method
  service_type   = each.value.service_type
  service_name   = each.value.service_name
  resource_arn   = each.value.resource_arn
  attributes     = each.value.attributes
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
    for_each = each.value.insights_configuration != null ? [each.value.insights_configuration] : []

    content {
      insights_enabled      = insights_configuration.value.insights_enabled
      notifications_enabled = insights_configuration.value.notifications_enabled
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
  bypass_policy_lockout_check = each.value.bypass_policy_lockout_check
  region                      = var.region
}

################################################################################
