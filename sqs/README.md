# SQS

OpenTofu module to create and manage AWS SQS queues with optional dead-letter queues, queue policies, and redrive allow policies.

## Features

- **SQS Queue** - Creates standard or FIFO queues with configurable visibility timeout, message retention, max message size, delay, and long polling
- **Dead-Letter Queue** - Optional built-in DLQ with configurable max receive count, or bring your own redrive policy
- **Queue Policy** - Flexible IAM policy management for the main queue using custom statements with source/override policy documents
- **DLQ Policy** - Separate policy support for the dead-letter queue; automatically copies the main queue policy when no custom DLQ statements are provided
- **Redrive Allow Policy** - Controls which source queues can use this queue as a dead-letter queue with allowAll, denyAll, or byQueue permissions
- **FIFO Support** - Full FIFO queue support including content-based deduplication and high-throughput mode with per-message-group deduplication and throughput limits
- **Encryption** - Server-side encryption via SQS-managed keys (SSE-SQS) or a customer-managed KMS key with configurable data key reuse period
- **Lifecycle Management** - Toggle resource creation on or off with the `enabled` variable

## Usage

```hcl
module "sqs" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//sqs?depth=1&ref=master"

  name                       = "my-queue"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 604800

  deadletter_queue_enabled = true
  deadletter_queue_count   = 3

  sqs_managed_sse_enabled = true

  tags = {
    Environment = "production"
  }
}
```

## Examples

## Basic Standard Queue

Create a standard SQS queue with default settings and SQS-managed server-side encryption.

```hcl
module "sqs_jobs" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//sqs?depth=1&ref=master"

  enabled        = true
  name           = "job-processing"
  sqs_queue_name = "job-processing"

  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400

  tags = {
    Environment = "production"
    Team        = "backend"
  }
}
```

## Queue with Dead-Letter Queue

Automatically create a DLQ and route failed messages there after 5 receive attempts, useful for error isolation and debugging.

```hcl
module "sqs_with_dlq" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//sqs?depth=1&ref=master"

  enabled        = true
  name           = "order-processor"
  sqs_queue_name = "order-processor"

  visibility_timeout_seconds = 120
  message_retention_seconds  = 345600

  deadletter_queue_enabled = true
  deadletter_queue_count   = 5

  # DLQ retention defaults to the 14-day maximum (1209600s); override if needed
  deadletter_message_retention_seconds = 1209600

  # Optionally restrict redrive into the DLQ to the main queue only
  deadletter_redrive_allow_policy_enabled = true

  kms_master_key_id = "arn:aws:kms:eu-west-1:123456789012:key/mrk-00000000000000000000000000000000"

  tags = {
    Environment = "production"
    Service     = "orders"
    Team        = "backend"
  }
}
```

## FIFO Queue for Ordered Processing

Create a high-throughput FIFO queue with content-based deduplication for guaranteed ordering of messages.

```hcl
module "sqs_fifo" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//sqs?depth=1&ref=master"

  enabled        = true
  name           = "inventory-sync"
  sqs_queue_name = "inventory-sync.fifo"

  fifo_queue                  = true
  high_throughput_fifo_queue  = true
  content_based_deduplication = true

  fifo_high_throughput_deduplication_scope = "messageGroup"
  fifo_high_throughput_limit               = "perMessageGroupId"

  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400

  tags = {
    Environment = "production"
    Service     = "inventory"
    Team        = "backend"
  }
}
```

## Queue with Custom Policy and Redrive Allow Policy

Create a queue that accepts messages from an SNS topic via a resource policy, and control which source queues can use it as a DLQ.

```hcl
data "aws_iam_policy_document" "allow_sns" {
  statement {
    sid    = "AllowSNSPublish"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = ["*"]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:sns:eu-west-1:123456789012:application-events"]
    }
  }
}

module "sqs_sns_subscriber" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//sqs?depth=1&ref=master"

  enabled        = true
  name           = "events-consumer"
  sqs_queue_name = "events-consumer"

  create_queue_policy = true
  queue_policy_statements = {
    allow_sns = jsondecode(data.aws_iam_policy_document.allow_sns.json).Statement[0]
  }

  create_redrive_allow_policy          = true
  redrive_allow_policy_permission      = "byQueue"
  redrive_allow_policy_source_queue_arns = [
    "arn:aws:sqs:eu-west-1:123456789012:events-primary",
  ]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Reference

<details>
<summary>Requirements, providers, inputs and outputs (generated by terraform-docs)</summary>

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
| content\_based\_deduplication | Enables content-based deduplication for FIFO queues | `bool` | `false` | no |
| create\_queue\_policy | Whether to create SQS queue policy | `bool` | `false` | no |
| create\_redrive\_allow\_policy | Whether to create an SQS queue redrive allow policy to control which source queues can use this queue as a dead-letter queue | `bool` | `false` | no |
| deadletter\_message\_retention\_seconds | The number of seconds the dead letter queue retains a message (60 to 1209600). Defaults to the maximum of 14 days so failed messages are kept as long as possible. | `number` | `1209600` | no |
| deadletter\_override\_policy\_documents | List of IAM policy documents that override for the dead letter queue policy (only used when deadletter\_queue\_policy\_statements is provided) | `list(string)` | `[]` | no |
| deadletter\_queue\_count | Deadletter queue max receive count when `var.deadletter_queue_enabled` is true | `number` | `5` | no |
| deadletter\_queue\_enabled | Option whether to enable deadletter queue, This option overides `var.redrive_policy` | `bool` | `false` | no |
| deadletter\_queue\_policy\_enabled | Whether to create a policy for the dead letter queue. When true and no custom DLQ statements are provided, the source queue policy is automatically copied to the DLQ. | `bool` | `false` | no |
| deadletter\_queue\_policy\_statements | Custom IAM policy statements for the dead letter queue. When empty and deadletter\_queue\_policy\_enabled is true, the main queue's policy statements are used instead. | `any` | `{}` | no |
| deadletter\_redrive\_allow\_policy\_enabled | Whether to attach a redrive allow policy to the module-created dead letter queue, restricting redrive permission to the main queue (`byQueue`). | `bool` | `false` | no |
| deadletter\_source\_policy\_documents | List of IAM policy documents to merge for the dead letter queue policy (only used when deadletter\_queue\_policy\_statements is provided) | `list(string)` | `[]` | no |
| delay\_seconds | The time in seconds that the delivery of all messages in the queue will be delayed. An integer from 0 to 900 (15 minutes) | `number` | `0` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| fifo\_high\_throughput\_deduplication\_scope | (Optional) Specifies whether message deduplication occurs at the message group or queue level. Valid values are messageGroup and queue (default) | `string` | `"messageGroup"` | no |
| fifo\_high\_throughput\_limit | (Optional) Specifies whether the FIFO queue throughput quota applies to the entire queue or per message group. Valid values are perQueue (default) and perMessageGroupId | `string` | `"perMessageGroupId"` | no |
| fifo\_queue | Boolean designating a FIFO queue | `bool` | `false` | no |
| high\_throughput\_fifo\_queue | Boolean designating a high-throughput FIFO queue | `bool` | `false` | no |
| kms\_data\_key\_reuse\_period\_seconds | The length of time, in seconds, for which Amazon SQS can reuse a data key to encrypt or decrypt messages before calling AWS KMS again. An integer representing seconds, between 60 seconds (1 minute) and 86,400 seconds (24 hours) | `number` | `300` | no |
| kms\_master\_key\_id | The ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK | `string` | `null` | no |
| max\_message\_size | The limit of how many bytes a message can contain before Amazon SQS rejects it. An integer from 1024 bytes (1 KiB) up to 262144 bytes (256 KiB) | `number` | `262144` | no |
| message\_retention\_seconds | The number of seconds Amazon SQS retains a message. Integer representing seconds, from 60 (1 minute) to 1209600 (14 days) | `number` | `604800` | no |
| name | Name to use for resource naming and tagging. | `string` | `null` | no |
| override\_queue\_policy\_documents | List of IAM policy documents that are merged together into the exported document. In merging, statements with non-blank `sid`s will override statements with the same `sid` | `list(string)` | `[]` | no |
| queue\_policy\_statements | A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage | `any` | `{}` | no |
| receive\_wait\_time\_seconds | The time for which a ReceiveMessage call will wait for a message to arrive (long polling) before returning. An integer from 0 to 20 (seconds) | `number` | `0` | no |
| redrive\_allow\_policy\_permission | Permission type for the redrive allow policy. Valid values: allowAll, denyAll, byQueue | `string` | `"denyAll"` | no |
| redrive\_allow\_policy\_source\_queue\_arns | List of source queue ARNs allowed to use this queue as a dead-letter queue. Only used when redrive\_allow\_policy\_permission is byQueue | `list(string)` | `[]` | no |
| redrive\_policy | The JSON policy to set up the Dead Letter Queue, see AWS docs. Note: when specifying maxReceiveCount, you must specify it as an integer (5), and not a string ("5") | `string` | `null` | no |
| source\_queue\_policy\_documents | List of IAM policy documents that are merged together into the exported document. Statements must have unique `sid`s | `list(string)` | `[]` | no |
| sqs\_managed\_sse\_enabled | Enable server-side encryption (SSE) of message content with SQS-owned encryption keys | `bool` | `true` | no |
| sqs\_queue\_name | Name of the SQS queue | `string` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| visibility\_timeout\_seconds | The visibility timeout for the queue. An integer from 0 to 43200 (12 hours) | `number` | `30` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| arn | The ARN of the SQS queue |
| dlq\_arn | The ARN of the dead letter queue |
| dlq\_id | The URL for the created dead letter queue |
| dlq\_name | The name of the dead letter queue |
| dlq\_url | The URL of the dead letter queue |
| id | The URL for the created Amazon SQS queue |
| name | The name of the SQS queue |
| url | The URL of the SQS queue |
<!-- END_TF_DOCS -->

</details>
