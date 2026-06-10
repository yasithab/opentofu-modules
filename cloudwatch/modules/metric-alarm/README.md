# CloudWatch Metric Alarm

OpenTofu module to create an AWS CloudWatch Metric Alarm. Supports standard metric alarms, anomaly detection, and metric math expressions via `metric_query`.

## Features

- **Standard Metric Alarms** - Monitor a single CloudWatch metric with configurable threshold, comparison operator, and evaluation periods
- **Metric Math Expressions** - Create alarms based on metric math expressions using the `metric_query` parameter
- **Anomaly Detection** - Support for anomaly detection band alarms via `threshold_metric_id`
- **Action Configuration** - Attach SNS topics or other actions to ALARM, OK, and INSUFFICIENT_DATA state transitions
- **Missing Data Handling** - Configure how missing data points are treated (missing, ignore, breaching, notBreaching)
- **Lifecycle Management** - Toggle resource creation with the `enabled` variable

## Usage

```hcl
module "cpu_alarm" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/metric-alarm?depth=1&ref=master"

  name                = "high-cpu-utilization"
  alarm_description   = "CPU utilization exceeded 80%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  threshold           = 80

  metric_name = "CPUUtilization"
  namespace   = "AWS/EC2"
  period      = 300
  statistic   = "Average"

  dimensions = {
    InstanceId = "i-0123456789abcdef0"
  }

  alarm_actions = ["arn:aws:sns:us-east-1:123456789012:my-topic"]

  tags = {
    Environment = "production"
  }
}
```

### Metric Math Expression

```hcl
module "error_rate_alarm" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/metric-alarm?depth=1&ref=master"

  name                = "high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 5

  metric_query = [
    {
      id          = "error_rate"
      expression  = "errors / requests * 100"
      label       = "Error Rate"
      return_data = true
    },
    {
      id = "errors"
      metric = {
        metric_name = "5XXError"
        namespace   = "AWS/ApiGateway"
        period      = 300
        stat        = "Sum"
      }
    },
    {
      id = "requests"
      metric = {
        metric_name = "Count"
        namespace   = "AWS/ApiGateway"
        period      = 300
        stat        = "Sum"
      }
    }
  ]
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
| actions\_enabled | Indicates whether actions should be executed during any changes to the alarm's state. | `bool` | `true` | no |
| alarm\_actions | The list of actions to execute when this alarm transitions into an ALARM state from any other state. | `list(string)` | `null` | no |
| alarm\_description | The description for the alarm. | `string` | `null` | no |
| comparison\_operator | The arithmetic operation to use when comparing the specified statistic and threshold. | `string` | n/a | yes |
| datapoints\_to\_alarm | The number of datapoints that must be breaching to trigger the alarm. | `number` | `null` | no |
| dimensions | The dimensions for the alarm's associated metric. | `map(string)` | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| evaluate\_low\_sample\_count\_percentiles | Used only for alarms based on percentiles. Valid values: evaluate, ignore. | `string` | `null` | no |
| evaluation\_periods | The number of periods over which data is compared to the specified threshold. | `number` | n/a | yes |
| extended\_statistic | The percentile statistic for the metric associated with the alarm (e.g. p99.9). | `string` | `null` | no |
| insufficient\_data\_actions | The list of actions to execute when this alarm transitions into an INSUFFICIENT\_DATA state from any other state. | `list(string)` | `null` | no |
| metric\_name | The name for the alarm's associated metric. | `string` | `null` | no |
| metric\_query | Enables you to create an alarm based on a metric math expression. A list of metric query objects. | <pre>list(object({<br/>    id          = string<br/>    account_id  = optional(string)<br/>    expression  = optional(string)<br/>    label       = optional(string)<br/>    return_data = optional(bool)<br/>    period      = optional(number)<br/>    metric = optional(object({<br/>      metric_name = string<br/>      namespace   = string<br/>      period      = number<br/>      stat        = string<br/>      unit        = optional(string)<br/>      dimensions  = optional(map(string))<br/>    }))<br/>  }))</pre> | `[]` | no |
| name | The descriptive name for the alarm. | `string` | n/a | yes |
| namespace | The namespace for the alarm's associated metric. | `string` | `null` | no |
| ok\_actions | The list of actions to execute when this alarm transitions into an OK state from any other state. | `list(string)` | `null` | no |
| period | The period in seconds over which the specified statistic is applied. | `number` | `null` | no |
| statistic | The statistic to apply to the alarm's associated metric. Valid values: SampleCount, Average, Sum, Minimum, Maximum. | `string` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| threshold | The value against which the specified statistic is compared. Required if metric\_query is not provided. | `number` | `null` | no |
| threshold\_metric\_id | If this is an alarm based on an anomaly detection model, make this value match the ID of the ANOMALY\_DETECTION\_BAND function. | `string` | `null` | no |
| treat\_missing\_data | Sets how this alarm is to handle missing data points. | `string` | `"missing"` | no |
| unit | The unit for the alarm's associated metric. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| alarm\_arn | The ARN of the CloudWatch Metric Alarm. |
| alarm\_id | The ID of the CloudWatch Metric Alarm. |
| alarm\_name | The name of the CloudWatch Metric Alarm. |
<!-- END_TF_DOCS -->
