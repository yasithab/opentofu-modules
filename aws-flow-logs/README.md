<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.34 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.34 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudwatch_log_group_class"></a> [cloudwatch\_log\_group\_class](#input\_cloudwatch\_log\_group\_class) | Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT\_ACCESS | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#input\_cloudwatch\_log\_group\_name) | Name of the CloudWatch Log Group (only used when log\_destination\_type is 'cloud-watch-logs' and log\_destination is not specified) | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_skip_destroy"></a> [cloudwatch\_log\_group\_skip\_destroy](#input\_cloudwatch\_log\_group\_skip\_destroy) | Set to true if you do not want to destroy the log group at destroy time, and instead just remove the log group from the Terraform state | `bool` | `false` | no |
| <a name="input_cloudwatch_log_kms_key_id"></a> [cloudwatch\_log\_kms\_key\_id](#input\_cloudwatch\_log\_kms\_key\_id) | ARN of the KMS key to use for encrypting CloudWatch Logs | `string` | `null` | no |
| <a name="input_cloudwatch_log_retention_in_days"></a> [cloudwatch\_log\_retention\_in\_days](#input\_cloudwatch\_log\_retention\_in\_days) | Number of days to retain logs in CloudWatch Logs | `number` | `30` | no |
| <a name="input_deliver_cross_account_role"></a> [deliver\_cross\_account\_role](#input\_deliver\_cross\_account\_role) | ARN of the IAM role that allows publishing flow logs across accounts | `string` | `null` | no |
| <a name="input_destination_options"></a> [destination\_options](#input\_destination\_options) | Destination options for flow logs (only applicable when log\_destination\_type is 's3') | <pre>object({<br/>    file_format                = optional(string, "plain-text")<br/>    hive_compatible_partitions = optional(bool, false)<br/>    per_hour_partition         = optional(bool, false)<br/>  })</pre> | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to enable VPC Flow Logs | `bool` | `true` | no |
| <a name="input_eni_id"></a> [eni\_id](#input\_eni\_id) | Elastic Network Interface ID to attach to (mutually exclusive with other attachment options) | `string` | `null` | no |
| <a name="input_iam_policy_name"></a> [iam\_policy\_name](#input\_iam\_policy\_name) | Name of the IAM policy to create (only used when log\_destination\_type is 'cloud-watch-logs' and iam\_role\_arn is not specified) | `string` | `null` | no |
| <a name="input_iam_role_arn"></a> [iam\_role\_arn](#input\_iam\_role\_arn) | ARN of an existing IAM role for posting logs to CloudWatch Logs (only used when log\_destination\_type is 'cloud-watch-logs') | `string` | `null` | no |
| <a name="input_iam_role_name"></a> [iam\_role\_name](#input\_iam\_role\_name) | Name of the IAM role to create (only used when log\_destination\_type is 'cloud-watch-logs' and iam\_role\_arn is not specified) | `string` | `null` | no |
| <a name="input_kinesis_firehose_delivery_stream_arn"></a> [kinesis\_firehose\_delivery\_stream\_arn](#input\_kinesis\_firehose\_delivery\_stream\_arn) | ARN of the Kinesis Firehose delivery stream (only used when log\_destination\_type is 'kinesis-data-firehose' and log\_destination is not specified) | `string` | `null` | no |
| <a name="input_log_destination"></a> [log\_destination](#input\_log\_destination) | ARN of the logging destination. If not specified, a default destination will be created based on log\_destination\_type | `string` | `null` | no |
| <a name="input_log_destination_type"></a> [log\_destination\_type](#input\_log\_destination\_type) | The type of the logging destination. Valid values: cloud-watch-logs, s3, kinesis-data-firehose | `string` | `"cloud-watch-logs"` | no |
| <a name="input_log_format"></a> [log\_format](#input\_log\_format) | The fields to include in the flow log record. See AWS documentation for format syntax | `string` | `null` | no |
| <a name="input_max_aggregation_interval"></a> [max\_aggregation\_interval](#input\_max\_aggregation\_interval) | The maximum interval of time (in seconds) during which a flow of packets is captured and aggregated into a flow log record. Valid values: 60, 600 | `number` | `60` | no |
| <a name="input_name"></a> [name](#input\_name) | Name tag for the Flow Log resource | `string` | `null` | no |
| <a name="input_regional_nat_gateway_id"></a> [regional\_nat\_gateway\_id](#input\_regional\_nat\_gateway\_id) | Regional NAT Gateway ID to attach to (mutually exclusive with other attachment options) | `string` | `null` | no |
| <a name="input_s3_bucket_arn"></a> [s3\_bucket\_arn](#input\_s3\_bucket\_arn) | ARN of the S3 bucket (only used when log\_destination\_type is 's3' and log\_destination is not specified) | `string` | `null` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID to attach to (mutually exclusive with other attachment options) | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_traffic_type"></a> [traffic\_type](#input\_traffic\_type) | The type of traffic to capture. Valid values: ACCEPT, REJECT, ALL | `string` | `"ALL"` | no |
| <a name="input_transit_gateway_attachment_id"></a> [transit\_gateway\_attachment\_id](#input\_transit\_gateway\_attachment\_id) | Transit Gateway Attachment ID to attach to (mutually exclusive with other attachment options) | `string` | `null` | no |
| <a name="input_transit_gateway_id"></a> [transit\_gateway\_id](#input\_transit\_gateway\_id) | Transit Gateway ID to attach to (mutually exclusive with other attachment options) | `string` | `null` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC to attach to (mutually exclusive with other attachment options) | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | The ARN of the CloudWatch Log Group created for flow logs (if applicable) |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | The name of the CloudWatch Log Group created for flow logs (if applicable) |
| <a name="output_flow_log_arn"></a> [flow\_log\_arn](#output\_flow\_log\_arn) | The ARN of the Flow Log resource |
| <a name="output_flow_log_id"></a> [flow\_log\_id](#output\_flow\_log\_id) | The ID of the Flow Log resource |
| <a name="output_iam_policy_arn"></a> [iam\_policy\_arn](#output\_iam\_policy\_arn) | The ARN of the IAM policy created for flow logs (if applicable) |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | The ARN of the IAM role created for flow logs (if applicable) |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | The name of the IAM role created for flow logs (if applicable) |
| <a name="output_kinesis_firehose_arn"></a> [kinesis\_firehose\_arn](#output\_kinesis\_firehose\_arn) | The ARN of the Kinesis Firehose delivery stream used for flow logs (if applicable) |
| <a name="output_log_destination"></a> [log\_destination](#output\_log\_destination) | The final destination ARN used for flow logs (either specified or created) |
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | The ARN of the S3 bucket used for flow logs (if applicable) |
<!-- END_TF_DOCS -->