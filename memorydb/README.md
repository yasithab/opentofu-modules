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

## Security notes

- **Prefer IAM authentication for users** (`authentication_mode = { type = "iam" }`) over `password`. Passwords supplied via `users` are stored in OpenTofu state even though the variable and the `users` output are marked `sensitive`.
- The created ACL **does not include the open-access `default` user by default** - it contains only the users you define in `users`. The MemoryDB `default` user has no password and full access, so only opt in via `include_default_user = true` if clients must connect without credentials.

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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11.0 |
| aws | >= 6.49, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| acl\_name | Name of the ACL. If null, uses var.name. | `string` | `null` | no |
| auto\_minor\_version\_upgrade | Whether the cluster will automatically receive minor engine version upgrades after launch. | `bool` | `true` | no |
| create\_acl | Whether to create a MemoryDB ACL. | `bool` | `true` | no |
| create\_parameter\_group | Whether to create a new parameter group for the cluster. | `bool` | `true` | no |
| create\_subnet\_group | Whether to create a new subnet group for the cluster. | `bool` | `true` | no |
| data\_tiering | Enable data tiering. Only available for clusters using r6gd node types. | `bool` | `false` | no |
| description | Description of the MemoryDB cluster. | `string` | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| engine | The name of the engine to be used for the cluster. Valid values are redis and valkey. | `string` | `"redis"` | no |
| engine\_version | The version number of the Redis engine to be used for the cluster. | `string` | `null` | no |
| final\_snapshot\_name | Name of the final cluster snapshot to be created when the cluster is deleted. | `string` | `null` | no |
| include\_default\_user | Whether to include the open-access `default` user in the created ACL. Disabled by default for security - the default user has no password and full access. | `bool` | `false` | no |
| kms\_key\_arn | ARN of the KMS key used to encrypt data at rest in the cluster. | `string` | `null` | no |
| maintenance\_window | The weekly time range during which system maintenance can occur (e.g. sun:05:00-sun:06:00). | `string` | `"sun:05:00-sun:06:00"` | no |
| name | Name of the MemoryDB cluster and used as a default for related resources. | `string` | n/a | yes |
| node\_type | The compute and memory capacity of the nodes in the cluster (e.g. db.r7g.large). | `string` | `"db.r7g.large"` | no |
| num\_replicas\_per\_shard | The number of replicas per shard. | `number` | `1` | no |
| num\_shards | The number of shards in the cluster. | `number` | `1` | no |
| parameter\_group\_family | The engine version that the parameter group can be used with (e.g. memorydb\_redis7). | `string` | `"memorydb_redis7"` | no |
| parameter\_group\_name | Name of the parameter group. If null, uses var.name. | `string` | `null` | no |
| parameters | List of parameter maps to apply to the parameter group. | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>  }))</pre> | `[]` | no |
| port | The port on which the cluster accepts connections. | `number` | `6379` | no |
| security\_group\_ids | List of security group IDs to associate with the cluster. | `list(string)` | `[]` | no |
| snapshot\_arns | List of ARN(s) of the snapshots to restore from. | `list(string)` | `null` | no |
| snapshot\_name | The name of a snapshot from which to restore data into the cluster. | `string` | `null` | no |
| snapshot\_retention\_limit | The number of days for which MemoryDB retains automatic snapshots. Setting to 0 disables backups. | `number` | `7` | no |
| snapshot\_window | The daily time range during which MemoryDB begins taking daily snapshots (e.g. 02:00-03:00). | `string` | `"02:00-03:00"` | no |
| sns\_topic\_arn | ARN of an SNS topic to send MemoryDB notifications to. | `string` | `null` | no |
| subnet\_group\_name | Name of the subnet group. If null, uses var.name. | `string` | `null` | no |
| subnet\_ids | List of VPC subnet IDs for the subnet group. | `list(string)` | `[]` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| tls\_enabled | Whether to enable in-transit encryption (TLS). Enabled by default for production security. | `bool` | `true` | no |
| users | Map of MemoryDB user configurations to create. Each user must have user\_name, access\_string, and authentication\_mode. Prefer authentication\_mode type `iam` over `password` so no credentials are stored in state. | `any` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| acl\_arn | The ARN of the ACL. |
| acl\_id | The name (ID) of the ACL. |
| cluster\_arn | The ARN of the MemoryDB cluster. |
| cluster\_endpoint | The cluster endpoint address and port. |
| cluster\_engine\_version | The engine version of the MemoryDB cluster. |
| cluster\_id | The name (ID) of the MemoryDB cluster. |
| cluster\_name | The name of the MemoryDB cluster. |
| parameter\_group\_arn | The ARN of the parameter group. |
| parameter\_group\_id | The name (ID) of the parameter group. |
| shards | Set of shards in this cluster. |
| subnet\_group\_arn | The ARN of the subnet group. |
| subnet\_group\_id | The name (ID) of the subnet group. |
| users | Map of created MemoryDB users and their attributes. |
<!-- END_TF_DOCS -->

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
