<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.11.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.39.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.39.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_name"></a> [alarm\_name](#input\_alarm\_name) | The descriptive name for the alarm. | `string` | n/a | yes |
| <a name="input_comparison_operator"></a> [comparison\_operator](#input\_comparison\_operator) | The arithmetic operation to use when comparing the specified statistic and threshold. | `string` | n/a | yes |
| <a name="input_evaluation_periods"></a> [evaluation\_periods](#input\_evaluation\_periods) | The number of periods over which data is compared to the specified threshold. | `number` | n/a | yes |
| <a name="input_actions_enabled"></a> [actions\_enabled](#input\_actions\_enabled) | Indicates whether actions should be executed during any changes to the alarm's state. | `bool` | `true` | no |
| <a name="input_alarm_actions"></a> [alarm\_actions](#input\_alarm\_actions) | The list of actions to execute when this alarm transitions into an ALARM state from any other state. | `list(string)` | `null` | no |
| <a name="input_alarm_description"></a> [alarm\_description](#input\_alarm\_description) | The description for the alarm. | `string` | `null` | no |
| <a name="input_datapoints_to_alarm"></a> [datapoints\_to\_alarm](#input\_datapoints\_to\_alarm) | The number of datapoints that must be breaching to trigger the alarm. | `number` | `null` | no |
| <a name="input_dimensions"></a> [dimensions](#input\_dimensions) | The dimensions for the alarm's associated metric. | `map(string)` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_evaluate_low_sample_count_percentiles"></a> [evaluate\_low\_sample\_count\_percentiles](#input\_evaluate\_low\_sample\_count\_percentiles) | Used only for alarms based on percentiles. Valid values: evaluate, ignore. | `string` | `null` | no |
| <a name="input_extended_statistic"></a> [extended\_statistic](#input\_extended\_statistic) | The percentile statistic for the metric associated with the alarm (e.g. p99.9). | `string` | `null` | no |
| <a name="input_insufficient_data_actions"></a> [insufficient\_data\_actions](#input\_insufficient\_data\_actions) | The list of actions to execute when this alarm transitions into an INSUFFICIENT\_DATA state from any other state. | `list(string)` | `null` | no |
| <a name="input_metric_name"></a> [metric\_name](#input\_metric\_name) | The name for the alarm's associated metric. | `string` | `null` | no |
| <a name="input_metric_query"></a> [metric\_query](#input\_metric\_query) | Enables you to create an alarm based on a metric math expression. A list of metric query objects. | `any` | `[]` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The namespace for the alarm's associated metric. | `string` | `null` | no |
| <a name="input_ok_actions"></a> [ok\_actions](#input\_ok\_actions) | The list of actions to execute when this alarm transitions into an OK state from any other state. | `list(string)` | `null` | no |
| <a name="input_period"></a> [period](#input\_period) | The period in seconds over which the specified statistic is applied. | `number` | `null` | no |
| <a name="input_statistic"></a> [statistic](#input\_statistic) | The statistic to apply to the alarm's associated metric. Valid values: SampleCount, Average, Sum, Minimum, Maximum. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_threshold"></a> [threshold](#input\_threshold) | The value against which the specified statistic is compared. Required if metric\_query is not provided. | `number` | `null` | no |
| <a name="input_threshold_metric_id"></a> [threshold\_metric\_id](#input\_threshold\_metric\_id) | If this is an alarm based on an anomaly detection model, make this value match the ID of the ANOMALY\_DETECTION\_BAND function. | `string` | `null` | no |
| <a name="input_treat_missing_data"></a> [treat\_missing\_data](#input\_treat\_missing\_data) | Sets how this alarm is to handle missing data points. | `string` | `"missing"` | no |
| <a name="input_unit"></a> [unit](#input\_unit) | The unit for the alarm's associated metric. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alarm_arn"></a> [alarm\_arn](#output\_alarm\_arn) | The ARN of the CloudWatch Metric Alarm. |
| <a name="output_alarm_id"></a> [alarm\_id](#output\_alarm\_id) | The ID of the CloudWatch Metric Alarm. |
| <a name="output_alarm_name"></a> [alarm\_name](#output\_alarm\_name) | The name of the CloudWatch Metric Alarm. |
<!-- END_TF_DOCS -->
