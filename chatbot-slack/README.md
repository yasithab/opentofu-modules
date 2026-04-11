# AWS Chatbot Slack

Provisions AWS Chatbot channel configurations for Slack and Microsoft Teams, with a dedicated IAM role, SNS topic integration, and configurable guardrail policies.

## Features

- **Slack Channel Configuration** - Creates an AWS Chatbot Slack channel configuration with SNS topic subscriptions for delivering notifications (e.g., CloudWatch alarms) directly to Slack
- **Microsoft Teams Support** - Optionally creates a Teams channel configuration alongside Slack, sharing the same IAM role for unified notification delivery across both platforms
- **IAM Role Management** - Provisions a dedicated IAM role with the `AWSResourceExplorerReadOnlyAccess` policy for Chatbot to interact with AWS resources
- **Guardrail Policies** - Restricts which AWS actions Chatbot users can invoke from chat channels using configurable IAM policy guardrails
- **Configurable Logging** - Supports ERROR, INFO, or NONE logging levels, pushing log entries to Amazon CloudWatch Logs for audit and troubleshooting
- **Feature Flag** - Toggle all resource creation on or off with the `enabled` variable for per-environment control

## Usage

```hcl
module "chatbot_slack" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//chatbot-slack?depth=1&ref=master"

  name = "platform-alerts"

  slack_channel_configuration_name = "platform-alerts-slack"
  slack_channel_id                 = "C04AB1CDEFG"
  slack_workspace_id               = "T07EA123LEP"

  sns_topic_arns = [
    "arn:aws:sns:us-east-1:123456789012:platform-cloudwatch-alarms",
  ]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```


## Examples

## Basic Usage

Sends CloudWatch alarm notifications from an SNS topic to a single Slack channel.

```hcl
module "chatbot_slack" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//chatbot-slack?depth=1&ref=master"

  enabled = true
  name    = "platform-alerts"

  slack_channel_configuration_name = "platform-alerts-slack"
  slack_channel_id                  = "C04AB1CDEFG"
  slack_workspace_id                = "T07EA123LEP"

  sns_topic_arns = [
    "arn:aws:sns:us-east-1:123456789012:platform-cloudwatch-alarms",
  ]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## With Guardrail Policies and Logging

Restricts what AWS actions Chatbot users can invoke from Slack and enables INFO-level logging for audit purposes.

```hcl
module "chatbot_slack_restricted" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//chatbot-slack?depth=1&ref=master"

  enabled = true
  name    = "ops-channel"

  slack_channel_configuration_name = "ops-channel-slack"
  slack_channel_id                  = "C08XY9ZABCD"
  slack_workspace_id                = "T07EA123LEP"

  sns_topic_arns = [
    "arn:aws:sns:us-east-1:123456789012:ops-alerts",
    "arn:aws:sns:us-east-1:123456789012:security-alerts",
  ]

  guardrail_policies = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
  ]

  logging_level      = "INFO"
  user_role_required = true

  tags = {
    Environment = "production"
    Team        = "operations"
  }
}
```

## With Microsoft Teams Configuration

Creates both a Slack channel configuration and a Microsoft Teams channel configuration sharing the same IAM role, useful when notifications must reach both collaboration platforms.

```hcl
module "chatbot_multi_channel" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//chatbot-slack?depth=1&ref=master"

  enabled = true
  name    = "incidents"

  # Slack
  slack_channel_configuration_name = "incidents-slack"
  slack_channel_id                  = "C01INCIDENT1"
  slack_workspace_id                = "T07EA123LEP"
  sns_topic_arns = [
    "arn:aws:sns:us-east-1:123456789012:incident-alerts",
  ]
  logging_level = "ERROR"

  # Microsoft Teams
  create_teams_configuration = true
  teams_configuration_name   = "incidents-teams"
  teams_tenant_id            = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
  teams_team_id              = "19:abcdef1234567890abcdef1234567890@thread.skype"
  teams_team_name            = "Incidents"
  teams_channel_id           = "19:xyz123abc456def789@thread.skype"
  teams_channel_name         = "incident-alerts"
  teams_sns_topic_arns = [
    "arn:aws:sns:us-east-1:123456789012:incident-alerts",
  ]
  teams_logging_level = "ERROR"

  tags = {
    Environment = "production"
    Team        = "sre"
  }
}
```

## Disabled (Feature Flag)

Declares the module without creating any resources, useful for toggling notifications per environment.

```hcl
module "chatbot_slack_dev" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//chatbot-slack?depth=1&ref=master"

  enabled = false
  name    = "dev-alerts"

  slack_channel_configuration_name = "dev-alerts-slack"
  slack_channel_id                  = "C09DEVTEST1"
  slack_workspace_id                = "T07EA123LEP"

  tags = {
    Environment = "development"
    Team        = "platform"
  }
}
```
