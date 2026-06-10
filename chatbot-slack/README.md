# AWS Chatbot Slack

Provisions AWS Chatbot channel configurations for Slack and Microsoft Teams, with a dedicated IAM role, SNS topic integration, and configurable guardrail policies.

## Features

- **Slack Channel Configuration** - Creates an AWS Chatbot Slack channel configuration with SNS topic subscriptions for delivering notifications (e.g., CloudWatch alarms) directly to Slack
- **Microsoft Teams Support** - Optionally creates a Teams channel configuration alongside Slack, sharing the same IAM role for unified notification delivery across both platforms
- **IAM Role Management** - Provisions a dedicated IAM role with the `AWSResourceExplorerReadOnlyAccess` policy for Chatbot to interact with AWS resources
- **Guardrail Policies** - Restricts which AWS actions Chatbot users can invoke from chat channels using configurable IAM policy guardrails
- **Configurable Logging** - Supports ERROR, INFO, or NONE logging levels, pushing log entries to Amazon CloudWatch Logs for audit and troubleshooting
- **Feature Flag** - Toggle all resource creation on or off with the `enabled` variable for per-environment control

## Notes

- **Security / BREAKING-ish**: when `guardrail_policies` (or `teams_guardrail_policies`)
  is not set, the module now applies the partition-aware AWS managed `ReadOnlyAccess`
  policy as the channel guardrail. Previously no guardrail was sent, in which case AWS
  Chatbot itself falls back to `AdministratorAccess`. If you relied on that implicit
  admin guardrail, set `guardrail_policies` explicitly.
- `logging_level` (and `teams_logging_level`) now default to `"ERROR"` instead of
  `"NONE"` so misconfigurations surface in CloudWatch Logs.
- `slack_channel_id`, `slack_workspace_id`, `teams_channel_id`, `teams_team_id`, and
  `teams_tenant_id` are marked `sensitive`.
- IAM managed-policy ARNs are built with the current AWS partition (`aws`, `aws-cn`,
  `aws-us-gov`).

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


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11.0 |
| aws | >= 6.49, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| chatbot\_role\_name | Override for the Chatbot IAM role name. Defaults to <name>-chatbot or chatbot-role. | `string` | `null` | no |
| create\_teams\_configuration | Whether to create a Microsoft Teams channel configuration alongside the Slack configuration | `bool` | `false` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| guardrail\_policies | The list of IAM policy ARNs that are applied as channel guardrails. Defaults to the partition-aware AWS managed 'ReadOnlyAccess' policy when not set (AWS Chatbot's own fallback is AdministratorAccess, which is too broad) | `list(string)` | `null` | no |
| logging\_level | Specifies the logging level for this configuration: ERROR, INFO or NONE. This property affects the log entries pushed to Amazon CloudWatch logs | `string` | `"ERROR"` | no |
| name | Name to use for resource naming and tagging. | `string` | `null` | no |
| slack\_channel\_configuration\_name | The name of the Slack channel configuration. Required when enabled = true. | `string` | `null` | no |
| slack\_channel\_id | The ID of the Slack channel. Required when enabled = true. | `string` | `null` | no |
| slack\_workspace\_id | The ID of the Slack workspace (team) authorized with AWS Chatbot. Maps to the slack\_team\_id argument in the AWS provider (e.g., T07EA123LEP). Required when enabled = true. | `string` | `null` | no |
| sns\_topic\_arns | ARNs of SNS topics which deliver notifications to AWS Chatbot, for example CloudWatch alarm notifications | `list(string)` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| teams\_channel\_id | The ID of the Microsoft Teams channel | `string` | `null` | no |
| teams\_channel\_name | The name of the Microsoft Teams channel | `string` | `null` | no |
| teams\_configuration\_name | The name of the Microsoft Teams channel configuration | `string` | `null` | no |
| teams\_guardrail\_policies | List of IAM policy ARNs applied as guardrails for the Teams channel. Defaults to the partition-aware AWS managed 'ReadOnlyAccess' policy when not set | `list(string)` | `null` | no |
| teams\_logging\_level | Logging level for the Teams channel configuration: ERROR, INFO or NONE | `string` | `"ERROR"` | no |
| teams\_sns\_topic\_arns | ARNs of SNS topics for the Teams channel configuration | `list(string)` | `null` | no |
| teams\_team\_id | The ID of the Microsoft Teams team | `string` | `null` | no |
| teams\_team\_name | The name of the Microsoft Teams team | `string` | `null` | no |
| teams\_tenant\_id | The ID of the Microsoft Teams tenant | `string` | `null` | no |
| teams\_user\_role\_required | Enables use of a user role requirement in your Teams chat configuration | `bool` | `false` | no |
| user\_role\_required | Enables use of a user role requirement in your chat configuration | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| chatbot\_role\_arn | ARN of the IAM role used by AWS Chatbot |
| chatbot\_role\_name | Name of the IAM role used by AWS Chatbot |
| slack\_configuration\_arn | Amazon Resource Name (ARN) of the Slack channel configuration |
| slack\_configuration\_id | ID of the Slack channel configuration (ARN) |
| teams\_configuration\_arn | Amazon Resource Name (ARN) of the Teams channel configuration |
| teams\_configuration\_id | ID of the Teams channel configuration (ARN) |
<!-- END_TF_DOCS -->

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
