# ElastiCache Serverless Cache

OpenTofu module to create an Amazon ElastiCache Serverless cache. Provides a fully managed, serverless caching solution that automatically scales based on demand, supporting both Redis and Memcached engines.

## Features

- **Redis and Memcached** - Supports both Redis and Memcached cache engines
- **Usage Limits** - Configure data storage limits and ElastiCache Processing Units (eCPU) per second boundaries
- **Encryption at Rest** - Optional KMS customer-managed key for data-at-rest encryption
- **VPC Integration** - Deploy into VPC subnets with security group associations
- **Snapshots** - Configure daily snapshot times, retention limits, and restore from existing snapshots (Redis only)
- **User Group** - Associate a user group for Redis-based access control
- **Configurable Timeouts** - Customize create, update, and delete operation timeouts
- **Lifecycle Management** - Toggle resource creation with the `enabled` variable

## Usage

```hcl
module "serverless_cache" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache/serverless-cache?depth=1&ref=master"

  cache_name           = "my-cache"
  engine               = "redis"
  major_engine_version = "7"

  cache_usage_limits = {
    data_storage = {
      maximum = 10
      unit    = "GB"
    }
    ecpu_per_second = {
      maximum = 5000
    }
  }

  subnet_ids         = ["subnet-abc123", "subnet-def456"]
  security_group_ids = ["sg-0123456789abcdef0"]

  snapshot_retention_limit = 7
  daily_snapshot_time      = "05:00"

  tags = {
    Environment = "production"
  }
}
```

### Memcached

```hcl
module "memcached_cache" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache/serverless-cache?depth=1&ref=master"

  cache_name           = "my-memcached"
  engine               = "memcached"
  major_engine_version = "1.6"

  cache_usage_limits = {
    data_storage = {
      maximum = 5
      unit    = "GB"
    }
  }

  subnet_ids         = ["subnet-abc123", "subnet-def456"]
  security_group_ids = ["sg-0123456789abcdef0"]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `cache_name` | Unique identifier for the serverless cache | `string` | `null` | no |
| `engine` | Cache engine (`redis` or `memcached`) | `string` | `"redis"` | no |
| `major_engine_version` | The version of the cache engine | `string` | `null` | no |
| `description` | User-created description for the serverless cache | `string` | `null` | no |
| `cache_usage_limits` | Cache usage limits for storage and eCPU | `map(any)` | `{}` | no |
| `subnet_ids` | List of subnet IDs for the VPC endpoint | `list(string)` | `[]` | no |
| `security_group_ids` | List of VPC security group IDs | `list(string)` | `[]` | no |
| `kms_key_id` | ARN of a customer managed KMS key for encryption at rest | `string` | `null` | no |
| `user_group_id` | Identifier of the UserGroup for Redis access control | `string` | `null` | no |
| `daily_snapshot_time` | Daily time for automatic snapshots (Redis only) | `string` | `null` | no |
| `snapshot_retention_limit` | Number of snapshots to retain (Redis only) | `number` | `null` | no |
| `snapshot_arns_to_restore` | List of snapshot ARNs to restore from (Redis only) | `list(string)` | `null` | no |
| `timeouts` | Map of create, update, and delete timeouts | `map(string)` | `{}` | no |
| `region` | Region where the resources will be managed | `string` | `null` | no |
| `enabled` | Whether to create the serverless cache | `bool` | `true` | no |
| `tags` | Map of tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `serverless_cache_arn` | The ARN of the serverless cache |
| `serverless_cache_create_time` | Timestamp of when the serverless cache was created |
| `serverless_cache_endpoint` | Connection endpoint information for the cache |
| `serverless_cache_full_engine_version` | The full engine version of the serverless cache |
| `serverless_cache_major_engine_version` | The major engine version of the serverless cache |
| `serverless_cache_reader_endpoint` | Reader endpoint information for the cache |
| `serverless_cache_status` | The current status of the serverless cache |


## Examples

## Basic Usage

Serverless Redis cache with default settings and VPC placement.

```hcl
module "elasticache_serverless" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache/serverless-cache?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache/serverless-cache?depth=1&ref=master"

  enabled              = true
  cache_name           = "app-serverless-redis"
  engine               = "redis"
  major_engine_version = "7"
  description          = "Serverless Redis cache with limits for the app layer"

  cache_usage_limits = {
    data_storage = {
      maximum = 50
      minimum = 1
      unit    = "GB"
    }
    ecpu_per_second = {
      maximum = 5000
      minimum = 1000
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
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache/serverless-cache?depth=1&ref=master"

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
