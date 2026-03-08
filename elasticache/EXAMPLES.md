# ElastiCache Module - Examples

## Basic Usage

Redis replication group with encryption at rest and in transit across two subnets.

```hcl
module "elasticache" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache?depth=1&ref=v2.0.0"

  enabled = true

  replication_group_id = "my-redis"
  description          = "Redis cache for the application layer"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = "cache.t4g.medium"

  subnet_ids = ["subnet-0aaa111", "subnet-0bbb222"]
  vpc_id     = "vpc-0abc123def456789"

  at_rest_encryption_enabled  = true
  transit_encryption_enabled  = true

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Multi-AZ Redis with Automatic Failover

Highly available Redis with Multi-AZ, automatic failover, and daily snapshots.

```hcl
module "elasticache" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache?depth=1&ref=v2.0.0"

  enabled = true

  replication_group_id = "app-redis-ha"
  description          = "HA Redis cache with automatic failover"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = "cache.r7g.large"

  num_cache_clusters        = 2
  multi_az_enabled          = true
  automatic_failover_enabled = true

  at_rest_encryption_enabled = true
  kms_key_arn                = "arn:aws:kms:ap-southeast-1:123456789012:key/mrk-abc123"
  transit_encryption_enabled = true

  subnet_ids = ["subnet-0aaa111", "subnet-0bbb222", "subnet-0ccc333"]
  vpc_id     = "vpc-0abc123def456789"

  snapshot_retention_limit = 7
  snapshot_window          = "03:00-04:00"
  maintenance_window       = "mon:04:00-mon:05:00"

  log_delivery_configuration = {
    slow-log = {
      destination_type = "cloudwatch-logs"
      log_format       = "json"
    }
    engine-log = {
      destination_type = "cloudwatch-logs"
      log_format       = "json"
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Redis Cluster Mode (Sharded)

Redis replication group with cluster mode enabled for horizontal sharding.

```hcl
module "elasticache" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache?depth=1&ref=v2.0.0"

  enabled = true

  replication_group_id = "app-redis-cluster"
  description          = "Redis cluster-mode replication group"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = "cache.r7g.large"

  cluster_mode              = "enabled"
  num_node_groups           = 3
  replicas_per_node_group   = 1
  automatic_failover_enabled = true
  multi_az_enabled          = true

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  subnet_ids = ["subnet-0aaa111", "subnet-0bbb222", "subnet-0ccc333"]
  vpc_id     = "vpc-0abc123def456789"

  create_parameter_group  = true
  parameter_group_family  = "redis7"
  parameter_group_name    = "app-redis-cluster-params"
  parameters = [
    { name = "cluster-enabled", value = "yes" },
    { name = "maxmemory-policy", value = "allkeys-lru" }
  ]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Memcached Cluster with Multiple Nodes

Multi-AZ Memcached cluster using the simple cluster resource (not a replication group).

```hcl
module "elasticache_memcached" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache?depth=1&ref=v2.0.0"

  enabled = true

  create_cluster         = true
  create_replication_group = false

  cluster_id     = "app-memcached"
  engine         = "memcached"
  engine_version = "1.6.22"
  node_type      = "cache.t4g.medium"
  num_cache_nodes = 3
  az_mode        = "cross-az"

  preferred_availability_zones = [
    "ap-southeast-1a",
    "ap-southeast-1b",
    "ap-southeast-1c"
  ]

  subnet_ids = ["subnet-0aaa111", "subnet-0bbb222", "subnet-0ccc333"]
  vpc_id     = "vpc-0abc123def456789"

  tags = {
    Environment = "production"
    Team        = "platform"
    Engine      = "memcached"
  }
}
```
