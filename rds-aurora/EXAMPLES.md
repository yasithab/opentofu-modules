# RDS Aurora Module - Examples

## Basic Aurora PostgreSQL

Aurora PostgreSQL cluster with two instances and Secrets Manager-managed credentials.

```hcl
module "aurora_postgres" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds-aurora?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds-aurora?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds-aurora?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds-aurora?depth=1&ref=v2.0.0"

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
