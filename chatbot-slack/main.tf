locals {
  enabled            = var.enabled
  _chatbot_role_id   = var.name != null ? "${var.name}-chatbot" : "chatbot-role"
  configuration_name = var.slack_channel_configuration_name
  slack_channel_id   = var.slack_channel_id
  slack_workspace_id = var.slack_workspace_id
  sns_topic_arns     = var.sns_topic_arns
  guardrail_policies = var.guardrail_policies
  user_role_required = var.user_role_required
  logging_level      = var.logging_level

  chatbot_role_name = local.enabled ? coalesce(var.chatbot_role_name, local._chatbot_role_id) : null

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
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
  policy_arn = "arn:aws:iam::aws:policy/AWSResourceExplorerReadOnlyAccess"

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_chatbot_slack_channel_configuration" "this" {
  configuration_name    = local.configuration_name
  slack_channel_id      = local.slack_channel_id
  slack_team_id         = local.slack_workspace_id
  iam_role_arn          = aws_iam_role.chatbot.arn
  sns_topic_arns        = local.sns_topic_arns
  guardrail_policy_arns = local.guardrail_policies
  logging_level         = local.logging_level

  user_authorization_required = local.user_role_required

  tags = local.tags

  lifecycle {
    enabled = local.enabled
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

  guardrail_policy_arns       = var.teams_guardrail_policies
  logging_level               = var.teams_logging_level
  user_authorization_required = var.teams_user_role_required

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_teams_configuration
  }
}
