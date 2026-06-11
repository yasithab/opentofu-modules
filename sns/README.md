# SNS

OpenTofu module to create and manage AWS SNS topics with subscriptions, topic policies, and data protection policies.

> **Note — encryption by default:** `kms_master_key_id` now defaults to `alias/aws/sns`, so topics are created with server-side encryption (SSE-SNS) using the AWS managed key. AWS service event publishers (e.g. CloudWatch alarms, S3 event notifications) cannot use the AWS managed key for cross-service publishing in some cases and may need a customer-managed KMS key with appropriate key policy (`kms:GenerateDataKey*`, `kms:Decrypt` for the publishing service principal). Set `kms_master_key_id = null` to opt out of encryption (previous behaviour).

> **Note:** `name` is now required and must be non-empty.

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

  name         = "my-notifications"
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

  enabled = true
  name    = "application-alerts"

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

  enabled = true
  name    = "order-events"

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

  enabled = true
  name    = "inventory-updates.fifo"

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

  enabled = true
  name    = "partner-events"

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
| application\_feedback | Map of IAM role ARNs and sample rate for success and failure feedback | `map(string)` | `{}` | no |
| archive\_policy | The message archive policy for FIFO topics. | `string` | `null` | no |
| content\_based\_deduplication | Boolean indicating whether or not to enable content-based deduplication for FIFO topics. | `bool` | `false` | no |
| create\_subscription | Determines whether an SNS subscription is created | `bool` | `true` | no |
| create\_topic\_policy | Determines whether an SNS topic policy is created | `bool` | `true` | no |
| data\_protection\_policy | A map of data protection policy statements | `string` | `null` | no |
| delivery\_policy | The SNS delivery policy | `string` | `null` | no |
| display\_name | The display name for the SNS topic | `string` | `null` | no |
| enable\_default\_topic\_policy | Specifies whether to enable the default topic policy. Defaults to `true` | `bool` | `true` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| fifo\_throughput\_scope | Specifies the throughput scope for a FIFO topic. Valid values: Topic, MessageGroup. Only applies when fifo\_topic is true. | `string` | `null` | no |
| fifo\_topic | Boolean indicating whether or not to create a FIFO (first-in-first-out) topic | `bool` | `false` | no |
| firehose\_feedback | Map of IAM role ARNs and sample rate for success and failure feedback | `map(string)` | `{}` | no |
| http\_feedback | Map of IAM role ARNs and sample rate for success and failure feedback | `map(string)` | `{}` | no |
| kms\_master\_key\_id | The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. Defaults to the AWS managed SNS key (SSE enabled by default); set to `null` to disable server-side encryption. | `string` | `"alias/aws/sns"` | no |
| lambda\_feedback | Map of IAM role ARNs and sample rate for success and failure feedback | `map(string)` | `{}` | no |
| name | The name of the SNS topic to create | `string` | n/a | yes |
| override\_topic\_policy\_documents | List of IAM policy documents that are merged together into the exported document. In merging, statements with non-blank `sid`s will override statements with the same `sid` | `list(string)` | `[]` | no |
| signature\_version | If SignatureVersion should be 1 (SHA1) or 2 (SHA256). The signature version corresponds to the hashing algorithm used while creating the signature of the notifications, subscription confirmations, or unsubscribe confirmation messages sent by Amazon SNS. | `number` | `null` | no |
| source\_topic\_policy\_documents | List of IAM policy documents that are merged together into the exported document. Statements must have unique `sid`s | `list(string)` | `[]` | no |
| sqs\_feedback | Map of IAM role ARNs and sample rate for success and failure feedback | `map(string)` | `{}` | no |
| subscriptions | A map of subscription definitions to create | `any` | `{}` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| topic\_policy | An externally created fully-formed AWS policy as JSON | `string` | `null` | no |
| topic\_policy\_statements | A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage | `any` | `{}` | no |
| tracing\_config | Tracing mode of an Amazon SNS topic. Valid values: PassThrough, Active. | `string` | `null` | no |
| use\_name\_prefix | Determines whether `name` is used as a prefix | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| subscriptions | Map of subscriptions created and their attributes |
| topic\_arn | The ARN of the SNS topic, as a more obvious property (clone of id) |
| topic\_beginning\_archive\_time | The oldest timestamp at which a FIFO topic subscriber can start a replay |
| topic\_id | The ARN of the SNS topic |
| topic\_name | The name of the topic |
| topic\_owner | The AWS Account ID of the SNS topic owner |
<!-- END_TF_DOCS -->

</details>
