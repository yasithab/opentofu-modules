# SQS Module - Examples

## Basic Standard Queue

Create a standard SQS queue with default settings and SQS-managed server-side encryption.

```hcl
module "sqs_jobs" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//sqs?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//sqs?depth=1&ref=v2.0.0"

  enabled        = true
  name           = "order-processor"
  sqs_queue_name = "order-processor"

  visibility_timeout_seconds = 120
  message_retention_seconds  = 345600

  deadletter_queue_enabled = true
  deadletter_queue_count   = 5

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//sqs?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//sqs?depth=1&ref=v2.0.0"

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
