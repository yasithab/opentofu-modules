# DynamoDB Module - Examples

## Basic Usage

A simple on-demand table with a single partition key and encryption enabled (default).

```hcl
module "dynamodb_table" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//dynamodb?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//dynamodb?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//dynamodb?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//dynamodb?depth=1&ref=v2.0.0"

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
