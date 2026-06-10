# RDS Aurora

Provisions Amazon Aurora database clusters with support for Aurora MySQL and Aurora PostgreSQL, including provisioned and Serverless v2 engine modes, read replica autoscaling, custom endpoints, activity streams, and shard groups.

## Features

- **Aurora MySQL and PostgreSQL** - Deploy clusters using `aurora-mysql` or `aurora-postgresql` engines with engine-aware default port detection
- **Provisioned and Serverless v2** - Support for both provisioned instance classes and Serverless v2 auto-scaling capacity with configurable min/max ACUs
- **Cluster Instances** - Define multiple named instances with per-instance overrides for instance class, availability zone, and promotion tier
- **Read Replica Autoscaling** - Scale reader instances automatically based on CPU utilization or connection count using Application Auto Scaling
- **Custom Endpoints** - Create additional cluster endpoints for routing traffic to specific instance subsets
- **Security Group Management** - Automatically create and configure VPC security groups with flexible ingress and egress rules
- **Parameter Groups** - Create both cluster-level and instance-level parameter groups with configurable parameters
- **Enhanced Monitoring** - Optionally provision an IAM role for RDS Enhanced Monitoring at both the cluster and instance level
- **CloudWatch Log Exports** - Create CloudWatch log groups and export engine-specific logs (audit, error, general, slowquery, postgresql)
- **Secrets Manager Integration** - Manage master user passwords through AWS Secrets Manager with optional automatic rotation schedules
- **Activity Stream** - Enable database activity streaming for audit compliance with sync or async modes
- **Global Clusters** - Support for Aurora Global Database topologies with primary and secondary cluster configurations
- **Limitless Database** - Support for Aurora Limitless Database scalability mode and shard groups
- **Encryption Enforcement** - Built-in check block that validates storage encryption is enabled

## Notes

- **Enhanced Monitoring and Performance Insights are disabled by default** (`monitoring_interval = 0`, `cluster_monitoring_interval = 0`, `performance_insights_enabled = null`). For production workloads, consider setting a monitoring interval (e.g. `60`) and `performance_insights_enabled = true`. The enhanced monitoring IAM role is created automatically when monitoring is enabled at the cluster level, the module-wide instance level, or via any per-instance `monitoring_interval` override.

## Usage

```hcl
module "aurora_postgres" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds-aurora?depth=1&ref=master"

  name           = "app-db"
  engine         = "aurora-postgresql"
  engine_version = "16.2"
  instance_class = "db.r6g.large"

  create_db_subnet_group = true
  subnets                = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]
  vpc_id                 = "vpc-0abc123def456789"

  manage_master_user_password = true
  master_username             = "dbadmin"
  database_name               = "appdb"

  instances = {
    writer = {}
    reader = {}
  }

  security_group_rules = {
    app_ingress = {
      type                         = "ingress"
      referenced_security_group_id = "sg-0abc123def456789a"
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

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| allocated\_storage | The amount of storage in gibibytes (GiB) to allocate to each DB instance in the Multi-AZ DB cluster. (This setting is required to create a Multi-AZ DB cluster) | `number` | `null` | no |
| allow\_major\_version\_upgrade | Enable to allow major engine version upgrades when changing engine versions. Defaults to `false` | `bool` | `false` | no |
| apply\_immediately | Specifies whether any cluster modifications are applied immediately, or during the next maintenance window. Default is `false` | `bool` | `null` | no |
| auto\_minor\_version\_upgrade | Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window. Default `true` | `bool` | `null` | no |
| autoscaling\_enabled | Determines whether autoscaling of the cluster read replicas is enabled | `bool` | `false` | no |
| autoscaling\_max\_capacity | Maximum number of read replicas permitted when autoscaling is enabled | `number` | `2` | no |
| autoscaling\_min\_capacity | Minimum number of read replicas permitted when autoscaling is enabled | `number` | `0` | no |
| autoscaling\_policy\_name | Autoscaling policy name | `string` | `"target-metric"` | no |
| autoscaling\_scale\_in\_cooldown | Cooldown in seconds before allowing further scaling operations after a scale in | `number` | `300` | no |
| autoscaling\_scale\_out\_cooldown | Cooldown in seconds before allowing further scaling operations after a scale out | `number` | `300` | no |
| autoscaling\_target\_connections | Average number of connections threshold which will initiate autoscaling. Default value is 70% of db.r4/r5/r6g.large's default max\_connections | `number` | `700` | no |
| autoscaling\_target\_cpu | CPU threshold which will initiate autoscaling | `number` | `70` | no |
| availability\_zones | List of EC2 Availability Zones for the DB cluster storage where DB cluster instances can be created. RDS automatically assigns 3 AZs if less than 3 AZs are configured, which will show as a difference requiring resource recreation next Terraform apply | `list(string)` | `null` | no |
| backtrack\_window | The target backtrack window, in seconds. Only available for `aurora` engine currently. To disable backtracking, set this value to 0. Must be between 0 and 259200 (72 hours) | `number` | `null` | no |
| backup\_retention\_period | The days to retain backups for | `number` | `7` | no |
| ca\_cert\_identifier | The identifier of the CA certificate for the DB instance | `string` | `null` | no |
| cloudwatch\_log\_group\_class | Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT\_ACCESS | `string` | `null` | no |
| cloudwatch\_log\_group\_kms\_key\_id | The ARN of the KMS Key to use when encrypting log data | `string` | `null` | no |
| cloudwatch\_log\_group\_retention\_in\_days | The number of days to retain CloudWatch logs for the DB instance | `number` | `7` | no |
| cloudwatch\_log\_group\_skip\_destroy | Set to true if you do not wish the log group (and any logs it may contain) to be deleted at destroy time, and instead just remove the log group from the Terraform state | `bool` | `null` | no |
| cloudwatch\_log\_group\_tags | Additional tags for the CloudWatch log group(s) | `map(string)` | `{}` | no |
| cluster\_ca\_cert\_identifier | The CA certificate identifier to use for the DB cluster's server certificate. Currently only supported for multi-az DB clusters | `string` | `null` | no |
| cluster\_members | List of RDS Instances that are a part of this cluster | `list(string)` | `null` | no |
| cluster\_monitoring\_interval | Interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB cluster. To turn off collecting Enhanced Monitoring metrics, specify 0. Valid Values: 0, 1, 5, 10, 15, 30, 60 | `number` | `0` | no |
| cluster\_performance\_insights\_enabled | Enables Performance Insights for the RDS Cluster | `bool` | `null` | no |
| cluster\_performance\_insights\_kms\_key\_id | Specifies the KMS Key ID to encrypt Performance Insights data. If not specified, the default RDS KMS key will be used (aws/rds) | `string` | `null` | no |
| cluster\_performance\_insights\_retention\_period | Specifies the amount of time to retain performance insights data for. Defaults to 7 days if Performance Insights are enabled. Valid values are 7, month * 31 (where month is a number of months from 1-23), and 731 | `number` | `null` | no |
| cluster\_scalability\_type | Specifies the scalability mode of the Aurora DB cluster. When set to limitless, the cluster operates as an Aurora Limitless Database. When set to standard (the default), the cluster uses normal DB instance creation. Valid values: limitless, standard | `string` | `null` | no |
| cluster\_tags | A map of tags to add to only the cluster. Used for AWS Instance Scheduler tagging | `map(string)` | `{}` | no |
| cluster\_timeouts | Create, update, and delete timeout configurations for the cluster | `map(string)` | `{}` | no |
| cluster\_use\_name\_prefix | Whether to use `name` as a prefix for the cluster | `bool` | `false` | no |
| compute\_redundancy | Specifies whether to create standby DB shard groups for the DB shard group | `number` | `null` | no |
| copy\_tags\_to\_snapshot | Copy all Cluster `tags` to snapshots | `bool` | `null` | no |
| create\_cloudwatch\_log\_group | Determines whether a CloudWatch log group is created for each `enabled_cloudwatch_logs_exports` | `bool` | `false` | no |
| create\_db\_cluster\_activity\_stream | Determines whether a cluster activity stream is created. | `bool` | `false` | no |
| create\_db\_cluster\_parameter\_group | Determines whether a cluster parameter should be created or use existing | `bool` | `false` | no |
| create\_db\_parameter\_group | Determines whether a DB parameter should be created or use existing | `bool` | `false` | no |
| create\_db\_subnet\_group | Determines whether to create the database subnet group or use existing | `bool` | `false` | no |
| create\_monitoring\_role | Determines whether to create the IAM role for RDS enhanced monitoring | `bool` | `true` | no |
| create\_security\_group | Determines whether to create security group for RDS cluster | `bool` | `true` | no |
| create\_shard\_group | Whether to create a shard group resource | `bool` | `false` | no |
| custom\_iam\_instance\_profile | The instance profile associated with the underlying Amazon EC2 instance of an RDS Custom DB instance | `string` | `null` | no |
| database\_insights\_mode | The mode of Database Insights to enable for the DB cluster. Valid values: standard, advanced | `string` | `null` | no |
| database\_name | Name for an automatically created database on cluster creation | `string` | `null` | no |
| db\_cluster\_activity\_stream\_kms\_key\_id | The AWS KMS key identifier for encrypting messages in the database activity stream | `string` | `null` | no |
| db\_cluster\_activity\_stream\_mode | Specifies the mode of the database activity stream. Database events such as a change or access generate an activity stream event. One of: sync, async | `string` | `null` | no |
| db\_cluster\_db\_instance\_parameter\_group\_name | Instance parameter group to associate with all instances of the DB cluster. The `db_cluster_db_instance_parameter_group_name` is only valid in combination with `allow_major_version_upgrade` | `string` | `null` | no |
| db\_cluster\_instance\_class | The compute and memory capacity of each DB instance in the Multi-AZ DB cluster, for example db.m6g.xlarge. Not all DB instance classes are available in all AWS Regions, or for all database engines | `string` | `null` | no |
| db\_cluster\_parameter\_group\_description | The description of the DB cluster parameter group. Defaults to "Managed by Terraform" | `string` | `null` | no |
| db\_cluster\_parameter\_group\_family | The family of the DB cluster parameter group | `string` | `null` | no |
| db\_cluster\_parameter\_group\_name | The name of the DB cluster parameter group | `string` | `null` | no |
| db\_cluster\_parameter\_group\_parameters | A list of DB cluster parameters to apply. Note that parameters may differ from a family to an other | `list(map(string))` | `[]` | no |
| db\_cluster\_parameter\_group\_use\_name\_prefix | Determines whether the DB cluster parameter group name is used as a prefix | `bool` | `true` | no |
| db\_parameter\_group\_description | The description of the DB parameter group. Defaults to "Managed by Terraform" | `string` | `null` | no |
| db\_parameter\_group\_family | The family of the DB parameter group | `string` | `null` | no |
| db\_parameter\_group\_name | The name of the DB parameter group | `string` | `null` | no |
| db\_parameter\_group\_parameters | A list of DB parameters to apply. Note that parameters may differ from a family to an other | `list(map(string))` | `[]` | no |
| db\_parameter\_group\_use\_name\_prefix | Determines whether the DB parameter group name is used as a prefix | `bool` | `true` | no |
| db\_shard\_group\_identifier | The name of the DB shard group | `string` | `null` | no |
| db\_subnet\_group\_name | The name of the subnet group name (existing or created) | `string` | `null` | no |
| db\_system\_id | For use with RDS Custom. The ID of the DB system for the DB cluster | `string` | `null` | no |
| delete\_automated\_backups | Specifies whether to remove automated backups immediately after the DB cluster is deleted | `bool` | `null` | no |
| deletion\_protection | If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to `true`. The default is `true` | `bool` | `true` | no |
| domain | The ID of the Directory Service Active Directory domain to create the instance in | `string` | `null` | no |
| domain\_iam\_role\_name | (Required if domain is provided) The name of the IAM role to be used when making API calls to the Directory Service | `string` | `null` | no |
| enable\_global\_write\_forwarding | Whether cluster should forward writes to an associated global cluster. Applied to secondary clusters to enable them to forward writes to an `aws_rds_global_cluster`'s primary cluster | `bool` | `null` | no |
| enable\_http\_endpoint | Enable HTTP endpoint (data API). Only valid when engine\_mode is set to `serverless` | `bool` | `null` | no |
| enable\_local\_write\_forwarding | Whether read replicas can forward write operations to the writer DB instance in the DB cluster. By default, write operations aren't allowed on reader DB instances. | `bool` | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| enabled\_cloudwatch\_logs\_exports | Set of log types to export to cloudwatch. If omitted, no logs will be exported. The following log types are supported: `audit`, `error`, `general`, `slowquery`, `postgresql` | `list(string)` | `[]` | no |
| endpoints | Map of additional cluster endpoints and their attributes to be created | <pre>map(object({<br/>    identifier       = string<br/>    type             = string<br/>    excluded_members = optional(list(string))<br/>    static_members   = optional(list(string))<br/>    tags             = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| engine | The name of the database engine to be used for this DB cluster. Defaults to `aurora`. Valid Values: `aurora`, `aurora-mysql`, `aurora-postgresql` | `string` | `null` | no |
| engine\_lifecycle\_support | The life cycle type for this DB instance. This setting is valid for cluster types Aurora DB clusters and Multi-AZ DB clusters. Valid values are `open-source-rds-extended-support`, `open-source-rds-extended-support-disabled`. Default value is `open-source-rds-extended-support`. | `string` | `null` | no |
| engine\_mode | The database engine mode. Valid values: `global`, `multimaster`, `parallelquery`, `provisioned`, `serverless`. Defaults to: `provisioned` | `string` | `"provisioned"` | no |
| engine\_native\_audit\_fields\_included | Specifies whether the database activity stream includes engine-native audit fields. This option only applies to an Oracle DB instance. By default, no engine-native audit fields are included | `bool` | `false` | no |
| engine\_version | The database engine version. Updating this argument results in an outage | `string` | `null` | no |
| final\_snapshot\_identifier | The name of your final DB snapshot when this DB cluster is deleted. If omitted, no final snapshot will be made | `string` | `null` | no |
| global\_cluster\_identifier | The global cluster identifier specified on `aws_rds_global_cluster` | `string` | `null` | no |
| iam\_database\_authentication\_enabled | Specifies whether or mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled | `bool` | `null` | no |
| iam\_role\_description | Description of the monitoring role | `string` | `null` | no |
| iam\_role\_force\_detach\_policies | Whether to force detaching any policies the monitoring role has before destroying it | `bool` | `null` | no |
| iam\_role\_managed\_policy\_arns | Set of exclusive IAM managed policy ARNs to attach to the monitoring role | `list(string)` | `null` | no |
| iam\_role\_max\_session\_duration | Maximum session duration (in seconds) that you want to set for the monitoring role | `number` | `null` | no |
| iam\_role\_name | Friendly name of the monitoring role | `string` | `null` | no |
| iam\_role\_path | Path for the monitoring role | `string` | `null` | no |
| iam\_role\_permissions\_boundary | The ARN of the policy that is used to set the permissions boundary for the monitoring role | `string` | `null` | no |
| iam\_role\_use\_name\_prefix | Determines whether to use `iam_role_name` as is or create a unique name beginning with the `iam_role_name` as the prefix | `bool` | `false` | no |
| iam\_roles | Map of IAM roles and supported feature names to associate with the cluster | `map(map(string))` | `{}` | no |
| instance\_class | Instance type to use at master instance. Note: if `autoscaling_enabled` is `true`, this will be the same instance class used on instances created by autoscaling | `string` | `null` | no |
| instance\_force\_destroy | Destroys a read replica cluster instance before deletion. This can be used to force deletion of a read replica without first stopping replication | `bool` | `null` | no |
| instance\_timeouts | Create, update, and delete timeout configurations for the cluster instance(s) | `map(string)` | `{}` | no |
| instances | Map of cluster instances and any specific/overriding attributes to be created | <pre>map(object({<br/>    apply_immediately                     = optional(bool)<br/>    auto_minor_version_upgrade            = optional(bool)<br/>    availability_zone                     = optional(string)<br/>    copy_tags_to_snapshot                 = optional(bool)<br/>    custom_iam_instance_profile           = optional(string)<br/>    db_parameter_group_name               = optional(string)<br/>    force_destroy                         = optional(bool)<br/>    identifier                            = optional(string)<br/>    identifier_prefix                     = optional(string)<br/>    instance_class                        = optional(string)<br/>    monitoring_interval                   = optional(number)<br/>    performance_insights_enabled          = optional(bool)<br/>    performance_insights_kms_key_id       = optional(string)<br/>    performance_insights_retention_period = optional(number)<br/>    preferred_maintenance_window          = optional(string)<br/>    promotion_tier                        = optional(number)<br/>    publicly_accessible                   = optional(bool)<br/>    tags                                  = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| instances\_use\_identifier\_prefix | Determines whether cluster instance identifiers are used as prefixes | `bool` | `false` | no |
| iops | The amount of Provisioned IOPS (input/output operations per second) to be initially allocated for each DB instance in the Multi-AZ DB cluster | `number` | `null` | no |
| is\_primary\_cluster | Determines whether cluster is primary cluster with writer instance (set to `false` for global cluster and replica clusters) | `bool` | `true` | no |
| kms\_key\_id | The ARN for the KMS encryption key. When specifying `kms_key_id`, `storage_encrypted` needs to be set to `true` | `string` | `null` | no |
| manage\_master\_user\_password | Set to true to allow RDS to manage the master user password in Secrets Manager. Cannot be set if `master_password` is provided | `bool` | `true` | no |
| manage\_master\_user\_password\_rotation | Whether to manage the master user password rotation. By default, false on creation, rotation is managed by RDS. There is not currently a way to disable this on initial creation even when set to false. Setting this value to false after previously having been set to true will disable automatic rotation. | `bool` | `false` | no |
| master\_password\_wo | Write-only password for the master DB user. Never stored in Terraform state. Required unless `manage_master_user_password` is set to `true` or unless `snapshot_identifier` or `replication_source_identifier` is provided or unless a `global_cluster_identifier` is provided when the cluster is the secondary cluster of a global database | `string` | `null` | no |
| master\_password\_wo\_version | Version counter for the master DB password. Increment to trigger a password rotation without storing the new value in state | `number` | `1` | no |
| master\_user\_password\_rotate\_immediately | Specifies whether to rotate the secret immediately or wait until the next scheduled rotation window. | `bool` | `null` | no |
| master\_user\_password\_rotation\_automatically\_after\_days | Specifies the number of days between automatic scheduled rotations of the secret. Either `master_user_password_rotation_automatically_after_days` or `master_user_password_rotation_schedule_expression` must be specified | `number` | `null` | no |
| master\_user\_password\_rotation\_duration | The length of the rotation window in hours. For example, 3h for a three hour window. | `string` | `null` | no |
| master\_user\_password\_rotation\_schedule\_expression | A cron() or rate() expression that defines the schedule for rotating your secret. Either `master_user_password_rotation_automatically_after_days` or `master_user_password_rotation_schedule_expression` must be specified | `string` | `null` | no |
| master\_user\_secret\_kms\_key\_id | The Amazon Web Services KMS key identifier is the key ARN, key ID, alias ARN, or alias name for the KMS key | `string` | `null` | no |
| master\_username | Username for the master DB user. Required unless `snapshot_identifier` or `replication_source_identifier` is provided or unless a `global_cluster_identifier` is provided when the cluster is the secondary cluster of a global database | `string` | `null` | no |
| max\_acu | The maximum capacity of the DB shard group in Aurora capacity units (ACUs) | `number` | `null` | no |
| min\_acu | The minimum capacity of the DB shard group in Aurora capacity units (ACUs) | `number` | `null` | no |
| monitoring\_interval | The interval, in seconds, between points when Enhanced Monitoring metrics are collected for instances. Set to `0` to disable. Default is `0` | `number` | `0` | no |
| monitoring\_role\_arn | IAM role used by RDS to send enhanced monitoring metrics to CloudWatch | `string` | `null` | no |
| name | Name to use for resource naming and tagging. | `string` | `null` | no |
| network\_type | The type of network stack to use (IPV4 or DUAL) | `string` | `null` | no |
| performance\_insights\_enabled | Specifies whether Performance Insights is enabled or not | `bool` | `null` | no |
| performance\_insights\_kms\_key\_id | The ARN for the KMS key to encrypt Performance Insights data | `string` | `null` | no |
| performance\_insights\_retention\_period | Amount of time in days to retain Performance Insights data. Either 7 (7 days) or 731 (2 years) | `number` | `null` | no |
| port | The port on which the DB accepts connections | `number` | `null` | no |
| predefined\_metric\_type | The metric type to scale on. Valid values are `RDSReaderAverageCPUUtilization` and `RDSReaderAverageDatabaseConnections` | `string` | `"RDSReaderAverageCPUUtilization"` | no |
| preferred\_backup\_window | The daily time range during which automated backups are created if automated backups are enabled using the `backup_retention_period` parameter. Time in UTC | `string` | `"02:00-03:00"` | no |
| preferred\_maintenance\_window | The weekly time range during which system maintenance can occur, in (UTC) | `string` | `"sun:05:00-sun:06:00"` | no |
| publicly\_accessible | Determines whether instances are publicly accessible. Default `false` | `bool` | `null` | no |
| replication\_source\_identifier | ARN of a source DB cluster or DB instance if this DB cluster is to be created as a Read Replica | `string` | `null` | no |
| restore\_to\_point\_in\_time | Map of nested attributes for cloning Aurora cluster | `map(string)` | `{}` | no |
| s3\_import | Configuration map used to restore from a Percona Xtrabackup in S3 (only MySQL is supported) | `map(string)` | `{}` | no |
| scaling\_configuration | Map of nested attributes with scaling properties. Only valid when `engine_mode` is set to `serverless` | `map(string)` | `{}` | no |
| security\_group\_description | The description of the security group. If value is set to empty string it will contain cluster name in the description | `string` | `null` | no |
| security\_group\_name | The security group name. Default value is (`var.name`) | `string` | `null` | no |
| security\_group\_rules | Map of security group rules to add to the cluster security group created | <pre>map(object({<br/>    type                         = optional(string, "ingress")<br/>    ip_protocol                  = optional(string, "tcp")<br/>    from_port                    = optional(number)<br/>    to_port                      = optional(number)<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    description                  = optional(string)<br/>    prefix_list_id               = optional(string)<br/>    referenced_security_group_id = optional(string)<br/>    tags                         = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| security\_group\_tags | Additional tags for the security group | `map(string)` | `{}` | no |
| security\_group\_use\_name\_prefix | Determines whether the security group name (`var.name`) is used as a prefix | `bool` | `true` | no |
| serverlessv2\_scaling\_configuration | Map of nested attributes with serverless v2 scaling properties. Only valid when `engine_mode` is set to `provisioned` | `map(string)` | `{}` | no |
| shard\_group\_tags | Additional tags for the shard group | `map(string)` | `{}` | no |
| shard\_group\_timeouts | Create, update, and delete timeout configurations for the shard group | `map(string)` | `{}` | no |
| skip\_final\_snapshot | Determines whether a final snapshot is created before the cluster is deleted. If true is specified, no snapshot is created | `bool` | `false` | no |
| snapshot\_identifier | Specifies whether or not to create this cluster from a snapshot. You can use either the name or ARN when specifying a DB cluster snapshot, or the ARN when specifying a DB snapshot | `string` | `null` | no |
| source\_region | The source region for an encrypted replica DB cluster | `string` | `null` | no |
| storage\_encrypted | Specifies whether the DB cluster is encrypted. The default is `true` | `bool` | `true` | no |
| storage\_type | Determines the storage type for the DB cluster. Optional for Single-AZ, required for Multi-AZ DB clusters. Valid values for Single-AZ: `aurora`, `""` (default, both refer to Aurora Standard), `aurora-iopt1` (Aurora I/O Optimized). Valid values for Multi-AZ: `io1` (default). | `string` | `null` | no |
| subnets | List of subnet IDs used by database subnet group created | `list(string)` | `[]` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| vpc\_id | ID of the VPC where to create security group | `string` | `null` | no |
| vpc\_security\_group\_ids | List of VPC security groups to associate to the cluster in addition to the security group created | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| additional\_cluster\_endpoints | A map of additional cluster endpoints and their attributes |
| cluster\_arn | Amazon Resource Name (ARN) of cluster |
| cluster\_ca\_certificate\_identifier | CA identifier of the CA certificate used for the DB instance's server certificate |
| cluster\_ca\_certificate\_valid\_till | Expiration date of the DB instance’s server certificate |
| cluster\_database\_name | Name for an automatically created database on cluster creation |
| cluster\_endpoint | Writer endpoint for the cluster |
| cluster\_engine\_version\_actual | The running version of the cluster database |
| cluster\_hosted\_zone\_id | The Route53 Hosted Zone ID of the endpoint |
| cluster\_id | The RDS Cluster Identifier |
| cluster\_instances | A map of cluster instances and their attributes |
| cluster\_master\_user\_secret | The generated database master user secret when `manage_master_user_password` is set to `true` |
| cluster\_master\_username | The database master username |
| cluster\_members | List of RDS Instances that are a part of this cluster |
| cluster\_port | The database port |
| cluster\_reader\_endpoint | A read-only endpoint for the cluster, automatically load-balanced across replicas |
| cluster\_resource\_id | The RDS Cluster Resource ID |
| cluster\_role\_associations | A map of IAM roles associated with the cluster and their attributes |
| db\_cluster\_activity\_stream\_kinesis\_stream\_name | The name of the Amazon Kinesis data stream to be used for the database activity stream |
| db\_cluster\_cloudwatch\_log\_groups | Map of CloudWatch log groups created and their attributes |
| db\_cluster\_parameter\_group\_arn | The ARN of the DB cluster parameter group created |
| db\_cluster\_parameter\_group\_id | The ID of the DB cluster parameter group created |
| db\_cluster\_secretsmanager\_secret\_rotation\_enabled | Specifies whether automatic rotation is enabled for the secret |
| db\_parameter\_group\_arn | The ARN of the DB parameter group created |
| db\_parameter\_group\_id | The ID of the DB parameter group created |
| db\_shard\_group\_arn | ARN of the shard group |
| db\_shard\_group\_endpoint | The connection endpoint for the DB shard group |
| db\_shard\_group\_resource\_id | The AWS Region-unique, immutable identifier for the DB shard group |
| db\_subnet\_group\_name | The db subnet group name |
| enhanced\_monitoring\_iam\_role\_arn | The Amazon Resource Name (ARN) specifying the enhanced monitoring role |
| enhanced\_monitoring\_iam\_role\_name | The name of the enhanced monitoring role |
| enhanced\_monitoring\_iam\_role\_unique\_id | Stable and unique string identifying the enhanced monitoring role |
| security\_group\_id | The security group ID of the cluster |
<!-- END_TF_DOCS -->

## Examples

## Basic Aurora PostgreSQL

Aurora PostgreSQL cluster with two instances and Secrets Manager-managed credentials.

```hcl
module "aurora_postgres" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds-aurora?depth=1&ref=master"

  enabled = true
  name    = "app-db"

  engine         = "aurora-postgresql"
  engine_version = "16.2"
  instance_class = "db.r6g.large"

  create_db_subnet_group = true
  subnets                = ["subnet-0aa111bbb222", "subnet-0cc333ddd444", "subnet-0ee555fff666"]

  vpc_id = "vpc-0abc123def456789"

  security_group_rules = {
    app_ingress = {
      type                         = "ingress"
      referenced_security_group_id = "sg-0abc123def456789a"
      description                  = "Allow access from application tier"
    }
  }

  manage_master_user_password = true
  master_username             = "dbadmin"
  database_name               = "appdb"

  instances = {
    writer = {}
    reader = {}
  }

  backup_retention_period = 7
  deletion_protection     = true
  storage_encrypted       = true

  tags = {
    Environment = "production"
    Team        = "backend"
  }
}
```

## With KMS Encryption and Enhanced Monitoring

Aurora MySQL cluster with CMK encryption, enhanced monitoring, and CloudWatch logs.

```hcl
module "aurora_mysql" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds-aurora?depth=1&ref=master"

  enabled = true
  name    = "orders-db"

  engine         = "aurora-mysql"
  engine_version = "8.0.mysql_aurora.3.05.2"
  instance_class = "db.r6g.xlarge"

  create_db_subnet_group = true
  subnets                = ["subnet-0aa111bbb222", "subnet-0cc333ddd444", "subnet-0ee555fff666"]

  vpc_id = "vpc-0abc123def456789"

  security_group_rules = {
    app_ingress = {
      type                         = "ingress"
      from_port                    = 3306
      to_port                      = 3306
      referenced_security_group_id = "sg-0abc123def456789a"
    }
  }

  kms_key_id              = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"
  storage_encrypted       = true
  manage_master_user_password = true
  master_username         = "dbadmin"
  database_name           = "ordersdb"

  monitoring_interval      = 60
  create_monitoring_role   = true

  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  create_cloudwatch_log_group     = true
  cloudwatch_log_group_retention_in_days = 30

  instances = {
    writer = { instance_class = "db.r6g.xlarge" }
    reader = { instance_class = "db.r6g.large" }
  }

  backup_retention_period      = 14
  preferred_backup_window      = "02:00-03:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"
  deletion_protection          = true

  tags = {
    Environment = "production"
    Team        = "orders"
    DataClass   = "confidential"
  }
}
```

## Aurora Serverless v2

Aurora PostgreSQL with Serverless v2 scaling - ideal for variable workloads.

```hcl
module "aurora_serverless_v2" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds-aurora?depth=1&ref=master"

  enabled = true
  name    = "analytics-db"

  engine         = "aurora-postgresql"
  engine_version = "16.2"
  instance_class = "db.serverless"
  engine_mode    = "provisioned"

  serverlessv2_scaling_configuration = {
    min_capacity             = 0.5
    max_capacity             = 16
    seconds_until_auto_pause = 300
  }

  create_db_subnet_group = true
  subnets                = ["subnet-0aa111bbb222", "subnet-0cc333ddd444"]

  vpc_id = "vpc-0abc123def456789"

  security_group_rules = {
    app_ingress = {
      type                         = "ingress"
      referenced_security_group_id = "sg-0abc123def456789a"
    }
  }

  manage_master_user_password = true
  master_username             = "postgres"
  database_name               = "analytics"

  instances = {
    writer = {}
  }

  storage_encrypted   = true
  deletion_protection = true
  skip_final_snapshot = false
  final_snapshot_identifier = "analytics-db-final"

  tags = {
    Environment = "production"
    Team        = "analytics"
  }
}
```

## Advanced - With Autoscaling, Parameter Groups, and Activity Stream

Production cluster with read replica autoscaling, custom parameter groups, and database activity streaming for audit compliance.

```hcl
module "aurora_advanced" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds-aurora?depth=1&ref=master"

  enabled = true
  name    = "listings-db"

  engine         = "aurora-postgresql"
  engine_version = "16.2"
  instance_class = "db.r6g.2xlarge"

  create_db_subnet_group = true
  subnets                = ["subnet-0aa111bbb222", "subnet-0cc333ddd444", "subnet-0ee555fff666"]

  vpc_id = "vpc-0abc123def456789"

  security_group_rules = {
    app_ingress = {
      type                         = "ingress"
      referenced_security_group_id = "sg-0abc123def456789a"
    }
  }

  kms_key_id              = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"
  storage_encrypted       = true
  manage_master_user_password = true
  master_username         = "dbadmin"
  database_name           = "listings"

  instances = {
    writer = { instance_class = "db.r6g.2xlarge" }
    reader = { instance_class = "db.r6g.xlarge", promotion_tier = 1 }
  }

  autoscaling_enabled          = true
  autoscaling_min_capacity     = 1
  autoscaling_max_capacity     = 5
  predefined_metric_type       = "RDSReaderAverageCPUUtilization"
  autoscaling_target_cpu       = 70

  create_db_cluster_parameter_group   = true
  db_cluster_parameter_group_family   = "aurora-postgresql16"
  db_cluster_parameter_group_parameters = [
    { name = "log_connections", value = "1" },
    { name = "log_min_duration_statement", value = "1000" },
  ]

  create_db_cluster_activity_stream          = true
  db_cluster_activity_stream_mode            = "async"
  db_cluster_activity_stream_kms_key_id      = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"

  monitoring_interval    = 60
  create_monitoring_role = true

  backup_retention_period = 30
  deletion_protection     = true

  tags = {
    Environment = "production"
    Team        = "listings"
    CostCenter  = "product"
  }
}
```
