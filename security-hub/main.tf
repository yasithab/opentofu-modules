locals {
  enabled = var.enabled
  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# Security Hub
################################################################################

resource "aws_securityhub_account" "this" {
  enable_default_standards  = var.enable_default_standards
  control_finding_generator = var.control_finding_generator
  auto_enable_controls      = var.auto_enable_controls

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# Standards Subscriptions
################################################################################

resource "aws_securityhub_standards_subscription" "this" {
  for_each = local.enabled ? toset(var.standards_arns) : toset([])

  standards_arn = each.value

  depends_on = [aws_securityhub_account.this]
}

################################################################################
# Member Accounts
################################################################################

resource "aws_securityhub_member" "this" {
  for_each = local.enabled ? { for k, v in var.member_accounts : k => v } : {}

  account_id = each.value.account_id
  email      = try(each.value.email, null)
  invite     = try(each.value.invite, true)

  depends_on = [aws_securityhub_account.this]
}

################################################################################
# Finding Aggregator
################################################################################

resource "aws_securityhub_finding_aggregator" "this" {
  linking_mode      = var.finding_aggregator_linking_mode
  specified_regions = var.finding_aggregator_linking_mode == "SPECIFIED_REGIONS" ? var.finding_aggregator_regions : null

  depends_on = [aws_securityhub_account.this]

  lifecycle {
    enabled = local.enabled && var.enable_finding_aggregator
  }
}

################################################################################
# Organization Configuration
################################################################################

resource "aws_securityhub_organization_configuration" "this" {
  auto_enable           = var.organization_auto_enable
  auto_enable_standards = var.organization_auto_enable_standards

  dynamic "organization_configuration" {
    for_each = var.organization_configuration_type != null ? [1] : []

    content {
      configuration_type = var.organization_configuration_type
    }
  }

  depends_on = [aws_securityhub_account.this]

  lifecycle {
    enabled = local.enabled && var.enable_organization_configuration
  }
}

################################################################################
# Action Targets
################################################################################

resource "aws_securityhub_action_target" "this" {
  for_each = local.enabled ? { for k, v in var.action_targets : k => v } : {}

  name        = each.key
  identifier  = each.value.identifier
  description = each.value.description

  depends_on = [aws_securityhub_account.this]
}
