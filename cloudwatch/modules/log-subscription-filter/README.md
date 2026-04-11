# CloudWatch Log Subscription Filter

OpenTofu module to create an AWS CloudWatch Log Subscription Filter. Streams log events from a CloudWatch Logs log group to a destination such as a Kinesis stream, Lambda function, or Kinesis Data Firehose delivery stream.

## Features

- **Multiple Destinations** - Stream logs to Kinesis Data Streams, Lambda functions, or Kinesis Data Firehose delivery streams
- **Pattern Filtering** - Apply filter patterns to stream only matching log events, or use an empty string to match everything
- **Distribution Control** - Choose between Random or ByLogStream distribution methods for Kinesis destinations
- **IAM Role Support** - Optionally specify an IAM role for CloudWatch Logs to assume when delivering to Kinesis/Firehose destinations
- **Lifecycle Management** - Toggle resource creation with the `enabled` variable

## Usage

```hcl
module "log_subscription" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/log-subscription-filter?depth=1&ref=master"

  name            = "stream-errors-to-lambda"
  log_group_name  = "/aws/ecs/my-service"
  destination_arn = "arn:aws:lambda:us-east-1:123456789012:function:log-processor"
  filter_pattern  = "ERROR"
}
```

### Kinesis Data Stream Destination

```hcl
module "log_subscription" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/log-subscription-filter?depth=1&ref=master"

  name            = "stream-all-to-kinesis"
  log_group_name  = "/aws/ecs/my-service"
  destination_arn = "arn:aws:kinesis:us-east-1:123456789012:stream/my-stream"
  filter_pattern  = ""
  role_arn        = "arn:aws:iam::123456789012:role/CWLtoKinesisRole"
  distribution    = "ByLogStream"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | The name of the CloudWatch Log Subscription Filter | `string` | n/a | yes |
| `destination_arn` | The ARN of the destination (Kinesis stream, Lambda function, or Firehose delivery stream) | `string` | n/a | yes |
| `log_group_name` | The name of the log group to associate the subscription filter with | `string` | n/a | yes |
| `filter_pattern` | A valid CloudWatch Logs filter pattern (empty string matches everything) | `string` | `""` | no |
| `role_arn` | The ARN of an IAM role for CloudWatch Logs (required for Kinesis/Firehose destinations) | `string` | `null` | no |
| `distribution` | The method used to distribute log data to the destination (Random or ByLogStream) | `string` | `null` | no |
| `enabled` | Set to false to prevent the module from creating any resources | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| `subscription_filter_name` | The name of the CloudWatch Log Subscription Filter |
| `subscription_filter_log_group_name` | The name of the log group associated with the subscription filter |
| `subscription_filter_destination_arn` | The ARN of the destination for the subscription filter |
