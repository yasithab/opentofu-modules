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

  alarm_name          = "high-cpu-utilization"
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

  alarm_name          = "high-error-rate"
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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `alarm_name` | The descriptive name for the alarm | `string` | n/a | yes |
| `comparison_operator` | The arithmetic operation to use when comparing the specified statistic and threshold | `string` | n/a | yes |
| `evaluation_periods` | The number of periods over which data is compared to the specified threshold | `number` | n/a | yes |
| `alarm_description` | The description for the alarm | `string` | `null` | no |
| `threshold` | The value against which the specified statistic is compared | `number` | `null` | no |
| `threshold_metric_id` | ID of the ANOMALY_DETECTION_BAND function for anomaly detection alarms | `string` | `null` | no |
| `metric_name` | The name for the alarm's associated metric | `string` | `null` | no |
| `namespace` | The namespace for the alarm's associated metric | `string` | `null` | no |
| `period` | The period in seconds over which the specified statistic is applied | `number` | `null` | no |
| `statistic` | The statistic to apply to the alarm's associated metric (SampleCount, Average, Sum, Minimum, Maximum) | `string` | `null` | no |
| `extended_statistic` | The percentile statistic for the metric (e.g., p99.9) | `string` | `null` | no |
| `dimensions` | The dimensions for the alarm's associated metric | `map(string)` | `null` | no |
| `actions_enabled` | Whether actions should be executed during state changes | `bool` | `true` | no |
| `alarm_actions` | Actions to execute on ALARM state transition | `list(string)` | `null` | no |
| `ok_actions` | Actions to execute on OK state transition | `list(string)` | `null` | no |
| `insufficient_data_actions` | Actions to execute on INSUFFICIENT_DATA state transition | `list(string)` | `null` | no |
| `datapoints_to_alarm` | The number of datapoints that must be breaching to trigger the alarm | `number` | `null` | no |
| `treat_missing_data` | How to handle missing data points (missing, ignore, breaching, notBreaching) | `string` | `"missing"` | no |
| `evaluate_low_sample_count_percentiles` | Used only for percentile-based alarms (evaluate, ignore) | `string` | `null` | no |
| `metric_query` | List of metric query objects for metric math expression alarms | `any` | `[]` | no |
| `unit` | The unit for the alarm's associated metric | `string` | `null` | no |
| `enabled` | Set to false to prevent the module from creating any resources | `bool` | `true` | no |
| `tags` | Map of tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `alarm_arn` | The ARN of the CloudWatch Metric Alarm |
| `alarm_id` | The ID of the CloudWatch Metric Alarm |
| `alarm_name` | The name of the CloudWatch Metric Alarm |
