# Amazon ElastiCache

OpenTofu module for provisioning and managing Amazon ElastiCache clusters and replication groups with support for Redis, Valkey, and Memcached engines, including global replication for multi-region deployments.

## Features

- **Multi-Engine Support** - Supports Redis, Valkey, and Memcached cache engines with configurable versions
- **Replication Groups** - Redis/Valkey replication groups with automatic failover, Multi-AZ, and configurable replica counts
- **Cluster Mode** - Redis cluster mode (sharding) with configurable node groups and replicas per shard
- **Global Replication** - Cross-region global replication groups with primary and secondary region support for disaster recovery
- **Encryption** - At-rest encryption with optional KMS key and in-transit encryption with auth token support
- **Parameter Groups** - Automatic creation and management of parameter groups with custom parameters and cluster-mode settings
- **Subnet Groups** - Managed subnet group creation for VPC-based cache deployments
- **Security Groups** - Optional managed security group with customizable ingress and egress rules
- **CloudWatch Logging** - Automatic CloudWatch log group creation for Redis/Valkey slow logs and engine logs
- **Standalone Clusters** - Memcached clusters or Redis clusters joined to external replication groups
- **Snapshots** - Configurable snapshot windows and retention with support for restoring from existing snapshots or S3 ARNs
- **Data Tiering** - Support for r6gd node types with data tiering for cost-optimized memory management

## Usage

```hcl
module "elasticache" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache?depth=1&ref=master"

  replication_group_id = "my-redis"
  node_type            = "cache.t4g.micro"
  num_cache_clusters   = 2

  subnet_ids = ["subnet-0a1b2c3d", "subnet-4e5f6a7b"]
  vpc_id     = "vpc-0123456789abcdef0"

  security_group_rules = {
    ingress_vpc = {
      cidr_ipv4 = "10.0.0.0/16"
    }
  }

  tags = {
    Environment = "production"
  }
}
```


## Examples

## Basic Usage

Redis replication group with encryption at rest and in transit across two subnets.

```hcl
module "elasticache" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache?depth=1&ref=master"

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
