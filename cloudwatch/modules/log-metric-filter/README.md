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
| <a name="input_log_group_name"></a> [log\_group\_name](#input\_log\_group\_name) | The name of the log group to associate the metric filter with. | `string` | n/a | yes |
| <a name="input_metric_transformation_name"></a> [metric\_transformation\_name](#input\_metric\_transformation\_name) | The name of the CloudWatch metric to which the monitored log information should be published. | `string` | n/a | yes |
| <a name="input_metric_transformation_namespace"></a> [metric\_transformation\_namespace](#input\_metric\_transformation\_namespace) | The destination namespace of the CloudWatch metric. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the CloudWatch Log Metric Filter. | `string` | n/a | yes |
| <a name="input_pattern"></a> [pattern](#input\_pattern) | A valid CloudWatch Logs filter pattern for extracting metric data out of ingested log events. | `string` | n/a | yes |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_metric_transformation_default_value"></a> [metric\_transformation\_default\_value](#input\_metric\_transformation\_default\_value) | The value to emit when a filter pattern does not match a log event. Conflicts with `metric_transformation_dimensions`. | `string` | `null` | no |
| <a name="input_metric_transformation_dimensions"></a> [metric\_transformation\_dimensions](#input\_metric\_transformation\_dimensions) | Map of fields to use as dimensions for the metric. Conflicts with `metric_transformation_default_value`. | `map(string)` | `null` | no |
| <a name="input_metric_transformation_unit"></a> [metric\_transformation\_unit](#input\_metric\_transformation\_unit) | The unit to assign to the metric. | `string` | `null` | no |
| <a name="input_metric_transformation_value"></a> [metric\_transformation\_value](#input\_metric\_transformation\_value) | The value to publish to the CloudWatch metric. Each log event is assigned this value. | `string` | `"1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_metric_filter_id"></a> [metric\_filter\_id](#output\_metric\_filter\_id) | The ID of the CloudWatch Log Metric Filter. |
| <a name="output_metric_filter_log_group_name"></a> [metric\_filter\_log\_group\_name](#output\_metric\_filter\_log\_group\_name) | The name of the log group associated with the metric filter. |
| <a name="output_metric_filter_name"></a> [metric\_filter\_name](#output\_metric\_filter\_name) | The name of the CloudWatch Log Metric Filter. |
<!-- END_TF_DOCS -->
