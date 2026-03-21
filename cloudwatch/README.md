<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.11.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.37.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.37.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_log_group_name"></a> [log\_group\_name](#input\_log\_group\_name) | The name of the CloudWatch Log Group to create. | `string` | n/a | yes |
| <a name="input_create_log_streams"></a> [create\_log\_streams](#input\_create\_log\_streams) | Whether to create CloudWatch Log Streams. | `bool` | `false` | no |
| <a name="input_deletion_protection_enabled"></a> [deletion\_protection\_enabled](#input\_deletion\_protection\_enabled) | Whether to enable deletion protection on the log group. When enabled, the log group cannot be deleted. | `bool` | `true` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | The ARN of the KMS key to use for encrypting log data. | `string` | `null` | no |
| <a name="input_log_group_class"></a> [log\_group\_class](#input\_log\_group\_class) | The log class of the log group. Valid values: STANDARD, INFREQUENT\_ACCESS. | `string` | `null` | no |
| <a name="input_log_streams"></a> [log\_streams](#input\_log\_streams) | A map of log stream definitions to create. Each key is the log stream name. Optionally set `name` to override the key. | <pre>map(object({<br/>    name = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_retention_in_days"></a> [retention\_in\_days](#input\_retention\_in\_days) | Number of days to retain log events in the log group. Use 0 for infinite retention (never expire). Defaults to 90. | `number` | `90` | no |
| <a name="input_skip_destroy"></a> [skip\_destroy](#input\_skip\_destroy) | Set to true if you do not wish the log group to be deleted at destroy time, and instead just remove the log group from the OpenTofu state. | `bool` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_use_name_prefix"></a> [use\_name\_prefix](#input\_use\_name\_prefix) | Determines whether `log_group_name` is used as a prefix. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_log_group_arn"></a> [log\_group\_arn](#output\_log\_group\_arn) | The ARN of the CloudWatch Log Group. |
| <a name="output_log_group_kms_key_id"></a> [log\_group\_kms\_key\_id](#output\_log\_group\_kms\_key\_id) | The ARN of the KMS key used to encrypt log data. |
| <a name="output_log_group_name"></a> [log\_group\_name](#output\_log\_group\_name) | The name of the CloudWatch Log Group. |
| <a name="output_log_group_retention_in_days"></a> [log\_group\_retention\_in\_days](#output\_log\_group\_retention\_in\_days) | The number of days log events are retained. |
| <a name="output_log_streams"></a> [log\_streams](#output\_log\_streams) | Map of log streams created and their attributes. |
<!-- END_TF_DOCS -->
