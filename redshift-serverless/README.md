# Redshift Serverless

Amazon Redshift Serverless module for on-demand analytics without cluster management. Automatically scales compute capacity based on workload.

## Features

- **Namespace and workgroup** - creates both the namespace (database, users, schemas) and workgroup (compute resources)
- **Auto-scaling capacity** - configurable base and max RPU capacity with optional price-performance targeting
- **Admin password management** - AWS Secrets Manager managed passwords, random generation, or write-only passwords (never in state)
- **KMS encryption** - optional customer-managed key for namespace encryption
- **Security group** - built-in security group with configurable ingress/egress rules
- **Usage limits** - RPU consumption caps with configurable breach actions (log, emit-metric, deactivate)
- **VPC endpoint access** - managed VPC endpoints for cross-account or private connectivity
- **Snapshots** - on-demand snapshots with configurable retention and resource policies
- **Custom domain** - associate a custom domain with ACM certificate
- **IAM role** - optional dedicated IAM role with inline or managed policies for S3/data access
- **CloudWatch logging** - export connection, user, and user activity logs
- **Random password generation** - automatically generates a random admin password when `create_random_password` is enabled (default: true)
- **Internal KMS key creation** - optionally create a module-managed KMS key for namespace encryption via `kms_enabled`
- **VPC endpoint by default** - a managed VPC endpoint is created by default (`endpoint_enabled` defaults to true) for private connectivity
- **Private by default** - `publicly_accessible` defaults to false, ensuring the workgroup is not reachable from public networks

## Usage

```hcl
module "redshift_serverless" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//redshift-serverless?depth=1&ref=master"

  name           = "analytics"
  namespace_name = "analytics-ns"
  workgroup_name = "analytics-wg"
  db_name        = "analyticsdb"
  admin_username = "awsadmin"

  manage_admin_password   = true
  workgroup_base_capacity = 32
  workgroup_max_capacity  = 128

  subnet_ids = module.vpc.private_subnets
  vpc_id     = module.vpc.vpc_id
}
```


## Examples

## Basic Usage

Minimal Redshift Serverless namespace and workgroup using Secrets Manager for the admin password.

```hcl
module "redshift_serverless" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//redshift-serverless?depth=1&ref=master"

  enabled          = true
  name             = "analytics"
  iam_role_enabled = false

  namespace_name  = "analytics-ns"
  workgroup_name  = "analytics-wg"
  db_name         = "analyticsdb"
  admin_username  = "awsadmin"

  manage_admin_password = true

  workgroup_base_capacity = 32
  workgroup_max_capacity  = 128

  subnet_ids = ["subnet-0aa111bbb222", "subnet-0cc333ddd444", "subnet-0ee555fff666"]
  vpc_id     = "vpc-0abc123def456789"

  security_group_rules = {
    bi_tools = {
      from_port   = 5439
      to_port     = 5439
      ip_protocol = "tcp"
      cidr_ipv4   = "10.0.0.0/8"
      description = "Allow BI tools from internal network"
    }
  }

  tags = {
    Environment = "production"
    Team        = "analytics"
  }
}
```

## With KMS Encryption and IAM Role

Redshift Serverless with a CMK, a dedicated IAM role for S3 access, and CloudWatch audit logs.

```hcl
module "redshift_serverless_encrypted" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//redshift-serverless?depth=1&ref=master"

  enabled = true
  name    = "dw"

  namespace_name  = "dw-ns"
  workgroup_name  = "dw-wg"
  db_name         = "warehouse"
  admin_username  = "dwadmin"

  manage_admin_password = true
  admin_password_secret_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"

  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"

  iam_role_enabled = true
  iam_role_name    = "redshift-serverless-s3-access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "redshift-serverless.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"

  log_exports = ["connectionlog", "userlog", "useractivitylog"]

  workgroup_base_capacity = 64
  workgroup_max_capacity  = 256

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

  tags = {
    Environment = "production"
    Team        = "data"
    DataClass   = "confidential"
  }
}
```

## With Usage Limit and Write-Only Password

Redshift Serverless with a monthly RPU usage cap and a write-only admin password (never stored in state).

```hcl
module "redshift_serverless_limited" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//redshift-serverless?depth=1&ref=master"

  enabled          = true
  name             = "reporting"
  iam_role_enabled = false

  namespace_name  = "reporting-ns"
  workgroup_name  = "reporting-wg"
  db_name         = "reportingdb"
  admin_username  = "repadmin"

  manage_admin_password   = false
  use_admin_password_wo   = true
  # Provide the actual password via a variable marked sensitive=true:
  # admin_password = var.reporting_admin_password
  admin_user_password_wo_version = 1

  workgroup_base_capacity = 16
  workgroup_max_capacity  = 64

  usage_limit_enabled  = true
  usage_type           = "serverless-compute"
  usage_amount         = 100
  usage_period         = "monthly"
  usage_breach_action  = "emit-metric"

  subnet_ids = ["subnet-0aa111bbb222", "subnet-0cc333ddd444"]
  vpc_id     = "vpc-0abc123def456789"

  security_group_rules = {
    app = {
      from_port                    = 5439
      to_port                      = 5439
      ip_protocol                  = "tcp"
      referenced_security_group_id = "sg-0abc123def456789a"
    }
  }

  tags = {
    Environment = "production"
    Team        = "reporting"
  }
}
```

## Advanced - Price Performance Targeting with Custom Domain

Redshift Serverless with price-performance targeting, a custom domain, and snapshot management.

```hcl
module "redshift_serverless_advanced" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//redshift-serverless?depth=1&ref=master"

  enabled          = true
  name             = "platform-dw"
  iam_role_enabled = false

  namespace_name  = "platform-ns"
  workgroup_name  = "platform-wg"
  db_name         = "platformdb"
  admin_username  = "platformadmin"

  manage_admin_password            = true
  admin_password_secret_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"

  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"

  workgroup_base_capacity = 128
  workgroup_max_capacity  = 512

  workgroup_price_performance_target = {
    enabled = true
    level   = 75
  }

  workgroup_config_parameter = [
    {
      parameter_key   = "max_query_execution_time"
      parameter_value = "14400"
    }
  ]

  custom_domain_enabled        = true
  custom_domain_name           = "redshift.example.com"
  custom_domain_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc12345-1234-1234-1234-abc123456789"

  snapshot_enabled          = true
  snapshot_name             = "platform-dw-daily"
  snapshot_retention_period = "7"

  endpoint_enabled = true
  endpoint_name    = "platform-dw-endpoint"

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

  tags = {
    Environment = "production"
    Team        = "data-platform"
    CostCenter  = "data"
  }
}
```
