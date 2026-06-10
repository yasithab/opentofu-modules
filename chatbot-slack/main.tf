data "aws_partition" "current" {}

locals {
  enabled = var.enabled
  name    = var.name

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  partition = data.aws_partition.current.partition

  chatbot_role_name = coalesce(var.chatbot_role_name, local.name != null ? "${local.name}-chatbot" : "chatbot-role")

  # Default guardrail is ReadOnlyAccess. AWS Chatbot itself falls back to
  # AdministratorAccess when no guardrail is supplied, which is far too broad
  # for a chat integration.
  guardrail_policies       = var.guardrail_policies != null ? var.guardrail_policies : ["arn:${local.partition}:iam::aws:policy/ReadOnlyAccess"]
  teams_guardrail_policies = var.teams_guardrail_policies != null ? var.teams_guardrail_policies : ["arn:${local.partition}:iam::aws:policy/ReadOnlyAccess"]
}

# managed_policy_arns was removed from aws_iam_role in favour of an explicit
# aws_iam_role_policy_attachment resource. No state migration needed - the
# policy attachment is a new resource; the old inline attachment is simply
# dropped from the role on the next apply (AWS detaches it, then re-attaches
# via the new resource in the same plan).

resource "aws_iam_role" "chatbot" {
  name        = local.chatbot_role_name
  description = "IAM role for AWS Chatbot Slack channel configuration"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "chatbot.amazonaws.com"
        }
      },
    ]
  })

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_iam_role_policy_attachment" "chatbot" {
  role       = aws_iam_role.chatbot.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AWSResourceExplorerReadOnlyAccess"

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_chatbot_slack_channel_configuration" "this" {
  configuration_name    = var.slack_channel_configuration_name
  slack_channel_id      = var.slack_channel_id
  slack_team_id         = var.slack_workspace_id
  iam_role_arn          = aws_iam_role.chatbot.arn
  sns_topic_arns        = var.sns_topic_arns
  guardrail_policy_arns = local.guardrail_policies
  logging_level         = var.logging_level

  user_authorization_required = var.user_role_required

  tags = local.tags

  lifecycle {
    enabled = local.enabled

    precondition {
      condition     = !local.enabled || var.slack_channel_configuration_name != null
      error_message = "slack_channel_configuration_name must be set when enabled is true."
    }

    precondition {
      condition     = !local.enabled || var.slack_channel_id != null
      error_message = "slack_channel_id must be set when enabled is true."
    }

    precondition {
      condition     = !local.enabled || var.slack_workspace_id != null
      error_message = "slack_workspace_id must be set when enabled is true."
    }
  }
}

resource "aws_chatbot_teams_channel_configuration" "this" {
  channel_id         = var.teams_channel_id
  channel_name       = var.teams_channel_name
  configuration_name = var.teams_configuration_name
  iam_role_arn       = aws_iam_role.chatbot.arn
  team_id            = var.teams_team_id
  team_name          = var.teams_team_name
  tenant_id          = var.teams_tenant_id
  sns_topic_arns     = var.teams_sns_topic_arns

  guardrail_policy_arns       = local.teams_guardrail_policies
  logging_level               = var.teams_logging_level
  user_authorization_required = var.teams_user_role_required

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_teams_configuration

    precondition {
      condition     = !var.create_teams_configuration || var.teams_channel_id != null
      error_message = "teams_channel_id must be set when create_teams_configuration is true."
    }

    precondition {
      condition     = !var.create_teams_configuration || var.teams_configuration_name != null
      error_message = "teams_configuration_name must be set when create_teams_configuration is true."
    }

    precondition {
      condition     = !var.create_teams_configuration || var.teams_team_id != null
      error_message = "teams_team_id must be set when create_teams_configuration is true."
    }

    precondition {
      condition     = !var.create_teams_configuration || var.teams_tenant_id != null
      error_message = "teams_tenant_id must be set when create_teams_configuration is true."
    }
  }
}
