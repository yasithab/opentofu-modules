# Amazon DynamoDB

OpenTofu module for provisioning and managing Amazon DynamoDB tables with support for autoscaling, global tables, encryption, and point-in-time recovery.

## Features

- **Flexible Billing** - Supports both PAY_PER_REQUEST (on-demand) and PROVISIONED capacity modes with configurable read/write throughput
- **Autoscaling** - Built-in Application Auto Scaling for read/write capacity and global secondary index throughput with customizable scaling policies
- **Global Tables** - Multi-region replication with configurable replica regions, strong consistency mode, and global table witness support
- **Secondary Indexes** - Full support for both global secondary indexes (GSI) and local secondary indexes (LSI) with on-demand throughput and warm throughput options
- **Encryption** - Server-side encryption enabled by default with optional custom KMS key support
- **Point-in-Time Recovery** - Enabled by default with configurable retention period (up to 35 days)
- **TTL Support** - Configurable time-to-live attribute for automatic item expiration
- **DynamoDB Streams** - Optional change data capture with configurable stream view types
- **Resource Policies** - Attach resource-based IAM policies directly to tables
- **S3 Import** - Import data from S3 during table creation with CSV format support
- **Deletion Protection** - Enabled by default to prevent accidental table deletion

## Usage

```hcl
module "dynamodb" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//dynamodb?depth=1&ref=master"

  name     = "my-table"
  hash_key = "id"

  attributes = [
    { name = "id", type = "S" }
  ]

  tags = {
    Environment = "production"
  }
}
```


## Examples

## Basic Usage

A simple on-demand table with a single partition key and encryption enabled (default).

```hcl
module "dynamodb_table" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//dynamodb?depth=1&ref=master"

  enabled = true
  name    = "orders"

  hash_key = "OrderId"

  attributes = [
    { name = "OrderId", type = "S" }
  ]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## With Sort Key and TTL

A table with both a partition key and range key, plus TTL to automatically expire old items.

```hcl
module "dynamodb_sessions" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//dynamodb?depth=1&ref=master"

  enabled = true
  name    = "user-sessions"

  hash_key  = "UserId"
  range_key = "SessionId"

  attributes = [
    { name = "UserId",    type = "S" },
    { name = "SessionId", type = "S" }
  ]

  ttl_enabled        = true
  ttl_attribute_name = "ExpiresAt"

  point_in_time_recovery_enabled = true

  tags = {
    Environment = "production"
    Team        = "auth"
  }
}
```

## With Global Secondary Index and KMS Encryption

A table with a GSI for query flexibility and a customer-managed KMS key for encryption.

```hcl
module "dynamodb_products" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//dynamodb?depth=1&ref=master"

  enabled = true
  name    = "products"

  hash_key  = "ProductId"
  range_key = "Category"

  attributes = [
    { name = "ProductId", type = "S" },
    { name = "Category",  type = "S" },
    { name = "CreatedAt", type = "N" }
  ]

  global_secondary_indexes = [
    {
      name            = "CategoryCreatedAtIndex"
      projection_type = "ALL"
      key_schema = [
        { attribute_name = "Category",  key_type = "HASH" },
        { attribute_name = "CreatedAt", key_type = "RANGE" }
      ]
    }
  ]

  server_side_encryption_enabled     = true
  server_side_encryption_kms_key_arn = "arn:aws:kms:ap-southeast-1:123456789012:key/mrk-abc123def456"

  tags = {
    Environment = "production"
    Team        = "catalogue"
  }
}
```

## Provisioned Capacity with Autoscaling

A provisioned billing mode table with Application Auto Scaling to handle variable read/write workloads.

```hcl
module "dynamodb_events" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//dynamodb?depth=1&ref=master"

  enabled = true
  name    = "events"

  hash_key  = "EventId"
  range_key = "Timestamp"

  attributes = [
    { name = "EventId",   type = "S" },
    { name = "Timestamp", type = "N" }
  ]

  billing_mode   = "PROVISIONED"
  read_capacity  = 10
  write_capacity = 10

  autoscaling_enabled = true

  autoscaling_read = {
    scale_in_cooldown  = 50
    scale_out_cooldown = 40
    target_value       = 70
    max_capacity       = 100
  }

  autoscaling_write = {
    scale_in_cooldown  = 50
    scale_out_cooldown = 40
    target_value       = 70
    max_capacity       = 50
  }

  stream_enabled    = true
  stream_view_type  = "NEW_AND_OLD_IMAGES"

  tags = {
    Environment = "production"
    Team        = "data"
  }
}
```
