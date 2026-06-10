locals {
  enabled = var.enabled
  name    = var.name

  # Most Security Hub resources do not support tags; local.tags is applied to
  # the ones that do (automation rules).
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
  specified_regions = contains(["SPECIFIED_REGIONS", "ALL_REGIONS_EXCEPT_SPECIFIED"], var.finding_aggregator_linking_mode) ? var.finding_aggregator_regions : null

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

  name        = local.name != null ? "${local.name}-${each.key}" : each.key
  identifier  = each.value.identifier
  description = each.value.description

  depends_on = [aws_securityhub_account.this]
}

################################################################################
# Automation Rules
################################################################################

resource "aws_securityhub_automation_rule" "this" {
  for_each = { for k, v in var.automation_rules : k => v if local.enabled }

  rule_name   = coalesce(each.value.rule_name, each.key)
  rule_order  = each.value.rule_order
  description = each.value.description
  rule_status = each.value.rule_status
  is_terminal = each.value.is_terminal

  tags = local.tags

  actions {
    type = "FINDING_FIELDS_UPDATE"

    finding_fields_update {
      confidence          = each.value.actions.confidence
      criticality         = each.value.actions.criticality
      types               = each.value.actions.types
      user_defined_fields = each.value.actions.user_defined_fields
      verification_state  = each.value.actions.verification_state

      dynamic "note" {
        for_each = each.value.actions.note_text != null ? [1] : []

        content {
          text       = each.value.actions.note_text
          updated_by = each.value.actions.note_updated_by
        }
      }

      dynamic "severity" {
        for_each = each.value.actions.severity_label != null ? [1] : []

        content {
          label = each.value.actions.severity_label
        }
      }

      dynamic "workflow" {
        for_each = each.value.actions.workflow_status != null ? [1] : []

        content {
          status = each.value.actions.workflow_status
        }
      }
    }
  }

  criteria {
    dynamic "aws_account_id" {
      for_each = each.value.criteria.aws_account_id

      content {
        comparison = aws_account_id.value.comparison
        value      = aws_account_id.value.value
      }
    }

    dynamic "compliance_status" {
      for_each = each.value.criteria.compliance_status

      content {
        comparison = compliance_status.value.comparison
        value      = compliance_status.value.value
      }
    }

    dynamic "compliance_security_control_id" {
      for_each = each.value.criteria.compliance_security_control_id

      content {
        comparison = compliance_security_control_id.value.comparison
        value      = compliance_security_control_id.value.value
      }
    }

    dynamic "generator_id" {
      for_each = each.value.criteria.generator_id

      content {
        comparison = generator_id.value.comparison
        value      = generator_id.value.value
      }
    }

    dynamic "product_name" {
      for_each = each.value.criteria.product_name

      content {
        comparison = product_name.value.comparison
        value      = product_name.value.value
      }
    }

    dynamic "record_state" {
      for_each = each.value.criteria.record_state

      content {
        comparison = record_state.value.comparison
        value      = record_state.value.value
      }
    }

    dynamic "resource_type" {
      for_each = each.value.criteria.resource_type

      content {
        comparison = resource_type.value.comparison
        value      = resource_type.value.value
      }
    }

    dynamic "severity_label" {
      for_each = each.value.criteria.severity_label

      content {
        comparison = severity_label.value.comparison
        value      = severity_label.value.value
      }
    }

    dynamic "title" {
      for_each = each.value.criteria.title

      content {
        comparison = title.value.comparison
        value      = title.value.value
      }
    }

    dynamic "type" {
      for_each = each.value.criteria.type

      content {
        comparison = type.value.comparison
        value      = type.value.value
      }
    }

    dynamic "workflow_status" {
      for_each = each.value.criteria.workflow_status

      content {
        comparison = workflow_status.value.comparison
        value      = workflow_status.value.value
      }
    }
  }

  depends_on = [aws_securityhub_account.this]
}

################################################################################
# Insights
################################################################################

resource "aws_securityhub_insight" "this" {
  for_each = { for k, v in var.insights : k => v if local.enabled }

  name               = coalesce(each.value.name, each.key)
  group_by_attribute = each.value.group_by_attribute

  filters {
    dynamic "aws_account_id" {
      for_each = each.value.filters.aws_account_id

      content {
        comparison = aws_account_id.value.comparison
        value      = aws_account_id.value.value
      }
    }

    dynamic "compliance_status" {
      for_each = each.value.filters.compliance_status

      content {
        comparison = compliance_status.value.comparison
        value      = compliance_status.value.value
      }
    }

    dynamic "generator_id" {
      for_each = each.value.filters.generator_id

      content {
        comparison = generator_id.value.comparison
        value      = generator_id.value.value
      }
    }

    dynamic "product_name" {
      for_each = each.value.filters.product_name

      content {
        comparison = product_name.value.comparison
        value      = product_name.value.value
      }
    }

    dynamic "record_state" {
      for_each = each.value.filters.record_state

      content {
        comparison = record_state.value.comparison
        value      = record_state.value.value
      }
    }

    dynamic "resource_type" {
      for_each = each.value.filters.resource_type

      content {
        comparison = resource_type.value.comparison
        value      = resource_type.value.value
      }
    }

    dynamic "severity_label" {
      for_each = each.value.filters.severity_label

      content {
        comparison = severity_label.value.comparison
        value      = severity_label.value.value
      }
    }

    dynamic "title" {
      for_each = each.value.filters.title

      content {
        comparison = title.value.comparison
        value      = title.value.value
      }
    }

    dynamic "type" {
      for_each = each.value.filters.type

      content {
        comparison = type.value.comparison
        value      = type.value.value
      }
    }

    dynamic "workflow_status" {
      for_each = each.value.filters.workflow_status

      content {
        comparison = workflow_status.value.comparison
        value      = workflow_status.value.value
      }
    }
  }

  depends_on = [aws_securityhub_account.this]
}
