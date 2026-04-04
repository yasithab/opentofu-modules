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
| <a name="input_firehose_arn"></a> [firehose\_arn](#input\_firehose\_arn) | ARN of the Amazon Kinesis Firehose delivery stream to use for this metric stream. | `string` | n/a | yes |
| <a name="input_output_format"></a> [output\_format](#input\_output\_format) | Output format for the metric stream. | `string` | n/a | yes |
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | ARN of the IAM role that this metric stream will use to access Amazon Kinesis Firehose resources. | `string` | n/a | yes |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_exclude_filter"></a> [exclude\_filter](#input\_exclude\_filter) | Map of exclusive metric filters. Each key is the namespace (e.g. AWS/EC2), and the value is a map with an optional `metric_names` list. Conflicts with `include_filter`. | `any` | `{}` | no |
| <a name="input_include_filter"></a> [include\_filter](#input\_include\_filter) | Map of inclusive metric filters. Each key is the namespace (e.g. AWS/EC2), and the value is a map with an optional `metric_names` list. Conflicts with `exclude_filter`. | `any` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the CloudWatch Metric Stream. Conflicts with `name_prefix`. At least one of `name` or `name_prefix` must be specified. | `string` | `null` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Creates a unique name beginning with the specified prefix. Conflicts with `name`. At least one of `name` or `name_prefix` must be specified. | `string` | `null` | no |
| <a name="input_statistics_configuration"></a> [statistics\_configuration](#input\_statistics\_configuration) | List of statistics configurations for additional statistics to stream. Each element is a map with `additional_statistics` (list) and `include_metric` (list of maps with `metric_name` and `namespace`). | `any` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_metric_stream_arn"></a> [metric\_stream\_arn](#output\_metric\_stream\_arn) | The ARN of the CloudWatch Metric Stream. |
| <a name="output_metric_stream_creation_date"></a> [metric\_stream\_creation\_date](#output\_metric\_stream\_creation\_date) | The date the metric stream was created. |
| <a name="output_metric_stream_last_update_date"></a> [metric\_stream\_last\_update\_date](#output\_metric\_stream\_last\_update\_date) | The date the metric stream was last updated. |
| <a name="output_metric_stream_name"></a> [metric\_stream\_name](#output\_metric\_stream\_name) | The name of the CloudWatch Metric Stream. |
| <a name="output_metric_stream_state"></a> [metric\_stream\_state](#output\_metric\_stream\_state) | The state of the metric stream (running or stopped). |
<!-- END_TF_DOCS -->
