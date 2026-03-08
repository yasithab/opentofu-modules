# Kinesis Firehose Module - Examples

## Basic Usage - Direct Put to S3

Stream data directly from producers into an S3 bucket with GZIP compression.

```hcl
module "firehose_s3" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kinesis-firehose?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//kinesis-firehose?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//kinesis-firehose?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//kinesis-firehose?depth=1&ref=v2.0.0"

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
