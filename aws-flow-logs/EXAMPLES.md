# AWS Flow Logs Module - Examples

## Basic Usage (CloudWatch Logs)

Enables VPC Flow Logs to CloudWatch Logs. The module creates the log group and the required IAM role and policy automatically.

```hcl
module "vpc_flow_logs" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//aws-flow-logs?depth=1&ref=v2.0.0"

  enabled = true
  name    = "production-vpc"

  vpc_id               = "vpc-0abc123def456gh01"
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"

  cloudwatch_log_retention_in_days = 30

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## To S3 with Parquet Format

Delivers flow logs to an existing S3 bucket in Parquet format with per-hour partitioning for cost-efficient Athena queries.

```hcl
module "vpc_flow_logs_s3" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//aws-flow-logs?depth=1&ref=v2.0.0"

  enabled = true
  name    = "production-vpc-s3"

  vpc_id               = "vpc-0abc123def456gh01"
  log_destination_type = "s3"
  traffic_type         = "ALL"

  s3_bucket_arn = "arn:aws:s3:::my-org-flow-logs-us-east-1"

  destination_options = {
    file_format                = "parquet"
    hive_compatible_partitions = true
    per_hour_partition         = true
  }

  max_aggregation_interval = 60

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Subnet-Level Flow Logs with KMS-Encrypted CloudWatch

Captures flow logs for a specific subnet and encrypts the CloudWatch log group with a KMS key. Only REJECT traffic is captured to reduce volume and cost.

```hcl
module "subnet_flow_logs" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//aws-flow-logs?depth=1&ref=v2.0.0"

  enabled = true
  name    = "payments-subnet"

  subnet_id            = "subnet-0abc123def456gh03"
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "REJECT"

  cloudwatch_log_group_name        = "/aws/vpc-flow-logs/payments-subnet"
  cloudwatch_log_retention_in_days = 90
  cloudwatch_log_kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/mrk-1234abcd-12ab-34cd-56ef-1234567890ab"
  cloudwatch_log_group_class       = "STANDARD"

  max_aggregation_interval = 60

  tags = {
    Environment = "production"
    Team        = "payments"
  }
}
```

## To Kinesis Firehose for Centralised SIEM Ingestion

Routes flow logs into an existing Kinesis Data Firehose delivery stream for forwarding to an external SIEM (e.g. Splunk or OpenSearch).

```hcl
module "vpc_flow_logs_firehose" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//aws-flow-logs?depth=1&ref=v2.0.0"

  enabled = true
  name    = "production-vpc-siem"

  vpc_id               = "vpc-0abc123def456gh01"
  log_destination_type = "kinesis-data-firehose"
  traffic_type         = "ALL"

  kinesis_firehose_delivery_stream_arn = "arn:aws:firehose:us-east-1:123456789012:deliverystream/vpc-flow-logs-to-splunk"

  max_aggregation_interval = 60

  tags = {
    Environment = "production"
    Team        = "security"
  }
}
```
