# SNS

OpenTofu module to create and manage AWS SNS topics with subscriptions, topic policies, and data protection policies.

## Features

- **SNS Topic** - Creates standard or FIFO topics with configurable name or name prefix, display name, delivery policy, and tracing
- **Topic Policy** - Built-in default topic policy with support for custom policy statements, source/override policy documents, or an externally managed policy
- **Subscriptions** - Manages multiple topic subscriptions with support for all protocols (SQS, Lambda, HTTP/S, email, etc.) including filter policies and dead-letter queues
- **Data Protection Policy** - Optional data protection policy for non-FIFO topics to detect and protect sensitive data
- **Encryption** - Optional KMS encryption via a customer-managed or AWS-managed key
- **Delivery Feedback** - Configurable success/failure feedback logging for Application, Firehose, HTTP, Lambda, and SQS delivery endpoints
- **FIFO Support** - Full FIFO topic support including content-based deduplication, throughput scope, archive policy, and signature version control
- **Subscription Toggle** - Control subscription creation independently via `create_subscription` (defaults to true)
- **Lifecycle Management** - Toggle resource creation on or off with the `enabled` variable

## Usage

```hcl
module "sns" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//sns?depth=1&ref=master"

  topic_name   = "my-notifications"
  display_name = "My Notifications"

  create_topic_policy        = true
  enable_default_topic_policy = true

  subscriptions = {
    sqs_subscription = {
      protocol = "sqs"
      endpoint = "arn:aws:sqs:us-east-1:123456789012:my-queue"
    }
  }

  tags = {
    Environment = "production"
  }
}
```


## Examples

## Basic Standard Topic

Create a standard SNS topic with a default topic policy and an email subscription.

```hcl
module "sns_alerts" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//sns?depth=1&ref=master"

  enabled    = true
  topic_name = "application-alerts"

  subscriptions = {
    ops_email = {
      protocol = "email"
      endpoint = "ops@example.com"
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Encrypted Topic with SQS Subscription

Create a KMS-encrypted SNS topic that delivers messages to an SQS queue for async processing.

```hcl
module "sns_events" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//sns?depth=1&ref=master"

  enabled    = true
  topic_name = "order-events"

  kms_master_key_id = "arn:aws:kms:eu-west-1:123456789012:key/mrk-00000000000000000000000000000000"
  tracing_config    = "Active"

  subscriptions = {
    orders_queue = {
      protocol             = "sqs"
      endpoint             = "arn:aws:sqs:eu-west-1:123456789012:order-processing-queue"
      raw_message_delivery = true
    }
  }

  tags = {
    Environment = "production"
    Service     = "orders"
    Team        = "backend"
  }
}
```

## FIFO Topic with Content-Based Deduplication

Create a FIFO SNS topic for ordered, exactly-once event delivery to a FIFO SQS queue.

```hcl
module "sns_fifo" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//sns?depth=1&ref=master"

  enabled    = true
  topic_name = "inventory-updates.fifo"

  fifo_topic                  = true
  content_based_deduplication = true

  subscriptions = {
    inventory_queue = {
      protocol = "sqs"
      endpoint = "arn:aws:sqs:eu-west-1:123456789012:inventory-updates.fifo"
    }
  }

  tags = {
    Environment = "production"
    Service     = "inventory"
    Team        = "backend"
  }
}
```

## Topic with Custom Policy and Lambda Subscription

Attach a custom resource policy to allow cross-account publishing, and subscribe a Lambda function as the consumer.

```hcl
data "aws_iam_policy_document" "sns_cross_account" {
  statement {
    sid    = "AllowCrossAccountPublish"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::999888777666:root"]
    }
    actions   = ["SNS:Publish"]
    resources = ["*"]
  }
}

module "sns_cross_account" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//sns?depth=1&ref=master"

  enabled    = true
  topic_name = "partner-events"

  enable_default_topic_policy  = true
  source_topic_policy_documents = [data.aws_iam_policy_document.sns_cross_account.json]

  subscriptions = {
    processor_lambda = {
      protocol = "lambda"
      endpoint = "arn:aws:lambda:eu-west-1:123456789012:function:partner-event-processor"
    }
  }

  tags = {
    Environment = "production"
    Team        = "integrations"
  }
}
```
