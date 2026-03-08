# Redshift Module - Examples

## Basic Usage

Single-node Redshift cluster with a randomly generated password and auto-created subnet and parameter groups.

```hcl
module "redshift" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//redshift?depth=1&ref=v2.0.0"

  enabled = true
  name    = "analytics"

  cluster_identifier = "analytics-prod"
  node_type          = "ra3.xlplus"
  number_of_nodes    = 1
  database_name      = "analyticsdb"
  master_username    = "awsuser"

  create_random_password = true

  subnet_ids = ["subnet-0aa111bbb222", "subnet-0cc333ddd444"]
  vpc_id     = "vpc-0abc123def456789"

  security_group_rules = {
    app_ingress = {
      from_port                    = 5439
      to_port                      = 5439
      ip_protocol                  = "tcp"
      referenced_security_group_id = "sg-0abc123def456789a"
      description                  = "Allow BI tools access"
    }
  }

  tags = {
    Environment = "production"
    Team        = "data"
  }
}
```

## Multi-Node with KMS Encryption

Three-node RA3 cluster with CMK encryption, enhanced VPC routing, and S3-based audit logging.

```hcl
module "redshift_multi_node" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//redshift?depth=1&ref=v2.0.0"

  enabled = true
  name    = "dw"

  cluster_identifier = "dw-prod"
  node_type          = "ra3.4xlarge"
  number_of_nodes    = 3
  database_name      = "warehouse"
  master_username    = "dwadmin"

  create_random_password = true

  encrypted   = true
  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"

  enhanced_vpc_routing = true

  subnet_ids = ["subnet-0aa111bbb222", "subnet-0cc333ddd444", "subnet-0ee555fff666"]
  vpc_id     = "vpc-0abc123def456789"

  security_group_rules = {
    bi_tools = {
      from_port                    = 5439
      to_port                      = 5439
      ip_protocol                  = "tcp"
      referenced_security_group_id = "sg-0abc123def456789a"
      description                  = "Allow BI tools"
    }
  }

  logging = {
    log_destination_type = "s3"
    bucket_name          = "my-redshift-audit-logs-123456789012"
    s3_key_prefix        = "dw-prod/"
    log_exports          = ["connectionlog", "userlog", "useractivitylog"]
  }

  create_cloudwatch_log_group            = true
  cloudwatch_log_group_retention_in_days = 30

  preferred_maintenance_window = "sun:10:00-sun:11:00"
  automated_snapshot_retention_period = 7

  tags = {
    Environment = "production"
    Team        = "data"
    DataClass   = "confidential"
  }
}
```

## With Secrets Manager-Managed Password and Snapshot Schedule

RA3 cluster using Secrets Manager for credential rotation and a custom snapshot schedule.

```hcl
module "redshift_managed_secret" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//redshift?depth=1&ref=v2.0.0"

  enabled = true
  name    = "reporting"

  cluster_identifier = "reporting-prod"
  node_type          = "ra3.xlplus"
  number_of_nodes    = 2
  database_name      = "reportingdb"
  master_username    = "reportingadmin"

  manage_master_password    = true
  create_random_password    = false

  encrypted   = true
  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"

  subnet_ids = ["subnet-0aa111bbb222", "subnet-0cc333ddd444"]
  vpc_id     = "vpc-0abc123def456789"

  security_group_rules = {
    analytics_ingress = {
      from_port   = 5439
      to_port     = 5439
      ip_protocol = "tcp"
      cidr_ipv4   = "10.0.0.0/8"
      description = "Allow from internal network"
    }
  }

  create_snapshot_schedule = true
  snapshot_schedule_identifier = "reporting-daily"
  snapshot_schedule_definitions = ["cron(0 20 * * ? *)"]

  manage_master_password_rotation                   = true
  master_password_rotation_automatically_after_days = 30

  tags = {
    Environment = "production"
    Team        = "reporting"
  }
}
```

## Advanced - Multi-AZ with Scheduled Resize Actions

Multi-AZ RA3 cluster with scheduled actions to scale down outside business hours and usage limits.

```hcl
module "redshift_advanced" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//redshift?depth=1&ref=v2.0.0"

  enabled = true
  name    = "etl"

  cluster_identifier                   = "etl-prod"
  node_type                            = "ra3.4xlarge"
  number_of_nodes                      = 4
  database_name                        = "etldb"
  master_username                      = "etladmin"
  create_random_password                = true
  encrypted                            = true
  kms_key_arn                          = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"
  multi_az                             = true
  availability_zone_relocation_enabled = true

  subnet_ids = ["subnet-0aa111bbb222", "subnet-0cc333ddd444", "subnet-0ee555fff666"]
  vpc_id     = "vpc-0abc123def456789"

  security_group_rules = {
    internal = {
      from_port   = 5439
      to_port     = 5439
      ip_protocol = "tcp"
      cidr_ipv4   = "10.0.0.0/8"
    }
  }

  create_scheduled_action_iam_role = true

  scheduled_actions = {
    scale_down_weekend = {
      name        = "etl-scale-down"
      description = "Scale down to 2 nodes on weekends"
      schedule    = "cron(0 20 ? * FRI *)"
      resize_cluster = {
        node_type       = "ra3.xlplus"
        number_of_nodes = 2
      }
    }
    scale_up_monday = {
      name        = "etl-scale-up"
      description = "Scale back up Monday morning"
      schedule    = "cron(0 6 ? * MON *)"
      resize_cluster = {
        node_type       = "ra3.4xlarge"
        number_of_nodes = 4
      }
    }
  }

  usage_limits = {
    daily_compute = {
      feature_type  = "concurrency-scaling"
      limit_type    = "time"
      amount        = 60
      period        = "daily"
      breach_action = "emit-metric"
    }
  }

  tags = {
    Environment = "production"
    Team        = "data-engineering"
    CostCenter  = "data"
  }
}
```
