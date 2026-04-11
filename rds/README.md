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
