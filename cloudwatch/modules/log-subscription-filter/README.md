<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.11.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.38.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.38.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_destination_arn"></a> [destination\_arn](#input\_destination\_arn) | The ARN of the destination to deliver matching log events to (Kinesis stream, Lambda function, or Kinesis Data Firehose delivery stream). | `string` | n/a | yes |
| <a name="input_log_group_name"></a> [log\_group\_name](#input\_log\_group\_name) | The name of the log group to associate the subscription filter with. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the CloudWatch Log Subscription Filter. | `string` | n/a | yes |
| <a name="input_distribution"></a> [distribution](#input\_distribution) | The method used to distribute log data to the destination. | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_filter_pattern"></a> [filter\_pattern](#input\_filter\_pattern) | A valid CloudWatch Logs filter pattern for subscribing to a filtered stream of log events. Use empty string to match everything. | `string` | `""` | no |
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | The ARN of an IAM role that grants CloudWatch Logs permissions to deliver ingested log events to the destination. Required for Kinesis stream/Firehose destinations. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_subscription_filter_destination_arn"></a> [subscription\_filter\_destination\_arn](#output\_subscription\_filter\_destination\_arn) | The ARN of the destination for the subscription filter. |
| <a name="output_subscription_filter_log_group_name"></a> [subscription\_filter\_log\_group\_name](#output\_subscription\_filter\_log\_group\_name) | The name of the log group associated with the subscription filter. |
| <a name="output_subscription_filter_name"></a> [subscription\_filter\_name](#output\_subscription\_filter\_name) | The name of the CloudWatch Log Subscription Filter. |
<!-- END_TF_DOCS -->
