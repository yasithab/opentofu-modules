# Neptune

Provisions Amazon Neptune graph database clusters with configurable instances, encryption, IAM authentication, Serverless v2 scaling, and CloudWatch log exports.

## Features

- **Cluster Configuration** - Deploy Neptune clusters with configurable engine versions and instance counts
- **Cluster Instances** - Define multiple named instances with per-instance overrides for instance class, availability zone, and promotion tier
- **Subnet Group** - Optionally create a subnet group or reference an existing one for VPC placement
- **Parameter Groups** - Create both cluster-level and instance-level parameter groups with configurable parameters
- **KMS Encryption** - Encrypt data at rest using AWS KMS with customer-managed or default keys (enabled by default)
- **IAM Authentication** - IAM database authentication enabled by default for secure, token-based access
- **CloudWatch Log Exports** - Export audit and slowquery logs to CloudWatch Logs for monitoring and troubleshooting
- **Serverless v2 Scaling** - Support for Neptune Serverless v2 with configurable min/max capacity for auto-scaling workloads
- **Backup Retention** - Configurable automated backup retention with customizable backup windows

## Usage

```hcl
module "neptune" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//neptune?depth=1&ref=master"

  name           = "app-graph"
  engine_version = "1.3.2.1"

  create_subnet_group = true
  subnet_ids          = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]

  vpc_security_group_ids = ["sg-0abc123def456789a"]

  instances = {
    writer = {}
    reader = {}
  }

  tags = {
    Environment = "production"
  }
}
```

## Examples

### Basic Neptune Cluster

Two-instance Neptune cluster with encryption and IAM authentication.

```hcl
module "neptune" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//neptune?depth=1&ref=master"

  enabled = true
  name    = "knowledge-graph"

  engine_version = "1.3.2.1"
  instance_class = "db.r6g.large"

  create_subnet_group = true
  subnet_ids          = ["subnet-0aa111bbb222", "subnet-0cc333ddd444", "subnet-0ee555fff666"]

  vpc_security_group_ids = ["sg-0abc123def456789a"]

  iam_database_authentication_enabled = true
  storage_encrypted                   = true

  instances = {
    writer = {}
    reader = {}
  }

  backup_retention_period = 7
  deletion_protection     = true

  tags = {
    Environment = "production"
    Team        = "data-engineering"
  }
}
```

### Neptune Serverless v2

Neptune cluster using Serverless v2 auto-scaling for variable workloads.

```hcl
module "neptune_serverless" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//neptune?depth=1&ref=master"

  enabled = true
  name    = "analytics-graph"

  engine_version = "1.3.2.1"
  instance_class = "db.serverless"

  serverless_v2_scaling_configuration = {
    min_capacity = 1.0
    max_capacity = 16.0
  }

  create_subnet_group = true
  subnet_ids          = ["subnet-0aa111bbb222", "subnet-0cc333ddd444"]

  vpc_security_group_ids = ["sg-0abc123def456789a"]

  instances = {
    writer = {}
  }

  storage_encrypted   = true
  deletion_protection = true

  tags = {
    Environment = "production"
    Team        = "analytics"
  }
}
```

### With KMS Encryption and CloudWatch Logs

Production Neptune cluster with CMK encryption, audit and slowquery logs, and custom parameters.

```hcl
module "neptune_production" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//neptune?depth=1&ref=master"

  enabled = true
  name    = "fraud-graph"

  engine_version = "1.3.2.1"
  instance_class = "db.r6g.xlarge"

  create_subnet_group = true
  subnet_ids          = ["subnet-0aa111bbb222", "subnet-0cc333ddd444", "subnet-0ee555fff666"]

  vpc_security_group_ids = ["sg-0abc123def456789a"]
  kms_key_arn            = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"

  iam_database_authentication_enabled = true
  iam_roles                           = ["arn:aws:iam::123456789012:role/NeptuneS3Access"]

  enable_cloudwatch_logs_exports = ["audit", "slowquery"]

  create_cluster_parameter_group = true
  cluster_parameter_group_family = "neptune1.3"
  cluster_parameters = [
    { name = "neptune_enable_audit_log", value = "1" },
    { name = "neptune_query_timeout", value = "120000" },
  ]

  instances = {
    writer = { instance_class = "db.r6g.xlarge" }
    reader = { instance_class = "db.r6g.large", promotion_tier = 1 }
  }

  backup_retention_period = 14
  deletion_protection     = true
  copy_tags_to_snapshot   = true

  tags = {
    Environment = "production"
    Team        = "fraud-detection"
    DataClass   = "confidential"
  }
}
```
