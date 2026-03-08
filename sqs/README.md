<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.34 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.35.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_content_based_deduplication"></a> [content\_based\_deduplication](#input\_content\_based\_deduplication) | Enables content-based deduplication for FIFO queues | `bool` | `false` | no |
| <a name="input_create_queue_policy"></a> [create\_queue\_policy](#input\_create\_queue\_policy) | Whether to create SQS queue policy | `bool` | `false` | no |
| <a name="input_create_redrive_allow_policy"></a> [create\_redrive\_allow\_policy](#input\_create\_redrive\_allow\_policy) | Whether to create an SQS queue redrive allow policy to control which source queues can use this queue as a dead-letter queue | `bool` | `false` | no |
| <a name="input_deadletter_override_policy_documents"></a> [deadletter\_override\_policy\_documents](#input\_deadletter\_override\_policy\_documents) | List of IAM policy documents that override for the dead letter queue policy (only used when deadletter\_queue\_policy\_statements is provided) | `list(string)` | `[]` | no |
| <a name="input_deadletter_queue_count"></a> [deadletter\_queue\_count](#input\_deadletter\_queue\_count) | Deadletter queue max receive count when `var.deadletter_queue_enabled` is true | `number` | `5` | no |
| <a name="input_deadletter_queue_enabled"></a> [deadletter\_queue\_enabled](#input\_deadletter\_queue\_enabled) | Option whether to enable deadletter queue, This option overides `var.redrive_policy` | `bool` | `false` | no |
| <a name="input_deadletter_queue_policy_enabled"></a> [deadletter\_queue\_policy\_enabled](#input\_deadletter\_queue\_policy\_enabled) | Whether to create a policy for the dead letter queue. When true and no custom DLQ statements are provided, the source queue policy is automatically copied to the DLQ. | `bool` | `false` | no |
| <a name="input_deadletter_queue_policy_statements"></a> [deadletter\_queue\_policy\_statements](#input\_deadletter\_queue\_policy\_statements) | Custom IAM policy statements for the dead letter queue. When empty and deadletter\_queue\_policy\_enabled is true, the main queue's policy statements are used instead. | `any` | `[]` | no |
| <a name="input_deadletter_source_policy_documents"></a> [deadletter\_source\_policy\_documents](#input\_deadletter\_source\_policy\_documents) | List of IAM policy documents to merge for the dead letter queue policy (only used when deadletter\_queue\_policy\_statements is provided) | `list(string)` | `[]` | no |
| <a name="input_delay_seconds"></a> [delay\_seconds](#input\_delay\_seconds) | The time in seconds that the delivery of all messages in the queue will be delayed. An integer from 0 to 900 (15 minutes) | `number` | `0` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_fifo_high_throughput_deduplication_scope"></a> [fifo\_high\_throughput\_deduplication\_scope](#input\_fifo\_high\_throughput\_deduplication\_scope) | (Optional) Specifies whether message deduplication occurs at the message group or queue level. Valid values are messageGroup and queue (default) | `string` | `"messageGroup"` | no |
| <a name="input_fifo_high_throughput_limit"></a> [fifo\_high\_throughput\_limit](#input\_fifo\_high\_throughput\_limit) | (Optional) Specifies whether the FIFO queue throughput quota applies to the entire queue or per message group. Valid values are perQueue (default) and perMessageGroupId | `string` | `"perMessageGroupId"` | no |
| <a name="input_fifo_queue"></a> [fifo\_queue](#input\_fifo\_queue) | Boolean designating a FIFO queue | `bool` | `false` | no |
| <a name="input_high_throughput_fifo_queue"></a> [high\_throughput\_fifo\_queue](#input\_high\_throughput\_fifo\_queue) | Boolean designating a high-throughput FIFO queue | `bool` | `false` | no |
| <a name="input_kms_data_key_reuse_period_seconds"></a> [kms\_data\_key\_reuse\_period\_seconds](#input\_kms\_data\_key\_reuse\_period\_seconds) | The length of time, in seconds, for which Amazon SQS can reuse a data key to encrypt or decrypt messages before calling AWS KMS again. An integer representing seconds, between 60 seconds (1 minute) and 86,400 seconds (24 hours) | `number` | `300` | no |
| <a name="input_kms_master_key_id"></a> [kms\_master\_key\_id](#input\_kms\_master\_key\_id) | The ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK | `string` | `null` | no |
| <a name="input_max_message_size"></a> [max\_message\_size](#input\_max\_message\_size) | The limit of how many bytes a message can contain before Amazon SQS rejects it. An integer from 1024 bytes (1 KiB) up to 262144 bytes (256 KiB) | `number` | `262144` | no |
| <a name="input_message_retention_seconds"></a> [message\_retention\_seconds](#input\_message\_retention\_seconds) | The number of seconds Amazon SQS retains a message. Integer representing seconds, from 60 (1 minute) to 1209600 (14 days) | `number` | `604800` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to use for resource naming and tagging. | `string` | `null` | no |
| <a name="input_override_queue_policy_documents"></a> [override\_queue\_policy\_documents](#input\_override\_queue\_policy\_documents) | List of IAM policy documents that are merged together into the exported document. In merging, statements with non-blank `sid`s will override statements with the same `sid` | `list(string)` | `[]` | no |
| <a name="input_queue_policy_statements"></a> [queue\_policy\_statements](#input\_queue\_policy\_statements) | A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage | `any` | `{}` | no |
| <a name="input_receive_wait_time_seconds"></a> [receive\_wait\_time\_seconds](#input\_receive\_wait\_time\_seconds) | The time for which a ReceiveMessage call will wait for a message to arrive (long polling) before returning. An integer from 0 to 20 (seconds) | `number` | `0` | no |
| <a name="input_redrive_allow_policy_permission"></a> [redrive\_allow\_policy\_permission](#input\_redrive\_allow\_policy\_permission) | Permission type for the redrive allow policy. Valid values: allowAll, denyAll, byQueue | `string` | `"denyAll"` | no |
| <a name="input_redrive_allow_policy_source_queue_arns"></a> [redrive\_allow\_policy\_source\_queue\_arns](#input\_redrive\_allow\_policy\_source\_queue\_arns) | List of source queue ARNs allowed to use this queue as a dead-letter queue. Only used when redrive\_allow\_policy\_permission is byQueue | `list(string)` | `[]` | no |
| <a name="input_redrive_policy"></a> [redrive\_policy](#input\_redrive\_policy) | The JSON policy to set up the Dead Letter Queue, see AWS docs. Note: when specifying maxReceiveCount, you must specify it as an integer (5), and not a string ("5") | `string` | `null` | no |
| <a name="input_source_queue_policy_documents"></a> [source\_queue\_policy\_documents](#input\_source\_queue\_policy\_documents) | List of IAM policy documents that are merged together into the exported document. Statements must have unique `sid`s | `list(string)` | `[]` | no |
| <a name="input_sqs_managed_sse_enabled"></a> [sqs\_managed\_sse\_enabled](#input\_sqs\_managed\_sse\_enabled) | Enable server-side encryption (SSE) of message content with SQS-owned encryption keys | `bool` | `true` | no |
| <a name="input_sqs_queue_name"></a> [sqs\_queue\_name](#input\_sqs\_queue\_name) | Name of the SQS queue | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_visibility_timeout_seconds"></a> [visibility\_timeout\_seconds](#input\_visibility\_timeout\_seconds) | The visibility timeout for the queue. An integer from 0 to 43200 (12 hours) | `number` | `30` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the SQS queue |
| <a name="output_dlq_arn"></a> [dlq\_arn](#output\_dlq\_arn) | The ARN of the dead letter queue |
| <a name="output_dlq_id"></a> [dlq\_id](#output\_dlq\_id) | The URL for the created dead letter queue |
| <a name="output_id"></a> [id](#output\_id) | The URL for the created Amazon SQS queue |
<!-- END_TF_DOCS -->