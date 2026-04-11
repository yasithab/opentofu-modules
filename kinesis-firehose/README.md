# Kinesis Firehose

Feature-rich Amazon Kinesis Data Firehose module that provisions delivery streams with support for a wide range of sources, destinations, and data transformation options. Handles IAM role creation, CloudWatch logging, VPC networking, and security group management automatically.

## Features

- **Multiple Sources** - Ingest data via Direct Put, Kinesis Data Streams, WAF logs, or Amazon MSK
- **Extensive Destination Support** - Deliver to S3, Redshift, OpenSearch (managed and serverless), Elasticsearch, Splunk, Snowflake, Apache Iceberg, and HTTP endpoints including Datadog, Coralogix, New Relic, Dynatrace, Honeycomb, LogicMonitor, MongoDB, and Sumo Logic
- **Data Transformation** - Optional Lambda-based record transformation with configurable buffer size, interval, and retry settings
- **Data Format Conversion** - Convert JSON to Apache Parquet or ORC using AWS Glue Data Catalog schemas
- **Dynamic Partitioning** - Partition S3 data by extracted keys for efficient query patterns
- **Server-Side Encryption** - SSE at rest with AWS-owned or customer-managed KMS keys
- **S3 Backup** - Configurable backup to a secondary S3 bucket for all destination types
- **VPC Delivery** - Deploy Firehose into VPC subnets with managed security groups for OpenSearch and Elasticsearch destinations
- **Cross-Account Support** - Deliver to S3 buckets, OpenSearch domains, or Elasticsearch domains in different AWS accounts
- **CloudWatch Logging** - Automatic log group and stream creation for delivery and backup monitoring
- **IAM Role Management** - Auto-creates least-privilege IAM roles for the delivery stream and optional application source roles
- **Secrets Manager Integration** - Retrieve destination credentials from AWS Secrets Manager

## Usage

```hcl
module "firehose" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kinesis-firehose?depth=1&ref=master"

  name        = "app-logs-to-s3"
  destination = "extended_s3"

  s3_bucket_arn          = "arn:aws:s3:::my-logs-bucket"
  s3_prefix              = "firehose/year=!{timestamp:yyyy}/month=!{timestamp:MM}/"
  s3_compression_format  = "GZIP"
  buffering_size         = 64
  buffering_interval     = 300

  tags = {
    Environment = "production"
  }
}
```


## Examples

## Basic Usage - Direct Put to S3

Stream data directly from producers into an S3 bucket with GZIP compression.

```hcl
module "firehose_s3" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kinesis-firehose?depth=1&ref=master"

  enabled      = true
  name         = "app-events"
  destination  = "extended_s3"
  input_source = "direct-put"

  s3_bucket_arn          = "arn:aws:s3:::my-data-lake-bucket"
  s3_prefix              = "app-events/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
  s3_error_output_prefix = "app-events-errors/"
  s3_compression_format  = "GZIP"
  buffering_size         = 128
  buffering_interval     = 300

  tags = {
    Environment = "production"
    Team        = "data"
  }
}
```

## With Kinesis Stream Source and S3 Destination

Read from an existing Kinesis Data Stream and deliver to S3 with KMS encryption.

```hcl
module "firehose_from_kinesis" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kinesis-firehose?depth=1&ref=master"

  enabled      = true
  name         = "clickstream-delivery"
  destination  = "extended_s3"
  input_source = "kinesis"

  kinesis_source_stream_arn = "arn:aws:kinesis:us-east-1:123456789012:stream/clickstream"

  s3_bucket_arn         = "arn:aws:s3:::my-data-lake-bucket"
  s3_prefix             = "clickstream/"
  enable_s3_encryption  = true
  s3_kms_key_arn        = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"

  enable_destination_log = true

  tags = {
    Environment = "production"
    Source      = "kinesis"
  }
}
```

## With OpenSearch Destination

Deliver logs to an Amazon OpenSearch Service domain inside a VPC.

```hcl
module "firehose_opensearch" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kinesis-firehose?depth=1&ref=master"

  enabled      = true
  name         = "app-logs-opensearch"
  destination  = "opensearch"
  input_source = "direct-put"

  opensearch_domain_arn         = "arn:aws:es:us-east-1:123456789012:domain/app-logs"
  opensearch_index_name         = "app-logs"
  opensearch_index_rotation_period = "OneDay"
  opensearch_retry_duration     = 300

  s3_bucket_arn = "arn:aws:s3:::my-firehose-backup-bucket"

  enable_vpc         = true
  vpc_subnet_ids     = ["subnet-0abc123def456", "subnet-0def456abc123"]

  enable_destination_log = true

  tags = {
    Environment = "production"
    Destination = "opensearch"
  }
}
```

## WAF Logs to S3 with Dynamic Partitioning

Capture WAF logs (note: name is automatically prefixed with `aws-waf-logs-`) with dynamic partitioning.

```hcl
module "firehose_waf_logs" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kinesis-firehose?depth=1&ref=master"

  enabled      = true
  name         = "prod-waf"
  destination  = "extended_s3"
  input_source = "waf"

  s3_bucket_arn          = "arn:aws:s3:::my-waf-logs-bucket"
  s3_prefix              = "waf-logs/region=us-east-1/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
  s3_error_output_prefix = "waf-logs-errors/!{firehose:error-output-type}/"
  s3_compression_format  = "GZIP"

  enable_dynamic_partitioning      = true
  dynamic_partitioning_retry_duration = 300

  enable_sse          = true
  sse_kms_key_type    = "CUSTOMER_MANAGED_CMK"
  sse_kms_key_arn     = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"

  enable_destination_log = true

  tags = {
    Environment = "production"
    Purpose     = "waf-logging"
  }
}
```
