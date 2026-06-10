locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
    Region    = data.aws_region.current.region
  })
}

data "aws_caller_identity" "current" {}

################################################################################
# Workspace
################################################################################

resource "aws_grafana_workspace" "this" {
  name                      = var.name
  description               = var.workspace_description
  account_access_type       = var.account_access_type
  authentication_providers  = var.authentication_providers
  permission_type           = var.permission_type
  grafana_version           = var.grafana_version
  data_sources              = var.data_sources
  notification_destinations = var.notification_destinations
  organizational_units      = var.organizational_units
  organization_role_name    = var.organization_role_name
  role_arn                  = var.create_iam_role ? aws_iam_role.this.arn : var.iam_role_arn
  stack_set_name            = var.stack_set_name
  configuration             = var.workspace_configuration != null ? jsonencode(var.workspace_configuration) : null

  dynamic "vpc_configuration" {
    for_each = var.vpc_configuration != null ? [var.vpc_configuration] : []

    content {
      security_group_ids = vpc_configuration.value.security_group_ids
      subnet_ids         = vpc_configuration.value.subnet_ids
    }
  }

  dynamic "network_access_control" {
    for_each = var.network_access_control != null ? [var.network_access_control] : []

    content {
      prefix_list_ids = network_access_control.value.prefix_list_ids
      vpce_ids        = network_access_control.value.vpce_ids
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# License Association
################################################################################

resource "aws_grafana_license_association" "this" {
  workspace_id = aws_grafana_workspace.this.id
  license_type = var.license_type

  lifecycle {
    enabled = local.enabled && var.create_license_association && var.license_type != null
  }
}

################################################################################
# SAML Configuration
################################################################################

resource "aws_grafana_workspace_saml_configuration" "this" {
  workspace_id       = aws_grafana_workspace.this.id
  editor_role_values = var.saml_editor_role_values
  admin_role_values  = var.saml_admin_role_values
  idp_metadata_url   = var.saml_idp_metadata_url
  idp_metadata_xml   = var.saml_idp_metadata_xml

  login_assertion  = var.saml_login_assertion != null ? var.saml_login_assertion.login : null
  email_assertion  = var.saml_login_assertion != null ? var.saml_login_assertion.email : null
  groups_assertion = var.saml_login_assertion != null ? var.saml_login_assertion.groups : null
  name_assertion   = var.saml_login_assertion != null ? var.saml_login_assertion.name : null
  org_assertion    = var.saml_login_assertion != null ? var.saml_login_assertion.org : null
  role_assertion   = var.saml_login_assertion != null ? var.saml_login_assertion.role : null

  lifecycle {
    enabled = local.enabled && var.enable_saml_configuration
  }
}

################################################################################
# Service Accounts
################################################################################

resource "aws_grafana_workspace_service_account" "this" {
  for_each = local.enabled ? var.service_accounts : {}

  name         = each.key
  grafana_role = each.value.grafana_role
  workspace_id = aws_grafana_workspace.this.id
}

resource "aws_grafana_workspace_service_account_token" "this" {
  for_each = local.enabled ? merge([
    for sa_key, sa in var.service_accounts : {
      for token_name, token in sa.tokens : "${sa_key}/${token_name}" => {
        sa_key          = sa_key
        name            = token_name
        seconds_to_live = token.seconds_to_live
      }
    }
  ]...) : {}

  name               = each.value.name
  service_account_id = aws_grafana_workspace_service_account.this[each.value.sa_key].service_account_id
  seconds_to_live    = each.value.seconds_to_live
  workspace_id       = aws_grafana_workspace.this.id
}

################################################################################
# IAM Role
################################################################################

resource "aws_iam_role" "this" {
  name        = var.iam_role_use_name_prefix ? null : coalesce(var.iam_role_name, "grafana-${var.name}")
  name_prefix = var.iam_role_use_name_prefix ? "${coalesce(var.iam_role_name, "grafana-${var.name}")}-" : null
  path        = var.iam_role_path
  description = "IAM role for Amazon Managed Grafana workspace ${var.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "grafana.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_iam_role
  }
}

resource "aws_iam_role_policy" "this" {
  for_each = local.enabled && var.create_iam_role ? var.iam_role_inline_policies : {}

  name   = each.key
  role   = aws_iam_role.this.id
  policy = each.value
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = local.enabled && var.create_iam_role ? var.iam_role_policy_arns : {}

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

################################################################################
# CloudWatch Data Source IAM Policy
################################################################################

resource "aws_iam_role_policy" "cloudwatch" {
  name = "grafana-cloudwatch-access"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetInsightRuleReport",
          "logs:DescribeLogGroups",
          "logs:GetLogGroupFields",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:GetQueryResults",
          "logs:GetLogEvents",
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "tag:GetResources",
        ]
        Resource = "*"
      }
    ]
  })

  lifecycle {
    enabled = local.enabled && var.create_iam_role && contains(var.data_sources, "CLOUDWATCH")
  }
}

################################################################################
# Prometheus Data Source IAM Policy
################################################################################

resource "aws_iam_role_policy" "prometheus" {
  name = "grafana-prometheus-access"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:ListWorkspaces",
          "aps:DescribeWorkspace",
          "aps:QueryMetrics",
          "aps:GetLabels",
          "aps:GetSeries",
          "aps:GetMetricMetadata",
        ]
        Resource = "*"
      }
    ]
  })

  lifecycle {
    enabled = local.enabled && var.create_iam_role && contains(var.data_sources, "PROMETHEUS")
  }
}

################################################################################
# X-Ray Data Source IAM Policy
################################################################################

resource "aws_iam_role_policy" "xray" {
  name = "grafana-xray-access"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets",
          "xray:GetSamplingStatisticSummaries",
          "xray:BatchGetTraces",
          "xray:GetServiceGraph",
          "xray:GetTraceGraph",
          "xray:GetTraceSummaries",
          "xray:GetGroups",
          "xray:GetGroup",
          "xray:GetTimeSeriesServiceStatistics",
          "xray:GetInsightSummaries",
          "xray:GetInsight",
          "xray:GetInsightEvents",
          "xray:GetInsightImpactGraph",
        ]
        Resource = "*"
      }
    ]
  })

  lifecycle {
    enabled = local.enabled && var.create_iam_role && contains(var.data_sources, "XRAY")
  }
}

################################################################################
# SNS Notification IAM Policy
################################################################################

resource "aws_iam_role_policy" "sns" {
  name = "grafana-sns-notifications"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish",
        ]
        Resource = var.sns_topic_arns
      }
    ]
  })

  lifecycle {
    enabled = local.enabled && var.create_iam_role && contains(var.notification_destinations, "SNS") && length(var.sns_topic_arns) > 0
  }
}

################################################################################

data "aws_region" "current" {}
