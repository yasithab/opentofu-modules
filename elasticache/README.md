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

## Security notes

- **`auth_token` is stored in OpenTofu state.** Even though the variable is marked `sensitive`, the token value still ends up in the state file. Prefer ElastiCache RBAC via user groups (`user_group_ids` together with the `elasticache/user-group` module, ideally with IAM authentication) instead of a shared auth token. If you must use an auth token, ensure your state backend is encrypted and access-restricted.

## Usage

```hcl
module "elasticache" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache?depth=1&ref=master"

  name               = "my-redis"
  node_type          = "cache.t4g.micro"
  num_cache_clusters = 2

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


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11.0 |
| aws | >= 6.49, < 7.0 |
| random | ~> 3.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |
| random | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| apply\_immediately | Whether any database modifications are applied immediately, or during the next maintenance window. Default is `false` | `bool` | `null` | no |
| at\_rest\_encryption\_enabled | Whether to enable encryption at rest | `bool` | `true` | no |
| auth\_token | The password used to access a password protected server. Can be specified only if `transit_encryption_enabled = true` | `string` | `null` | no |
| auth\_token\_update\_strategy | Strategy to use when updating the `auth_token`. Valid values are `SET`, `ROTATE`, and `DELETE`. Defaults to `ROTATE` | `string` | `null` | no |
| auto\_minor\_version\_upgrade | Specifies whether minor version engine upgrades will be applied automatically to the underlying Cache Cluster instances during the maintenance window. Only supported for engine type `redis` and `valkey` and if the engine version is 6 or higher. Defaults to `true` | `bool` | `null` | no |
| automatic\_failover\_enabled | Specifies whether a read-only replica will be automatically promoted to read/write primary if the existing primary fails. If true, Multi-AZ is enabled for this replication group. If false, Multi-AZ is disabled for this replication group. Must be enabled for Redis (cluster mode enabled) replication groups | `bool` | `null` | no |
| availability\_zone | Availability Zone for the cache cluster. If you want to create cache nodes in multi-az, use `preferred_availability_zones` instead | `string` | `null` | no |
| az\_mode | Whether the nodes in this Memcached node group are created in a single Availability Zone or created across multiple Availability Zones in the cluster's region. Valid values for this parameter are `single-az` or `cross-az`, default is `single-az` | `string` | `null` | no |
| cluster\_id | Group identifier. Defaults to `name` when not set. ElastiCache converts this name to lowercase. Changing this value will re-create the resource | `string` | `null` | no |
| cluster\_mode | Specifies whether cluster mode is enabled or disabled. Valid values are enabled or disabled or compatible | `string` | `null` | no |
| cluster\_mode\_enabled | Whether to enable Redis [cluster mode https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/Replication.Redis-RedisCluster.html] | `bool` | `false` | no |
| create\_cluster | Determines whether an ElastiCache cluster will be created or not | `bool` | `false` | no |
| create\_parameter\_group | Determines whether the ElastiCache parameter group will be created or not | `bool` | `false` | no |
| create\_primary\_global\_replication\_group | Determines whether an primary ElastiCache global replication group will be created | `bool` | `false` | no |
| create\_replication\_group | Determines whether an ElastiCache replication group will be created or not | `bool` | `true` | no |
| create\_secondary\_global\_replication\_group | Determines whether an secondary ElastiCache global replication group will be created | `bool` | `false` | no |
| create\_security\_group | Determines if a security group is created | `bool` | `true` | no |
| create\_subnet\_group | Determines whether the Elasticache subnet group will be created or not | `bool` | `true` | no |
| data\_tiering\_enabled | Enables data tiering. Data tiering is only supported for replication groups using the `r6gd` node type. This parameter must be set to true when using `r6gd` nodes | `bool` | `null` | no |
| description | User-created description for the replication group | `string` | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| engine | Name of the cache engine to be used for this cache cluster. Valid values are `memcached`, `redis`, or `valkey` | `string` | `"redis"` | no |
| engine\_version | Version number of the cache engine to be used. If not set, defaults to the latest version | `string` | `null` | no |
| final\_snapshot\_identifier | (Redis only) Name of your final cluster snapshot. If omitted, no final snapshot will be made | `string` | `null` | no |
| global\_replication\_group\_id | The ID of the global replication group to which this replication group should belong | `string` | `null` | no |
| ip\_discovery | The IP version to advertise in the discovery protocol. Valid values are `ipv4` or `ipv6` | `string` | `null` | no |
| kms\_key\_arn | The ARN of the key that you wish to use if encrypting at rest. If not supplied, uses service managed encryption. Can be specified only if `at_rest_encryption_enabled = true` | `string` | `null` | no |
| log\_delivery\_configuration | (Redis OSS or Valkey) Specifies the destination and format of Redis OSS/Valkey SLOWLOG or Redis OSS/Valkey Engine Log | `any` | <pre>{<br/>  "slow-log": {<br/>    "destination_type": "cloudwatch-logs",<br/>    "log_format": "json"<br/>  }<br/>}</pre> | no |
| maintenance\_window | Specifies the weekly time range for when maintenance on the cache cluster is performed. The format is `ddd:hh24:mi-ddd:hh24:mi` (24H Clock UTC) | `string` | `null` | no |
| multi\_az\_enabled | Specifies whether to enable Multi-AZ Support for the replication group. If true, `automatic_failover_enabled` must also be enabled. Defaults to `false` | `bool` | `false` | no |
| name | Name of the cache. Used as the default cluster ID and replication group ID, and to derive default names for the parameter group, subnet group, security group, and CloudWatch log groups | `string` | n/a | yes |
| network\_type | The IP versions for cache cluster connections. Valid values are `ipv4`, `ipv6` or `dual_stack` | `string` | `null` | no |
| node\_group\_configuration | List of node group (shard) configurations for the replication group. Only valid when cluster\_mode is enabled | `any` | `[]` | no |
| node\_type | The instance class used. For Memcached, changing this value will re-create the resource | `string` | `null` | no |
| notification\_topic\_arn | ARN of an SNS topic to send ElastiCache notifications to | `string` | `null` | no |
| num\_cache\_clusters | Number of cache clusters (primary and replicas) this replication group will have. If Multi-AZ is enabled, the value of this parameter must be at least 2. Updates will occur before other modifications. Conflicts with `num_node_groups`. Defaults to `1` | `number` | `null` | no |
| num\_cache\_nodes | The initial number of cache nodes that the cache cluster will have. For Redis, this value must be 1. For Memcached, this value must be between 1 and 40. If this number is reduced on subsequent runs, the highest numbered nodes will be removed | `number` | `1` | no |
| num\_node\_groups | Number of node groups (shards) for this Redis replication group. Changing this number will trigger a resizing operation before other settings modifications | `number` | `null` | no |
| outpost\_mode | Specify the outpost mode that will apply to the cache cluster creation. Valid values are `single-outpost` and `cross-outpost`, however AWS currently only supports `single-outpost` mode | `string` | `null` | no |
| parameter\_group\_description | The description of the ElastiCache parameter group. Defaults to `Managed by Terraform` | `string` | `null` | no |
| parameter\_group\_family | The family of the ElastiCache parameter group | `string` | `""` | no |
| parameter\_group\_name | The name of the parameter group. If `create_parameter_group` is `true`, this is the name assigned to the parameter group created. Otherwise, this is the name of an existing parameter group | `string` | `null` | no |
| parameters | List of ElastiCache parameters to apply | `list(map(string))` | `[]` | no |
| port | The port number on which each of the cache nodes will accept connections. For Memcached the default is `11211`, and for Redis the default port is `6379` | `number` | `null` | no |
| preferred\_availability\_zones | List of the Availability Zones in which cache nodes are created | `list(string)` | `[]` | no |
| preferred\_cache\_cluster\_azs | List of EC2 availability zones in which the replication group's cache clusters will be created. The order of the availability zones in the list is considered. The first item in the list will be the primary node. Ignored when updating | `list(string)` | `[]` | no |
| preferred\_outpost\_arn | (Required if `outpost_mode` is specified) The outpost ARN in which the cache cluster will be created | `string` | `null` | no |
| region | Region where the resource(s) will be managed. Defaults to the region set in the provider configuration | `string` | `null` | no |
| replicas\_per\_node\_group | Number of replica nodes in each node group. Changing this number will trigger a resizing operation before other settings modifications. Valid values are 0 to 5 | `number` | `null` | no |
| replication\_group\_id | Replication group identifier. Defaults to `name` when not set. When `create_replication_group` is set to `true`, this is the ID assigned to the replication group created. When `create_replication_group` is set to `false`, this is the ID of an externally created replication group | `string` | `null` | no |
| security\_group\_description | Description of the security group created | `string` | `null` | no |
| security\_group\_ids | One or more VPC security groups associated with the cache cluster | `list(string)` | `[]` | no |
| security\_group\_name | Name to use on security group created | `string` | `null` | no |
| security\_group\_names | Names of one or more Amazon VPC security groups associated with this replication group | `list(string)` | `[]` | no |
| security\_group\_rules | Security group ingress and egress rules to add to the security group created | <pre>map(object({<br/>    type                         = optional(string, "ingress")<br/>    ip_protocol                  = optional(string, "tcp")<br/>    from_port                    = optional(number)<br/>    to_port                      = optional(number)<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    description                  = optional(string)<br/>    prefix_list_id               = optional(string)<br/>    referenced_security_group_id = optional(string)<br/>    tags                         = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| security\_group\_tags | A map of additional tags to add to the security group created | `map(string)` | `{}` | no |
| security\_group\_use\_name\_prefix | Determines whether the security group name (`security_group_name`) is used as a prefix | `bool` | `true` | no |
| snapshot\_arns | (Redis only) Single-element string list containing an Amazon Resource Name (ARN) of a Redis RDB snapshot file stored in Amazon S3 | `list(string)` | `[]` | no |
| snapshot\_name | (Redis only) Name of a snapshot from which to restore data into the new node group. Changing `snapshot_name` forces a new resource | `string` | `null` | no |
| snapshot\_retention\_limit | (Redis only) Number of days for which ElastiCache will retain automatic cache cluster snapshots before deleting them. Defaults to 7; set to 0 to disable automatic snapshots | `number` | `7` | no |
| snapshot\_window | (Redis only) Daily time range (in UTC) during which ElastiCache will begin taking a daily snapshot of your cache cluster. Example: `05:00-09:00` | `string` | `null` | no |
| subnet\_group\_description | Description for the Elasticache subnet group | `string` | `null` | no |
| subnet\_group\_name | The name of the subnet group. If `create_subnet_group` is `true`, this is the name assigned to the subnet group created. Otherwise, this is the name of an existing subnet group | `string` | `null` | no |
| subnet\_ids | List of VPC Subnet IDs for the Elasticache subnet group | `list(string)` | `[]` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| transit\_encryption\_enabled | Enable encryption in-transit. Supported only with Memcached versions `1.6.12` and later, running in a VPC | `bool` | `true` | no |
| transit\_encryption\_mode | A setting that enables clients to migrate to in-transit encryption with no downtime. Valid values are preferred and required | `string` | `null` | no |
| user\_group\_ids | User Group ID to associate with the replication group. Only a maximum of one (1) user group ID is valid | `list(string)` | `null` | no |
| vpc\_id | Identifier of the VPC where the security group will be created | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| cloudwatch\_log\_groups | Map of CloudWatch log groups created and their attributes, keyed by log delivery configuration key |
| cluster\_address | (Memcached only) DNS name of the cache cluster without the port appended |
| cluster\_arn | The ARN of the ElastiCache Cluster |
| cluster\_cache\_nodes | List of node objects including `id`, `address`, `port` and `availability_zone` |
| cluster\_configuration\_endpoint | (Memcached only) Configuration endpoint to allow host discovery |
| cluster\_engine\_version\_actual | Because ElastiCache pulls the latest minor or patch for a version, this attribute returns the running version of the cache engine |
| global\_replication\_group\_arn | ARN of the created ElastiCache Global Replication Group |
| global\_replication\_group\_engine\_version\_actual | The full version number of the cache engine running on the members of this global replication group |
| global\_replication\_group\_id | ID of the ElastiCache Global Replication Group |
| global\_replication\_group\_node\_groups | Set of node groups (shards) on the global replication group |
| parameter\_group\_arn | The AWS ARN associated with the parameter group |
| parameter\_group\_id | The ElastiCache parameter group name |
| replication\_group\_arn | ARN of the created ElastiCache Replication Group |
| replication\_group\_configuration\_endpoint\_address | Address of the replication group configuration endpoint when cluster mode is enabled |
| replication\_group\_engine\_version\_actual | Because ElastiCache pulls the latest minor or patch for a version, this attribute returns the running version of the cache engine |
| replication\_group\_id | ID of the ElastiCache Replication Group |
| replication\_group\_member\_clusters | Identifiers of all the nodes that are part of this replication group |
| replication\_group\_primary\_endpoint\_address | Address of the endpoint for the primary node in the replication group, if the cluster mode is disabled |
| replication\_group\_reader\_endpoint\_address | Address of the endpoint for the reader node in the replication group, if the cluster mode is disabled |
| security\_group\_arn | Amazon Resource Name (ARN) of the security group |
| security\_group\_id | ID of the security group |
| subnet\_group\_name | The ElastiCache subnet group name |
<!-- END_TF_DOCS -->

## Examples

## Basic Usage

Redis replication group with encryption at rest and in transit across two subnets.

```hcl
module "elasticache" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache?depth=1&ref=master"

  enabled = true

  name           = "my-redis"
  description    = "Redis cache for the application layer"
  engine         = "redis"
  engine_version = "7.1"
  node_type      = "cache.t4g.medium"

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

  name           = "app-redis-ha"
  description    = "HA Redis cache with automatic failover"
  engine         = "redis"
  engine_version = "7.1"
  node_type      = "cache.r7g.large"

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

  name           = "app-redis-cluster"
  description    = "Redis cluster-mode replication group"
  engine         = "redis"
  engine_version = "7.1"
  node_type      = "cache.r7g.large"

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

  name           = "app-memcached"
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
