# MemoryDB

Provisions Amazon MemoryDB for Redis-compatible clusters with configurable sharding, replication, encryption, access control lists, and snapshot management.

## Features

- **Cluster Configuration** - Deploy MemoryDB clusters with configurable node types, shard counts, and replicas per shard
- **Subnet Group** - Optionally create a subnet group or reference an existing one for VPC placement
- **Parameter Group** - Create custom parameter groups with configurable engine parameters
- **Access Control Lists (ACL)** - Manage ACLs and users with fine-grained access control via access strings
- **KMS Encryption** - Encrypt data at rest using AWS KMS customer-managed keys
- **In-Transit Encryption** - TLS enabled by default for secure client-to-cluster communication
- **Snapshot Management** - Configurable snapshot windows, retention periods, and final snapshot on deletion
- **Multi-AZ** - Multi-AZ enabled by default for high availability with automatic failover
- **Auto Minor Version Upgrade** - Automatically apply minor engine patches during maintenance windows

## Usage

```hcl
module "memorydb" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//memorydb?depth=1&ref=master"

  name      = "app-cache"
  node_type = "db.r7g.large"

  num_shards             = 2
  num_replicas_per_shard = 1

  create_subnet_group = true
  subnet_ids          = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]

  security_group_ids = ["sg-0abc123def456789a"]

  tags = {
    Environment = "production"
  }
}
```

## Examples

### Basic MemoryDB Cluster

Single-shard MemoryDB cluster with one replica and TLS enabled.

```hcl
module "memorydb" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//memorydb?depth=1&ref=master"

  enabled = true
  name    = "session-store"

  node_type              = "db.r7g.large"
  num_shards             = 1
  num_replicas_per_shard = 1

  create_subnet_group = true
  subnet_ids          = ["subnet-0aa111bbb222", "subnet-0cc333ddd444", "subnet-0ee555fff666"]

  security_group_ids = ["sg-0abc123def456789a"]

  tls_enabled              = true
  multi_az_enabled         = true
  snapshot_retention_limit = 7

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

### Multi-Shard with KMS Encryption and Custom Users

Production cluster with multiple shards, KMS encryption, and custom ACL users.

```hcl
module "memorydb_encrypted" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//memorydb?depth=1&ref=master"

  enabled = true
  name    = "orders-cache"

  node_type              = "db.r7g.xlarge"
  num_shards             = 3
  num_replicas_per_shard = 2

  create_subnet_group = true
  subnet_ids          = ["subnet-0aa111bbb222", "subnet-0cc333ddd444", "subnet-0ee555fff666"]

  security_group_ids = ["sg-0abc123def456789a"]
  kms_key_arn        = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"

  create_acl = true
  users = {
    app_user = {
      user_name     = "app-writer"
      access_string = "on ~app::* &* +@all -@dangerous"
      authentication_mode = {
        type      = "password"
        passwords = ["SuperSecretPass123!"]
      }
    }
  }

  create_parameter_group = true
  parameter_group_family = "memorydb_redis7"
  parameters = [
    { name = "maxmemory-policy", value = "allkeys-lru" },
  ]

  snapshot_retention_limit    = 14
  auto_minor_version_upgrade = true

  tags = {
    Environment = "production"
    Team        = "orders"
    DataClass   = "confidential"
  }
}
```

### Valkey Engine with Data Tiering

MemoryDB cluster using the Valkey engine with data tiering on r6gd nodes.

```hcl
module "memorydb_valkey" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//memorydb?depth=1&ref=master"

  enabled = true
  name    = "analytics-cache"

  engine    = "valkey"
  node_type = "db.r6gd.xlarge"

  num_shards             = 2
  num_replicas_per_shard = 1
  data_tiering           = true

  create_subnet_group = true
  subnet_ids          = ["subnet-0aa111bbb222", "subnet-0cc333ddd444"]

  security_group_ids = ["sg-0abc123def456789a"]

  snapshot_retention_limit = 7
  final_snapshot_name      = "analytics-cache-final"

  tags = {
    Environment = "production"
    Team        = "analytics"
  }
}
```
