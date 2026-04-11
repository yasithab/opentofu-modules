# Kinesis Stream

OpenTofu module for provisioning Amazon Kinesis Data Streams with optional enhanced fan-out consumers and KMS encryption.

## Features

- **Provisioned and On-Demand modes** - choose between fixed shard capacity or automatic scaling with `stream_mode`
- **KMS encryption** - encrypts data at rest using AWS-managed or customer-managed KMS keys (enabled by default)
- **Enhanced fan-out consumers** - register dedicated consumers for low-latency, high-throughput reads via `consumer_count`
- **Shard-level CloudWatch metrics** - configurable shard-level metrics for operational visibility
- **Configurable retention** - retain data records from 24 hours up to 7 days (168 hours)

## Usage

```hcl
module "kinesis_stream" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kinesis-stream?depth=1&ref=master"

  name        = "app-events"
  stream_mode = "ON_DEMAND"

  tags = {
    Environment = "production"
  }
}
```


## Examples

## Basic Usage

Create a provisioned Kinesis stream with default settings and AWS-managed KMS encryption.

```hcl
module "kinesis_stream" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kinesis-stream?depth=1&ref=master"

  enabled = true
  name    = "app-events"

  shard_count = 2

  tags = {
    Environment = "production"
    Team        = "data"
  }
}
```

## On-Demand Mode with Extended Retention

Use on-demand capacity so shards scale automatically, and extend the retention window to 7 days.

```hcl
module "kinesis_stream_on_demand" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kinesis-stream?depth=1&ref=master"

  enabled = true
  name    = "clickstream"

  stream_mode      = "ON_DEMAND"
  retention_period = 168

  tags = {
    Environment = "production"
    Purpose     = "clickstream"
  }
}
```

## With Customer-Managed KMS Key and Enhanced Metrics

Encrypt the stream with a CMK and enable additional shard-level CloudWatch metrics.

```hcl
module "kinesis_stream_cmk" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kinesis-stream?depth=1&ref=master"

  enabled = true
  name    = "secure-events"

  shard_count      = 4
  retention_period = 48
  encryption_type  = "KMS"
  kms_key_id       = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"

  shard_level_metrics = [
    "IncomingBytes",
    "IncomingRecords",
    "OutgoingBytes",
    "OutgoingRecords",
    "IteratorAgeMilliseconds"
  ]

  tags = {
    Environment = "production"
    DataClass   = "confidential"
  }
}
```

## With Registered Consumers

Provision two enhanced fan-out consumers for downstream processing applications.

```hcl
module "kinesis_stream_with_consumers" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kinesis-stream?depth=1&ref=master"

  enabled = true
  name    = "order-events"

  shard_count      = 2
  stream_mode      = "PROVISIONED"
  retention_period = 48
  consumer_count   = 2

  tags = {
    Environment = "production"
    Domain      = "orders"
  }
}
```
