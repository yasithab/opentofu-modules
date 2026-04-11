# CloudWatch Composite Alarm

OpenTofu module to create an AWS CloudWatch Composite Alarm. Composite alarms combine multiple metric alarms using boolean logic to reduce alarm noise and focus on actionable conditions.

## Features

- **Boolean Alarm Rules** - Combine multiple alarms using AND, OR, and NOT operators in alarm rule expressions
- **Action Configuration** - Attach SNS topics or other actions to ALARM, OK, and INSUFFICIENT_DATA state transitions
- **Actions Suppressor** - Suppress alarm actions using a suppressor alarm with configurable wait and extension periods
- **Lifecycle Management** - Toggle resource creation with the `enabled` variable

## Usage

```hcl
module "composite_alarm" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/composite-alarm?depth=1&ref=master"

  alarm_name        = "service-degraded"
  alarm_description = "Both CPU and memory are in alarm state"
  alarm_rule        = "ALARM(high-cpu-alarm) AND ALARM(high-memory-alarm)"

  alarm_actions = ["arn:aws:sns:us-east-1:123456789012:critical-alerts"]

  tags = {
    Environment = "production"
  }
}
```

### With Actions Suppressor

```hcl
module "composite_alarm" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/composite-alarm?depth=1&ref=master"

  alarm_name = "service-degraded"
  alarm_rule = "ALARM(high-cpu-alarm) OR ALARM(high-memory-alarm)"

  alarm_actions = ["arn:aws:sns:us-east-1:123456789012:critical-alerts"]

  actions_suppressor = {
    alarm            = "arn:aws:cloudwatch:us-east-1:123456789012:alarm:maintenance-window"
    extension_period = 60
    wait_period      = 120
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `alarm_name` | The name for the composite alarm (must be unique within the region) | `string` | n/a | yes |
| `alarm_rule` | Expression specifying which alarms to evaluate (e.g., `ALARM(my-alarm-1) OR ALARM(my-alarm-2)`) | `string` | n/a | yes |
| `alarm_description` | The description for the composite alarm | `string` | `null` | no |
| `actions_enabled` | Whether actions should be executed during state changes | `bool` | `true` | no |
| `alarm_actions` | Actions to execute on ALARM state transition (max 5 ARNs) | `list(string)` | `null` | no |
| `ok_actions` | Actions to execute on OK state transition (max 5 ARNs) | `list(string)` | `null` | no |
| `insufficient_data_actions` | Actions to execute on INSUFFICIENT_DATA state transition (max 5 ARNs) | `list(string)` | `null` | no |
| `actions_suppressor` | Configuration for actions suppression (alarm ARN, extension_period, wait_period) | `object` | `null` | no |
| `enabled` | Set to false to prevent the module from creating any resources | `bool` | `true` | no |
| `tags` | Map of tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `alarm_arn` | The ARN of the composite alarm |
| `alarm_id` | The ID of the composite alarm |
| `alarm_name` | The name of the composite alarm |
