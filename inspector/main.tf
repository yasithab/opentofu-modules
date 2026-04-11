locals {
  enabled = var.enabled
  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# Inspector Enabler
################################################################################

resource "aws_inspector2_enabler" "this" {
  account_ids    = var.account_ids
  resource_types = var.resource_types

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# Delegated Admin Account
################################################################################

resource "aws_inspector2_delegated_admin_account" "this" {
  account_id = var.delegated_admin_account_id

  lifecycle {
    enabled = local.enabled && var.delegated_admin_account_id != null
  }
}

################################################################################
# Organization Configuration
################################################################################

resource "aws_inspector2_organization_configuration" "this" {
  auto_enable {
    ec2    = var.auto_enable_ec2
    ecr    = var.auto_enable_ecr
    lambda = var.auto_enable_lambda
  }

  depends_on = [aws_inspector2_enabler.this]

  lifecycle {
    enabled = local.enabled && var.enable_organization_configuration
  }
}

################################################################################
# Member Associations
################################################################################

resource "aws_inspector2_member_association" "this" {
  for_each = local.enabled ? toset(var.member_account_ids) : toset([])

  account_id = each.value

  depends_on = [aws_inspector2_enabler.this]
}

################################################################################
# Filters (Suppression Rules)
################################################################################

resource "aws_inspector2_filter" "this" {
  for_each = local.enabled ? { for k, v in var.filters : k => v } : {}

  name   = each.key
  action = each.value.action
  reason = try(each.value.reason, null)

  filter_criteria {
    dynamic "aws_account_id" {
      for_each = try(each.value.criteria.aws_account_id, [])

      content {
        comparison = aws_account_id.value.comparison
        value      = aws_account_id.value.value
      }
    }

    dynamic "finding_type" {
      for_each = try(each.value.criteria.finding_type, [])

      content {
        comparison = finding_type.value.comparison
        value      = finding_type.value.value
      }
    }

    dynamic "severity" {
      for_each = try(each.value.criteria.severity, [])

      content {
        comparison = severity.value.comparison
        value      = severity.value.value
      }
    }

    dynamic "vulnerability_id" {
      for_each = try(each.value.criteria.vulnerability_id, [])

      content {
        comparison = vulnerability_id.value.comparison
        value      = vulnerability_id.value.value
      }
    }

    dynamic "resource_type" {
      for_each = try(each.value.criteria.resource_type, [])

      content {
        comparison = resource_type.value.comparison
        value      = resource_type.value.value
      }
    }

    dynamic "ecr_image_repository_name" {
      for_each = try(each.value.criteria.ecr_image_repository_name, [])

      content {
        comparison = ecr_image_repository_name.value.comparison
        value      = ecr_image_repository_name.value.value
      }
    }

    dynamic "title" {
      for_each = try(each.value.criteria.title, [])

      content {
        comparison = title.value.comparison
        value      = title.value.value
      }
    }
  }

  tags = local.tags
}

