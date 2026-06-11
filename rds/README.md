# RDS

Provisions Amazon RDS database instances with comprehensive support for multiple database engines, read replicas, security groups, parameter groups, option groups, enhanced monitoring, and automated secret rotation.

## Features

- **Multi-Engine Support** - Deploy PostgreSQL, MySQL, MariaDB, Oracle, and SQL Server instances with engine-aware default port detection
- **Read Replicas** - Create and manage multiple read replicas with per-replica attribute overrides for instance class, storage, and availability zone
- **Security Group Management** - Automatically create and configure VPC security groups with flexible ingress and egress rules
- **Parameter and Option Groups** - Create custom DB parameter groups and option groups with configurable parameters
- **Enhanced Monitoring** - Optionally provision an IAM role for RDS Enhanced Monitoring with configurable collection intervals
- **CloudWatch Log Exports** - Create CloudWatch log groups and export engine-specific logs (audit, error, general, slowquery, postgresql, etc.)
- **Secrets Manager Integration** - Manage master user passwords through AWS Secrets Manager with optional automatic rotation schedules
- **Write-Only Passwords** - Support for OpenTofu write-only password attributes that are never stored in state
- **Blue/Green Deployments** - Enable low-downtime updates using RDS Blue/Green Deployment strategy
- **Point-in-Time Restore** - Restore from snapshots or arbitrary points in time
- **S3 Import** - Restore MySQL databases from Percona Xtrabackup files stored in S3
- **Encryption Enforcement** - Built-in check block that validates storage encryption is enabled

## Notes

- **Enhanced Monitoring and Performance Insights are disabled by default** (`monitoring_interval = 0`, `performance_insights_enabled = null`). For production workloads, consider setting `monitoring_interval` (e.g. `60`) and `performance_insights_enabled = true`.
- **Final snapshot identifier** - when `skip_final_snapshot = false` (the default) and `final_snapshot_identifier` is not provided, the module derives `<name>-final` automatically so instance deletion does not fail.

## Usage

```hcl
module "postgres" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds?depth=1&ref=master"

  name           = "app-db"
  engine         = "postgres"
  engine_version = "16.4"
  instance_class = "db.t4g.medium"

  allocated_storage      = 20
  max_allocated_storage  = 100
  create_db_subnet_group = true
  subnets                = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]
  vpc_id                 = "vpc-0abc123def456789"

  manage_master_user_password = true
  master_username             = "dbadmin"
  database_name               = "appdb"

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

## Examples

## Basic PostgreSQL

Standalone PostgreSQL instance with Secrets Manager-managed credentials and gp3 storage.

```hcl
module "postgres" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds?depth=1&ref=master"

  enabled = true
  name    = "app-db"

  engine         = "postgres"
  engine_version = "16.4"
  instance_class = "db.t4g.medium"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"

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

  backup_retention_period = 7
  deletion_protection     = true
  storage_encrypted       = true

  tags = {
    Environment = "production"
    Team        = "backend"
  }
}
```

## MySQL with Enhanced Monitoring and Option Groups

MySQL instance with CloudWatch logs, enhanced monitoring, and a custom option group.

```hcl
module "mysql" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds?depth=1&ref=master"

  enabled = true
  name    = "orders-db"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.r6g.large"

  allocated_storage     = 100
  max_allocated_storage = 500
  storage_type          = "gp3"

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

  monitoring_interval    = 60
  create_monitoring_role = true

  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  create_cloudwatch_log_group     = true
  cloudwatch_log_group_retention_in_days = 30

  create_db_option_group             = true
  db_option_group_engine_name        = "mysql"
  db_option_group_major_engine_version = "8.0"
  db_option_group_options = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"
      option_settings = [
        { name = "SERVER_AUDIT_EVENTS", value = "CONNECT,QUERY_DDL" },
      ]
    },
  ]

  create_db_parameter_group  = true
  db_parameter_group_family  = "mysql8.0"
  db_parameter_group_parameters = [
    { name = "slow_query_log", value = "1" },
    { name = "long_query_time", value = "2" },
  ]

  multi_az                     = true
  backup_retention_period      = 14
  backup_window                = "02:00-03:00"
  maintenance_window           = "sun:04:00-sun:05:00"
  deletion_protection          = true

  tags = {
    Environment = "production"
    Team        = "orders"
    DataClass   = "confidential"
  }
}
```

## Oracle with Character Set and License Model

Oracle SE2 instance with a custom character set and bring-your-own-license (BYOL) model.

```hcl
module "oracle" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds?depth=1&ref=master"

  enabled = true
  name    = "erp-db"

  engine         = "oracle-se2"
  engine_version = "19"
  instance_class = "db.r6i.xlarge"

  allocated_storage     = 200
  max_allocated_storage = 1000
  storage_type          = "io1"
  iops                  = 3000

  license_model      = "bring-your-own-license"
  character_set_name = "AL32UTF8"

  create_db_subnet_group = true
  subnets                = ["subnet-0aa111bbb222", "subnet-0cc333ddd444"]

  vpc_id = "vpc-0abc123def456789"

  security_group_rules = {
    app_ingress = {
      type                         = "ingress"
      referenced_security_group_id = "sg-0abc123def456789a"
      description                  = "Allow access from application tier"
    }
  }

  kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"
  storage_encrypted = true

  manage_master_user_password = true
  master_username             = "dbadmin"
  database_name               = "ERPDB"

  monitoring_interval    = 60
  create_monitoring_role = true

  enabled_cloudwatch_logs_exports = ["alert", "audit", "listener", "trace"]
  create_cloudwatch_log_group     = true

  create_db_option_group             = true
  db_option_group_engine_name        = "oracle-se2"
  db_option_group_major_engine_version = "19"
  db_option_group_options = [
    {
      option_name = "Timezone"
      option_settings = [
        { name = "TIME_ZONE", value = "US/Eastern" },
      ]
    },
  ]

  multi_az                = true
  backup_retention_period = 14
  deletion_protection     = true

  tags = {
    Environment = "production"
    Team        = "finance"
  }
}
```

## SQL Server with Timezone

SQL Server Standard instance with a custom timezone and domain authentication.

```hcl
module "sqlserver" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds?depth=1&ref=master"

  enabled = true
  name    = "reporting-db"

  engine         = "sqlserver-se"
  engine_version = "16.00"
  instance_class = "db.r6i.large"

  allocated_storage     = 200
  max_allocated_storage = 500
  storage_type          = "gp3"

  timezone           = "Eastern Standard Time"
  license_model      = "license-included"
  character_set_name = "SQL_Latin1_General_CP1_CI_AS"

  create_db_subnet_group = true
  subnets                = ["subnet-0aa111bbb222", "subnet-0cc333ddd444"]

  vpc_id = "vpc-0abc123def456789"

  security_group_rules = {
    app_ingress = {
      type                         = "ingress"
      referenced_security_group_id = "sg-0abc123def456789a"
      description                  = "Allow access from application tier"
    }
  }

  kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"
  storage_encrypted = true

  manage_master_user_password = true
  master_username             = "dbadmin"

  enabled_cloudwatch_logs_exports = ["agent", "error"]
  create_cloudwatch_log_group     = true

  multi_az                = true
  backup_retention_period = 7
  deletion_protection     = true

  tags = {
    Environment = "production"
    Team        = "reporting"
  }
}
```

## PostgreSQL with Read Replicas and Blue/Green Deployment

Production PostgreSQL with read replicas for scaling reads, and Blue/Green deployment for zero-downtime upgrades.

```hcl
module "postgres_advanced" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds?depth=1&ref=master"

  enabled = true
  name    = "listings-db"

  engine         = "postgres"
  engine_version = "16.4"
  instance_class = "db.r6g.2xlarge"

  allocated_storage     = 500
  max_allocated_storage = 2000
  storage_type          = "gp3"

  create_db_subnet_group = true
  subnets                = ["subnet-0aa111bbb222", "subnet-0cc333ddd444", "subnet-0ee555fff666"]

  vpc_id = "vpc-0abc123def456789"

  security_group_rules = {
    app_ingress = {
      type                         = "ingress"
      referenced_security_group_id = "sg-0abc123def456789a"
    }
  }

  kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"
  storage_encrypted = true

  manage_master_user_password = true
  master_username             = "dbadmin"
  database_name               = "listings"

  read_replicas = {
    reader-1 = {}
    reader-2 = { instance_class = "db.r6g.xlarge" }
  }

  blue_green_update = {
    enabled = "true"
  }

  performance_insights_enabled          = true
  performance_insights_retention_period = 731

  monitoring_interval    = 60
  create_monitoring_role = true

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true
  cloudwatch_log_group_retention_in_days = 30

  create_db_parameter_group  = true
  db_parameter_group_family  = "postgres16"
  db_parameter_group_parameters = [
    { name = "log_connections", value = "1" },
    { name = "log_min_duration_statement", value = "1000" },
  ]

  multi_az                = true
  backup_retention_period = 30
  deletion_protection     = true

  tags = {
    Environment = "production"
    Team        = "listings"
    CostCenter  = "product"
  }
}
```

## MariaDB - Simple Development Instance

Minimal MariaDB setup for development environments.

```hcl
module "mariadb_dev" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds?depth=1&ref=master"

  enabled = true
  name    = "dev-db"

  engine         = "mariadb"
  engine_version = "11.4"
  instance_class = "db.t4g.micro"

  allocated_storage = 20
  storage_type      = "gp3"

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
  master_username             = "devadmin"
  database_name               = "devdb"

  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true
  storage_encrypted       = true

  tags = {
    Environment = "development"
    Team        = "backend"
  }
}
```

## Reference

<details>
<summary>Requirements, providers, inputs and outputs (generated by terraform-docs)</summary>

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
| allocated\_storage | The allocated storage in gibibytes (GiB) | `number` | `null` | no |
| allow\_major\_version\_upgrade | Enable to allow major engine version upgrades when changing engine versions. Defaults to `false` | `bool` | `false` | no |
| apply\_immediately | Specifies whether any database modifications are applied immediately, or during the next maintenance window. Default is `false` | `bool` | `null` | no |
| auto\_minor\_version\_upgrade | Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window. Default `true` | `bool` | `null` | no |
| availability\_zone | The AZ for the RDS instance. If not set and multi\_az is false, a random AZ in the region will be selected | `string` | `null` | no |
| backup\_retention\_period | The days to retain backups for. Must be between 0 and 35 | `number` | `7` | no |
| backup\_window | The daily time range during which automated backups are created if automated backups are enabled using the backup\_retention\_period parameter. Time in UTC | `string` | `"02:00-03:00"` | no |
| blue\_green\_update | Enables low-downtime updates using RDS Blue/Green Deployments. See blue\_green\_update configuration below | `map(string)` | `{}` | no |
| ca\_cert\_identifier | The identifier of the CA certificate for the DB instance | `string` | `null` | no |
| character\_set\_name | The character set name to use for DB encoding in Oracle and Microsoft SQL instances (collation). This can't be changed. See Oracle Character Sets Supported in Amazon RDS or Server-Level Collation for Microsoft SQL Server for more information | `string` | `null` | no |
| cloudwatch\_log\_group\_class | Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT\_ACCESS | `string` | `null` | no |
| cloudwatch\_log\_group\_kms\_key\_id | The ARN of the KMS Key to use when encrypting log data | `string` | `null` | no |
| cloudwatch\_log\_group\_retention\_in\_days | The number of days to retain CloudWatch logs for the DB instance | `number` | `7` | no |
| cloudwatch\_log\_group\_skip\_destroy | Set to true if you do not wish the log group (and any logs it may contain) to be deleted at destroy time, and instead just remove the log group from the Terraform state | `bool` | `null` | no |
| cloudwatch\_log\_group\_tags | Additional tags for the CloudWatch log group(s) | `map(string)` | `{}` | no |
| copy\_tags\_to\_snapshot | Copy all instance tags to snapshots | `bool` | `null` | no |
| create\_cloudwatch\_log\_group | Determines whether a CloudWatch log group is created for each enabled\_cloudwatch\_logs\_exports | `bool` | `false` | no |
| create\_db\_option\_group | Determines whether to create a DB option group | `bool` | `false` | no |
| create\_db\_parameter\_group | Determines whether a DB parameter group should be created or use existing | `bool` | `false` | no |
| create\_db\_subnet\_group | Determines whether to create the database subnet group or use existing | `bool` | `false` | no |
| create\_monitoring\_role | Determines whether to create the IAM role for RDS enhanced monitoring | `bool` | `true` | no |
| create\_security\_group | Determines whether to create security group for RDS instance | `bool` | `true` | no |
| custom\_iam\_instance\_profile | The instance profile associated with the underlying Amazon EC2 instance of an RDS Custom DB instance | `string` | `null` | no |
| database\_insights\_mode | The mode of Database Insights to enable for the DB instance. Valid values: standard, advanced | `string` | `null` | no |
| database\_name | The name of the database to create when the DB instance is created | `string` | `null` | no |
| db\_option\_group\_description | The description of the option group | `string` | `null` | no |
| db\_option\_group\_engine\_name | Specifies the name of the engine that this option group should be associated with | `string` | `null` | no |
| db\_option\_group\_major\_engine\_version | Specifies the major version of the engine that this option group should be associated with | `string` | `null` | no |
| db\_option\_group\_name | The name of the option group. If omitted, defaults to var.name | `string` | `null` | no |
| db\_option\_group\_options | A list of options to apply to the option group | `any` | `[]` | no |
| db\_option\_group\_use\_name\_prefix | Determines whether the option group name is used as a prefix | `bool` | `true` | no |
| db\_parameter\_group\_description | The description of the DB parameter group | `string` | `null` | no |
| db\_parameter\_group\_family | The family of the DB parameter group | `string` | `null` | no |
| db\_parameter\_group\_name | Name of the DB parameter group to associate (existing, if not creating one) | `string` | `null` | no |
| db\_parameter\_group\_parameters | A list of DB parameters to apply. Note that parameters may differ from a family to an other | `list(map(string))` | `[]` | no |
| db\_parameter\_group\_use\_name\_prefix | Determines whether the DB parameter group name is used as a prefix | `bool` | `true` | no |
| db\_subnet\_group\_name | The name of the subnet group name (existing or created) | `string` | `null` | no |
| dedicated\_log\_volume | Use a dedicated log volume (DLV) for the DB instance. Requires Provisioned IOPS storage types | `bool` | `null` | no |
| delete\_automated\_backups | Specifies whether to remove automated backups immediately after the DB instance is deleted | `bool` | `null` | no |
| deletion\_protection | If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to `true`. The default is `true` | `bool` | `true` | no |
| domain | The ID of the Directory Service Active Directory domain to create the instance in | `string` | `null` | no |
| domain\_iam\_role\_name | (Required if domain is provided) The name of the IAM role to be used when making API calls to the Directory Service | `string` | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| enabled\_cloudwatch\_logs\_exports | Set of log types to export to cloudwatch. Valid values depend on engine: MySQL/MariaDB: audit, error, general, slowquery. PostgreSQL: postgresql, upgrade. Oracle: alert, audit, listener, trace, oemagent. MSSQL: agent, error | `list(string)` | `[]` | no |
| engine | The database engine to use. Valid values: mysql, postgres, mariadb, oracle-ee, oracle-se2, sqlserver-ee, sqlserver-se, sqlserver-ex, sqlserver-web | `string` | `null` | no |
| engine\_lifecycle\_support | The life cycle type for this DB instance. Valid values: open-source-rds-extended-support, open-source-rds-extended-support-disabled | `string` | `null` | no |
| engine\_version | The engine version to use. If auto\_minor\_version\_upgrade is enabled, you can provide a prefix of the version such as 8.0 (for 8.0.36) | `string` | `null` | no |
| final\_snapshot\_identifier | The name of your final DB snapshot when this DB instance is deleted. If skip\_final\_snapshot is false and this is not provided, defaults to `<name>-final` | `string` | `null` | no |
| iam\_database\_authentication\_enabled | Specifies whether mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled | `bool` | `null` | no |
| iam\_role\_description | Description of the monitoring role | `string` | `null` | no |
| iam\_role\_force\_detach\_policies | Whether to force detaching any policies the monitoring role has before destroying it | `bool` | `null` | no |
| iam\_role\_managed\_policy\_arns | Set of exclusive IAM managed policy ARNs to attach to the monitoring role | `list(string)` | `null` | no |
| iam\_role\_max\_session\_duration | Maximum session duration (in seconds) that you want to set for the monitoring role | `number` | `null` | no |
| iam\_role\_name | Friendly name of the monitoring role | `string` | `null` | no |
| iam\_role\_path | Path for the monitoring role | `string` | `null` | no |
| iam\_role\_permissions\_boundary | The ARN of the policy that is used to set the permissions boundary for the monitoring role | `string` | `null` | no |
| iam\_role\_use\_name\_prefix | Determines whether to use iam\_role\_name as is or create a unique name beginning with the iam\_role\_name as the prefix | `bool` | `false` | no |
| instance\_class | The instance type of the RDS instance | `string` | `null` | no |
| instance\_tags | A map of tags to add to only the DB instance | `map(string)` | `{}` | no |
| instance\_timeouts | Create, update, and delete timeout configurations for the DB instance | `map(string)` | `{}` | no |
| iops | The amount of provisioned IOPS. Setting this implies a storage\_type of io1 or io2 | `number` | `null` | no |
| kms\_key\_id | The ARN for the KMS encryption key. When specifying kms\_key\_id, storage\_encrypted needs to be set to true | `string` | `null` | no |
| license\_model | License model information for this DB instance. Optional, but required for some DB engines (e.g. Oracle) | `string` | `null` | no |
| maintenance\_window | The window to perform maintenance in. Syntax: ddd:hh24:mi-ddd:hh24:mi | `string` | `"sun:05:00-sun:06:00"` | no |
| manage\_master\_user\_password | Set to true to allow RDS to manage the master user password in Secrets Manager. Cannot be set if master\_password\_wo is provided | `bool` | `true` | no |
| manage\_master\_user\_password\_rotation | Whether to manage the master user password rotation. Setting this value to false after previously having been set to true will disable automatic rotation. | `bool` | `false` | no |
| master\_password\_wo | Write-only password for the master DB user. Never stored in Terraform state. Required unless manage\_master\_user\_password is set to true or unless snapshot\_identifier is provided | `string` | `null` | no |
| master\_password\_wo\_version | Version counter for the master DB password. Increment to trigger a password rotation without storing the new value in state | `number` | `1` | no |
| master\_user\_password\_rotate\_immediately | Specifies whether to rotate the secret immediately or wait until the next scheduled rotation window. | `bool` | `null` | no |
| master\_user\_password\_rotation\_automatically\_after\_days | Specifies the number of days between automatic scheduled rotations of the secret | `number` | `null` | no |
| master\_user\_password\_rotation\_duration | The length of the rotation window in hours. For example, 3h for a three hour window. | `string` | `null` | no |
| master\_user\_password\_rotation\_schedule\_expression | A cron() or rate() expression that defines the schedule for rotating your secret | `string` | `null` | no |
| master\_user\_secret\_kms\_key\_id | The Amazon Web Services KMS key identifier is the key ARN, key ID, alias ARN, or alias name for the KMS key | `string` | `null` | no |
| master\_username | Username for the master DB user. Required unless snapshot\_identifier or replicate\_source\_db is provided | `string` | `null` | no |
| max\_allocated\_storage | The upper limit to which Amazon RDS can automatically scale the storage of the DB instance. Set to 0 to disable storage autoscaling | `number` | `0` | no |
| monitoring\_interval | The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. Set to 0 to disable. Valid values: 0, 1, 5, 10, 15, 30, 60 | `number` | `0` | no |
| monitoring\_role\_arn | IAM role used by RDS to send enhanced monitoring metrics to CloudWatch | `string` | `null` | no |
| multi\_az | Specifies if the RDS instance is multi-AZ | `bool` | `false` | no |
| name | Name to use for resource naming and tagging. | `string` | `null` | no |
| network\_type | The type of network stack to use (IPV4 or DUAL) | `string` | `null` | no |
| option\_group\_name | Name of the option group to associate (existing, if not creating one) | `string` | `null` | no |
| performance\_insights\_enabled | Specifies whether Performance Insights is enabled or not | `bool` | `null` | no |
| performance\_insights\_kms\_key\_id | The ARN for the KMS key to encrypt Performance Insights data | `string` | `null` | no |
| performance\_insights\_retention\_period | Amount of time in days to retain Performance Insights data. Either 7 (7 days) or 731 (2 years) | `number` | `null` | no |
| port | The port on which the DB accepts connections | `number` | `null` | no |
| publicly\_accessible | Determines whether instances are publicly accessible. Default false | `bool` | `null` | no |
| read\_replicas | Map of read replicas and any specific/overriding attributes to be created. Each key becomes part of the identifier | <pre>map(object({<br/>    allocated_storage                     = optional(number)<br/>    allow_major_version_upgrade           = optional(bool)<br/>    apply_immediately                     = optional(bool)<br/>    auto_minor_version_upgrade            = optional(bool)<br/>    availability_zone                     = optional(string)<br/>    backup_retention_period               = optional(number, 0)<br/>    copy_tags_to_snapshot                 = optional(bool)<br/>    custom_iam_instance_profile           = optional(string)<br/>    database_insights_mode                = optional(string)<br/>    dedicated_log_volume                  = optional(bool)<br/>    deletion_protection                   = optional(bool)<br/>    enabled_cloudwatch_logs_exports       = optional(list(string))<br/>    identifier                            = optional(string)<br/>    identifier_prefix                     = optional(string)<br/>    instance_class                        = optional(string)<br/>    iops                                  = optional(number)<br/>    kms_key_id                            = optional(string)<br/>    max_allocated_storage                 = optional(number)<br/>    monitoring_interval                   = optional(number)<br/>    multi_az                              = optional(bool, false)<br/>    network_type                          = optional(string)<br/>    option_group_name                     = optional(string)<br/>    parameter_group_name                  = optional(string)<br/>    performance_insights_enabled          = optional(bool)<br/>    performance_insights_kms_key_id       = optional(string)<br/>    performance_insights_retention_period = optional(number)<br/>    publicly_accessible                   = optional(bool)<br/>    replica_mode                          = optional(string)<br/>    storage_throughput                    = optional(number)<br/>    storage_type                          = optional(string)<br/>    tags                                  = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| replica\_mode | Specifies whether the replica is in either mounted or open-read-only mode. Only supported for Oracle DB instances | `string` | `null` | no |
| replicate\_source\_db | Specifies that this resource is a Read Replica, and to use the value as the source database identifier. This correlates to the identifier of another Amazon RDS Database to replicate (if replicating within a single region) or ARN of the Amazon RDS Database to replicate (if replicating cross-region) | `string` | `null` | no |
| restore\_to\_point\_in\_time | Configuration block for restoring a DB instance to an arbitrary point in time. Requires the source\_db\_instance\_identifier or source\_dbi\_resource\_id argument | `map(string)` | `{}` | no |
| s3\_import | Configuration map used to restore from a Percona Xtrabackup in S3 (only MySQL is supported) | `map(string)` | `{}` | no |
| security\_group\_description | The description of the security group. If value is set to empty string it will contain instance name in the description | `string` | `null` | no |
| security\_group\_name | The security group name. Default value is (var.name) | `string` | `null` | no |
| security\_group\_rules | Map of security group rules to add to the security group created | <pre>map(object({<br/>    type                         = optional(string, "ingress")<br/>    ip_protocol                  = optional(string, "tcp")<br/>    from_port                    = optional(number)<br/>    to_port                      = optional(number)<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    description                  = optional(string)<br/>    prefix_list_id               = optional(string)<br/>    referenced_security_group_id = optional(string)<br/>    tags                         = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| security\_group\_tags | Additional tags for the security group | `map(string)` | `{}` | no |
| security\_group\_use\_name\_prefix | Determines whether the security group name (var.name) is used as a prefix | `bool` | `true` | no |
| skip\_final\_snapshot | Determines whether a final snapshot is created before the DB instance is deleted. If true is specified, no snapshot is created | `bool` | `false` | no |
| snapshot\_identifier | Specifies whether or not to create this database from a snapshot | `string` | `null` | no |
| storage\_encrypted | Specifies whether the DB instance is encrypted. The default is true | `bool` | `true` | no |
| storage\_throughput | The storage throughput value for the DB instance. Applicable only for gp3 storage type. Cannot be specified if the storage\_type is not gp3 | `number` | `null` | no |
| storage\_type | The storage type for the DB instance. Valid values: gp2, gp3, io1, io2, standard (magnetic) | `string` | `"gp3"` | no |
| subnets | List of subnet IDs used by database subnet group created | `list(string)` | `[]` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| timezone | Time zone of the DB instance. Only supported for Microsoft SQL Server | `string` | `null` | no |
| use\_identifier\_prefix | Whether to use `name` as a prefix for the DB instance identifier | `bool` | `false` | no |
| vpc\_id | ID of the VPC where to create security group | `string` | `null` | no |
| vpc\_security\_group\_ids | List of VPC security groups to associate to the instance in addition to the security group created | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| db\_instance\_address | The hostname of the RDS instance |
| db\_instance\_arn | The ARN of the RDS instance |
| db\_instance\_availability\_zone | The availability zone of the instance |
| db\_instance\_ca\_cert\_identifier | Specifies the identifier of the CA certificate for the DB instance |
| db\_instance\_cloudwatch\_log\_groups | Map of CloudWatch log groups created and their attributes |
| db\_instance\_endpoint | The connection endpoint in address:port format |
| db\_instance\_engine\_version\_actual | The running version of the database |
| db\_instance\_hosted\_zone\_id | The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record) |
| db\_instance\_id | The RDS instance identifier |
| db\_instance\_latest\_restorable\_time | The latest point in time to which the database can be restored with point-in-time restore |
| db\_instance\_master\_user\_secret | The master user secret when manage\_master\_user\_password is set to true |
| db\_instance\_multi\_az | Whether the RDS instance is multi-AZ |
| db\_instance\_name | The database name |
| db\_instance\_port | The database port |
| db\_instance\_resource\_id | The RDS Resource ID of this instance |
| db\_instance\_secretsmanager\_secret\_rotation\_enabled | Specifies whether automatic rotation is enabled for the secret |
| db\_instance\_status | The RDS instance status |
| db\_instance\_username | The master username for the database |
| db\_option\_group\_arn | The ARN of the DB option group created |
| db\_option\_group\_id | The ID of the DB option group created |
| db\_parameter\_group\_arn | The ARN of the DB parameter group created |
| db\_parameter\_group\_id | The ID of the DB parameter group created |
| db\_subnet\_group\_name | The db subnet group name |
| enhanced\_monitoring\_iam\_role\_arn | The Amazon Resource Name (ARN) specifying the enhanced monitoring role |
| enhanced\_monitoring\_iam\_role\_name | The name of the enhanced monitoring role |
| enhanced\_monitoring\_iam\_role\_unique\_id | Stable and unique string identifying the enhanced monitoring role |
| read\_replicas | A map of read replicas and their attributes |
| security\_group\_id | The security group ID of the RDS instance |
<!-- END_TF_DOCS -->

</details>
