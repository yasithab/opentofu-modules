# DMS Module - Examples

## Basic Usage - MySQL to Aurora PostgreSQL Migration

Provisions the full DMS stack: required IAM roles, a replication subnet group, a replication instance, source and target endpoints, and a full-load migration task.

```hcl
module "dms_mysql_to_aurora" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//dms?depth=1&ref=v2.0.0"

  enabled = true

  create_iam_roles = true

  # Subnet group
  create_repl_subnet_group        = true
  repl_subnet_group_name          = "dms-migration-subnets"
  repl_subnet_group_description   = "Subnet group for DMS replication instance"
  repl_subnet_group_subnet_ids    = [
    "subnet-0aaa111122223333",
    "subnet-0bbb444455556666",
  ]

  # Replication instance
  create_repl_instance              = true
  repl_instance_id                  = "dms-mysql-to-aurora"
  repl_instance_class               = "dms.r5.large"
  repl_instance_engine_version      = "3.5.3"
  repl_instance_allocated_storage   = 100
  repl_instance_multi_az            = true
  repl_instance_publicly_accessible = false
  repl_instance_vpc_security_group_ids = ["sg-0cc77788899900001"]

  # Source: MySQL
  endpoints = {
    source = {
      endpoint_id   = "mysql-source"
      endpoint_type = "source"
      engine_name   = "mysql"
      server_name   = "mysql-source.us-east-1.rds.amazonaws.com"
      port          = 3306
      database_name = "appdb"
      username      = "dms_user"
      password      = "changeme-use-secrets-manager"
      ssl_mode      = "require"
    }
    target = {
      endpoint_id   = "aurora-pg-target"
      endpoint_type = "target"
      engine_name   = "aurora-postgresql"
      server_name   = "aurora-cluster.cluster-abc123.us-east-1.rds.amazonaws.com"
      port          = 5432
      database_name = "appdb"
      username      = "dms_user"
      password      = "changeme-use-secrets-manager"
      ssl_mode      = "require"
    }
  }

  # Replication task
  replication_tasks = {
    full_load = {
      replication_task_id       = "mysql-to-aurora-full-load"
      migration_type            = "full-load"
      source_endpoint_key       = "source"
      target_endpoint_key       = "target"
      replication_instance_arn  = module.dms_mysql_to_aurora.replication_instance_arn
      table_mappings = jsonencode({
        rules = [{
          rule-type = "selection"
          rule-id   = "1"
          rule-name = "include-all"
          object-locator = {
            schema-name = "%"
            table-name  = "%"
          }
          rule-action = "include"
        }]
      })
    }
  }

  tags = {
    Environment = "production"
    Team        = "data-engineering"
  }
}
```

## Ongoing Replication with Event Subscriptions

Configures full-load-and-CDC (change data capture) replication from an Oracle source to S3 for a data lake, with SNS event notifications on task failures.

```hcl
module "dms_oracle_to_s3" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//dms?depth=1&ref=v2.0.0"

  enabled = true

  create_iam_roles = true

  # Subnet group
  create_repl_subnet_group      = true
  repl_subnet_group_name        = "dms-oracle-s3-subnets"
  repl_subnet_group_subnet_ids  = [
    "subnet-0aaa111122223333",
    "subnet-0bbb444455556666",
  ]

  # Replication instance
  create_repl_instance              = true
  repl_instance_id                  = "dms-oracle-s3"
  repl_instance_class               = "dms.r5.xlarge"
  repl_instance_engine_version      = "3.5.3"
  repl_instance_allocated_storage   = 500
  repl_instance_multi_az            = true
  repl_instance_publicly_accessible = false
  repl_instance_vpc_security_group_ids = ["sg-0cc77788899900001"]
  repl_instance_kms_key_arn         = "arn:aws:kms:us-east-1:123456789012:key/mrk-1234abcd5678efgh"
  repl_instance_preferred_maintenance_window = "sun:03:00-sun:04:00"

  endpoints = {
    oracle_source = {
      endpoint_id     = "oracle-source"
      endpoint_type   = "source"
      engine_name     = "oracle"
      server_name     = "oracle-db.us-east-1.rds.amazonaws.com"
      port            = 1521
      database_name   = "ORCL"
      username        = "dms_user"
      password        = "changeme-use-secrets-manager"
      ssl_mode        = "require"
    }
    s3_target = {
      endpoint_id   = "s3-data-lake"
      endpoint_type = "target"
      engine_name   = "s3"
      s3_settings = {
        bucket_name             = "my-data-lake-bucket"
        bucket_folder           = "oracle-cdc"
        compression_type        = "GZIP"
        data_format             = "parquet"
        service_access_role_arn = "arn:aws:iam::123456789012:role/dms-s3-access-role"
      }
    }
  }

  replication_tasks = {
    full_load_cdc = {
      replication_task_id      = "oracle-to-s3-cdc"
      migration_type           = "full-load-and-cdc"
      source_endpoint_key      = "oracle_source"
      target_endpoint_key      = "s3_target"
      replication_instance_arn = module.dms_oracle_to_s3.replication_instance_arn
      table_mappings = jsonencode({
        rules = [{
          rule-type = "selection"
          rule-id   = "1"
          rule-name = "include-sales-schema"
          object-locator = {
            schema-name = "SALES"
            table-name  = "%"
          }
          rule-action = "include"
        }]
      })
    }
  }

  event_subscriptions = {
    task_failure = {
      name             = "dms-task-failure-alerts"
      enabled          = true
      event_categories = ["failure", "state change"]
      source_type      = "replication-task"
      sns_topic_arn    = "arn:aws:sns:us-east-1:123456789012:dms-alerts"
    }
  }

  tags = {
    Environment = "production"
    Team        = "data-engineering"
  }
}
```

## Existing Replication Instance - Endpoints and Tasks Only

Attaches new endpoints and a migration task to an existing replication instance and subnet group, skipping IAM role creation when they already exist in the account.

```hcl
module "dms_endpoints_only" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//dms?depth=1&ref=v2.0.0"

  enabled = true

  create_iam_roles       = false
  create_repl_subnet_group = false
  create_repl_instance   = false
  repl_instance_subnet_group_id = "dms-existing-subnet-group"

  access_iam_role_name = "dms-access-role-existing"

  access_kms_key_arns = [
    "arn:aws:kms:us-east-1:123456789012:key/mrk-1234abcd5678efgh",
  ]
  access_secret_arns = [
    "arn:aws:secretsmanager:us-east-1:123456789012:secret:dms/source-db-credentials-AbCdEf",
    "arn:aws:secretsmanager:us-east-1:123456789012:secret:dms/target-db-credentials-GhIjKl",
  ]

  endpoints = {
    pg_source = {
      endpoint_id                 = "postgres-source"
      endpoint_type               = "source"
      engine_name                 = "postgres"
      secrets_manager_arn         = "arn:aws:secretsmanager:us-east-1:123456789012:secret:dms/source-db-credentials-AbCdEf"
      secrets_manager_access_role_arn = "arn:aws:iam::123456789012:role/dms-secrets-access-role"
      database_name               = "appdb"
      ssl_mode                    = "require"
    }
    pg_target = {
      endpoint_id                 = "postgres-target"
      endpoint_type               = "target"
      engine_name                 = "postgres"
      secrets_manager_arn         = "arn:aws:secretsmanager:us-east-1:123456789012:secret:dms/target-db-credentials-GhIjKl"
      secrets_manager_access_role_arn = "arn:aws:iam::123456789012:role/dms-secrets-access-role"
      database_name               = "appdb_replica"
      ssl_mode                    = "require"
    }
  }

  replication_tasks = {
    migrate = {
      replication_task_id      = "pg-to-pg-migrate"
      migration_type           = "full-load"
      source_endpoint_key      = "pg_source"
      target_endpoint_key      = "pg_target"
      replication_instance_arn = "arn:aws:dms:us-east-1:123456789012:rep:ABCDEFGHIJKLMNOPQRST"
      table_mappings = jsonencode({
        rules = [{
          rule-type = "selection"
          rule-id   = "1"
          rule-name = "include-all"
          object-locator = {
            schema-name = "public"
            table-name  = "%"
          }
          rule-action = "include"
        }]
      })
    }
  }

  tags = {
    Environment = "staging"
    Team        = "data-engineering"
  }
}
```
