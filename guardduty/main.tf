locals {
  enabled = var.enabled
  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# GuardDuty Detector
################################################################################

resource "aws_guardduty_detector" "this" {
  enable                       = true
  finding_publishing_frequency = var.finding_publishing_frequency

  datasources {
    s3_logs {
      enable = var.enable_s3_protection
    }

    kubernetes {
      audit_logs {
        enable = var.enable_eks_protection
      }
    }

    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = var.enable_malware_protection
        }
      }
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# Feature Configuration
################################################################################

resource "aws_guardduty_detector_feature" "rds_login_events" {
  detector_id = aws_guardduty_detector.this.id
  name        = "RDS_LOGIN_EVENTS"
  status      = var.enable_rds_protection ? "ENABLED" : "DISABLED"

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_guardduty_detector_feature" "lambda_network_logs" {
  detector_id = aws_guardduty_detector.this.id
  name        = "LAMBDA_NETWORK_LOGS"
  status      = var.enable_lambda_protection ? "ENABLED" : "DISABLED"

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_guardduty_detector_feature" "runtime_monitoring" {
  detector_id = aws_guardduty_detector.this.id
  name        = "RUNTIME_MONITORING"
  status      = var.enable_runtime_monitoring ? "ENABLED" : "DISABLED"

  dynamic "additional_configuration" {
    for_each = var.enable_runtime_monitoring ? [1] : []

    content {
      name   = "EKS_ADDON_MANAGEMENT"
      status = var.enable_eks_addon_management ? "ENABLED" : "DISABLED"
    }
  }

  dynamic "additional_configuration" {
    for_each = var.enable_runtime_monitoring ? [1] : []

    content {
      name   = "ECS_FARGATE_AGENT_MANAGEMENT"
      status = var.enable_ecs_fargate_agent_management ? "ENABLED" : "DISABLED"
    }
  }

  dynamic "additional_configuration" {
    for_each = var.enable_runtime_monitoring ? [1] : []

    content {
      name   = "EC2_AGENT_MANAGEMENT"
      status = var.enable_ec2_agent_management ? "ENABLED" : "DISABLED"
    }
  }

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# Publishing Destination
################################################################################

resource "aws_guardduty_publishing_destination" "this" {
  for_each = local.enabled && var.publishing_destination != null ? { this = var.publishing_destination } : {}

  detector_id      = aws_guardduty_detector.this.id
  destination_arn  = each.value.destination_arn
  kms_key_arn      = each.value.kms_key_arn
  destination_type = try(each.value.destination_type, "S3")
}

################################################################################
# IPSet
################################################################################

resource "aws_guardduty_ipset" "this" {
  for_each = local.enabled ? { for k, v in var.ipsets : k => v } : {}

  activate    = try(each.value.activate, true)
  detector_id = aws_guardduty_detector.this.id
  format      = each.value.format
  location    = each.value.location
  name        = each.key

  tags = local.tags
}

################################################################################
# ThreatIntelSet
################################################################################

resource "aws_guardduty_threatintelset" "this" {
  for_each = local.enabled ? { for k, v in var.threat_intel_sets : k => v } : {}

  activate    = try(each.value.activate, true)
  detector_id = aws_guardduty_detector.this.id
  format      = each.value.format
  location    = each.value.location
  name        = each.key

  tags = local.tags
}

################################################################################
# Filters
################################################################################

resource "aws_guardduty_filter" "this" {
  for_each = local.enabled ? { for k, v in var.filters : k => v } : {}

  name        = each.key
  action      = each.value.action
  detector_id = aws_guardduty_detector.this.id
  description = try(each.value.description, null)
  rank        = try(each.value.rank, 1)

  finding_criteria {
    dynamic "criterion" {
      for_each = each.value.criteria

      content {
        field                 = criterion.value.field
        equals                = try(criterion.value.equals, null)
        not_equals            = try(criterion.value.not_equals, null)
        greater_than          = try(criterion.value.greater_than, null)
        greater_than_or_equal = try(criterion.value.greater_than_or_equal, null)
        less_than             = try(criterion.value.less_than, null)
        less_than_or_equal    = try(criterion.value.less_than_or_equal, null)
      }
    }
  }

  tags = local.tags
}

################################################################################
# Member Accounts
################################################################################

resource "aws_guardduty_member" "this" {
  for_each = local.enabled ? { for k, v in var.member_accounts : k => v } : {}

  account_id                 = each.value.account_id
  detector_id                = aws_guardduty_detector.this.id
  email                      = each.value.email
  invite                     = try(each.value.invite, true)
  invitation_message         = try(each.value.invitation_message, "GuardDuty member invitation")
  disable_email_notification = try(each.value.disable_email_notification, true)
}
