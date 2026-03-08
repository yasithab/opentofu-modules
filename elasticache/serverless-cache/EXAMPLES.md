# ElastiCache Serverless Cache Module - Examples

## Basic Usage

Serverless Redis cache with default settings and VPC placement.

```hcl
module "elasticache_serverless" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache/serverless-cache?depth=1&ref=v2.0.0"

  enabled     = true
  cache_name  = "my-serverless-redis"
  engine      = "redis"
  description = "Serverless Redis cache for the application tier"

  subnet_ids = ["subnet-0aaa111", "subnet-0bbb222"]
  security_group_ids = ["sg-0abc123def456789"]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## With Usage Limits and Snapshots

Serverless cache with capacity caps, snapshot retention, and KMS encryption.

```hcl
module "elasticache_serverless" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache/serverless-cache?depth=1&ref=v2.0.0"

  enabled              = true
  cache_name           = "app-serverless-redis"
  engine               = "redis"
  major_engine_version = "7"
  description          = "Serverless Redis cache with limits for the app layer"

  cache_usage_limits = {
    data_storage = {
      maximum = { unit = "GB", value = 50 }
      minimum = { unit = "GB", value = 1 }
    }
    ecpu_per_second = {
      maximum = { value = 5000 }
      minimum = { value = 1000 }
    }
  }

  kms_key_id               = "arn:aws:kms:ap-southeast-1:123456789012:key/mrk-abc123"
  snapshot_retention_limit = 7
  daily_snapshot_time      = "03:00"

  subnet_ids         = ["subnet-0aaa111", "subnet-0bbb222", "subnet-0ccc333"]
  security_group_ids = ["sg-0abc123def456789"]

  tags = {
    Environment = "production"
    CostCenter  = "platform"
  }
}
```

## With User Group Association

Serverless cache associated with a user group for fine-grained RBAC.

```hcl
module "elasticache_serverless" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache/serverless-cache?depth=1&ref=v2.0.0"

  enabled      = true
  cache_name   = "secure-serverless-redis"
  engine       = "redis"
  description  = "Serverless Redis with user group access control"

  user_group_id = "app-user-group"

  snapshot_retention_limit = 3
  daily_snapshot_time      = "05:00"

  subnet_ids         = ["subnet-0aaa111", "subnet-0bbb222"]
  security_group_ids = ["sg-0abc123def456789"]

  timeouts = {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  tags = {
    Environment = "production"
    Security    = "rbac-enabled"
  }
}
```
