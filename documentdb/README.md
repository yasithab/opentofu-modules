# DocumentDB

Provisions Amazon DocumentDB (MongoDB-compatible) clusters with configurable instances, encryption, TLS, CloudWatch log exports, and security group management.

## Features

- **Cluster Configuration** - Deploy DocumentDB clusters with configurable engine versions and instance counts
- **Cluster Instances** - Define multiple named instances with per-instance overrides for instance class, availability zone, and promotion tier
- **Subnet Group** - Optionally create a subnet group or reference an existing one for VPC placement
- **Cluster Parameter Group** - Create cluster-level parameter groups with configurable parameters including TLS and audit log settings
- **KMS Encryption** - Encrypt data at rest using AWS KMS with customer-managed or default keys (enabled by default)
- **TLS Enabled** - Transport Layer Security enabled by default via cluster parameter group for in-transit encryption
- **CloudWatch Log Exports** - Export audit and profiler logs to CloudWatch Logs for monitoring and compliance
- **Backup Retention** - Configurable automated backup retention with customizable backup windows
- **Write-Only Master Password** - Uses `master_password_wo` to avoid storing credentials in state, following the rds-aurora pattern
- **Security Group** - Automatically create and configure VPC security groups with flexible ingress and egress rules

## Usage

```hcl
module "documentdb" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//documentdb?depth=1&ref=master"

  name             = "app-docdb"
  master_username  = "docdbadmin"
  master_password_wo = var.docdb_password

  create_subnet_group = true
  subnet_ids          = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]

  vpc_id = "vpc-0abc123def456789"

  security_group_rules = {
    app_ingress = {
      type                         = "ingress"
      referenced_security_group_id = "sg-0abc123def456789a"
    }
  }

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

### Basic DocumentDB Cluster

Two-instance DocumentDB cluster with TLS and encryption at rest.

```hcl
module "documentdb" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//documentdb?depth=1&ref=master"

  enabled = true
  name    = "app-docdb"

  engine_version   = "5.0.0"
  master_username  = "docdbadmin"
  master_password_wo = var.docdb_password

  instance_class = "db.r6g.large"

  create_subnet_group = true
  subnet_ids          = ["subnet-0aa111bbb222", "subnet-0cc333ddd444", "subnet-0ee555fff666"]

  vpc_id = "vpc-0abc123def456789"

  security_group_rules = {
    app_ingress = {
      type                         = "ingress"
      referenced_security_group_id = "sg-0abc123def456789a"
      description                  = "Allow access from application tier"
    }
  }

  instances = {
    writer = {}
    reader = {}
  }

  backup_retention_period = 7
  deletion_protection     = true

  tags = {
    Environment = "production"
    Team        = "backend"
  }
}
```

### With KMS Encryption and Custom Parameters

DocumentDB cluster with CMK encryption, custom cluster parameters, and extended log exports.

```hcl
module "documentdb_encrypted" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//documentdb?depth=1&ref=master"

  enabled = true
  name    = "orders-docdb"

  engine_version   = "5.0.0"
  master_username  = "docdbadmin"
  master_password_wo = var.docdb_password

  instance_class = "db.r6g.xlarge"

  create_subnet_group = true
  subnet_ids          = ["subnet-0aa111bbb222", "subnet-0cc333ddd444", "subnet-0ee555fff666"]

  vpc_id     = "vpc-0abc123def456789"
  kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"

  security_group_rules = {
    app_ingress = {
      type                         = "ingress"
      referenced_security_group_id = "sg-0abc123def456789a"
    }
  }

  create_cluster_parameter_group = true
  cluster_parameter_group_family = "docdb5.0"
  cluster_parameters = [
    { name = "tls", value = "enabled" },
    { name = "audit_logs", value = "enabled" },
    { name = "profiler", value = "enabled" },
    { name = "profiler_threshold_ms", value = "100" },
  ]

  instances = {
    writer = { instance_class = "db.r6g.xlarge" }
    reader = { instance_class = "db.r6g.large" }
  }

  enabled_cloudwatch_logs_exports = ["audit", "profiler"]
  backup_retention_period         = 14
  deletion_protection             = true

  tags = {
    Environment = "production"
    Team        = "orders"
    DataClass   = "confidential"
  }
}
```
