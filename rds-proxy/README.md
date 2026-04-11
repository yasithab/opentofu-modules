# RDS Proxy

Provisions Amazon RDS Proxy instances to pool and share database connections, reducing connection overhead for applications that open many short-lived connections to RDS or Aurora databases.

## Features

- **Multi-Engine Support** - Connect to MySQL, PostgreSQL, and SQL Server databases via the `engine_family` setting
- **Connection Pooling** - Configure connection pool sizing, idle connection management, borrow timeouts, and session pinning filters
- **TLS Enforcement** - Require TLS encryption for all client-to-proxy connections by default
- **Secrets Manager Authentication** - Authenticate using credentials stored in AWS Secrets Manager with optional IAM database authentication
- **Flexible Targeting** - Target either a standalone RDS DB instance or an Aurora DB cluster
- **Custom Endpoints** - Create additional proxy endpoints with read-only or read-write target roles for routing traffic
- **IAM Role and Policy** - Automatically create an IAM role with policies for Secrets Manager and KMS access, or bring your own role
- **CloudWatch Logging** - Manage a dedicated CloudWatch log group for proxy diagnostic logs with configurable retention
- **Dual-Stack Networking** - Support for IPv4, IPv6, and dual-stack endpoint and target connection network types

## Usage

```hcl
module "rds_proxy" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds-proxy?depth=1&ref=master"

  name          = "app-db-proxy"
  engine_family = "POSTGRESQL"
  require_tls   = true

  vpc_subnet_ids         = ["subnet-aaa", "subnet-bbb"]
  vpc_security_group_ids = ["sg-0abc123def456789a"]

  auth = {
    superuser = {
      auth_scheme = "SECRETS"
      iam_auth    = "DISABLED"
      secret_arn  = "arn:aws:secretsmanager:us-east-1:123456789012:secret:rds!cluster-abc123-AbCdEf"
    }
  }

  target_db_cluster     = true
  db_cluster_identifier = "app-db"

  tags = {
    Environment = "production"
  }
}
```


## Examples

## Basic Usage

RDS Proxy in front of an Aurora PostgreSQL cluster using Secrets Manager for credentials.

```hcl
module "rds_proxy" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds-proxy?depth=1&ref=master"

  enabled        = true
  name           = "app-db-proxy"
  engine_family  = "POSTGRESQL"
  require_tls    = true

  vpc_subnet_ids         = ["subnet-0aa111bbb222", "subnet-0cc333ddd444"]
  vpc_security_group_ids = ["sg-0abc123def456789a"]

  auth = {
    superuser = {
      auth_scheme = "SECRETS"
      iam_auth    = "DISABLED"
      secret_arn  = "arn:aws:secretsmanager:us-east-1:123456789012:secret:rds!cluster-abc123-AbCdEf"
    }
  }

  target_db_cluster    = true
  db_cluster_identifier = "app-db"

  tags = {
    Environment = "production"
    Team        = "backend"
  }
}
```

## With IAM Authentication

RDS Proxy enforcing IAM database authentication for passwordless connections from application roles.

```hcl
module "rds_proxy_iam" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds-proxy?depth=1&ref=master"

  enabled        = true
  name           = "listings-db-proxy"
  engine_family  = "POSTGRESQL"
  require_tls    = true
  idle_client_timeout = 1800

  vpc_subnet_ids         = ["subnet-0aa111bbb222", "subnet-0cc333ddd444", "subnet-0ee555fff666"]
  vpc_security_group_ids = ["sg-0abc123def456789a"]

  auth = {
    iam_user = {
      auth_scheme               = "SECRETS"
      iam_auth                  = "REQUIRED"
      client_password_auth_type = "POSTGRES_SCRAM_SHA_256"
      secret_arn                = "arn:aws:secretsmanager:us-east-1:123456789012:secret:rds!cluster-listings-AbCdEf"
      description               = "IAM-authenticated app user"
    }
  }

  target_db_cluster     = true
  db_cluster_identifier = "listings-db"

  max_connections_percent      = 90
  max_idle_connections_percent = 50
  connection_borrow_timeout    = 120

  log_group_retention_in_days = 30
  kms_key_arns = [
    "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"
  ]

  tags = {
    Environment = "production"
    Team        = "listings"
  }
}
```

## MySQL Proxy with Additional Read-Only Endpoint

MySQL RDS Proxy with a custom read-only endpoint for analytics traffic.

```hcl
module "rds_proxy_mysql" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds-proxy?depth=1&ref=master"

  enabled        = true
  name           = "orders-db-proxy"
  engine_family  = "MYSQL"
  require_tls    = true

  vpc_subnet_ids         = ["subnet-0aa111bbb222", "subnet-0cc333ddd444"]
  vpc_security_group_ids = ["sg-0abc123def456789b"]

  auth = {
    app = {
      auth_scheme = "SECRETS"
      iam_auth    = "DISABLED"
      secret_arn  = "arn:aws:secretsmanager:us-east-1:123456789012:secret:orders-db-creds-AbCdEf"
    }
  }

  target_db_cluster     = true
  db_cluster_identifier = "orders-db"

  endpoints = {
    read_only = {
      name                   = "orders-db-proxy-ro"
      vpc_subnet_ids         = ["subnet-0aa111bbb222", "subnet-0cc333ddd444"]
      vpc_security_group_ids = ["sg-0abc123def456789b"]
      target_role            = "READ_ONLY"
    }
  }

  max_connections_percent      = 75
  max_idle_connections_percent = 25

  tags = {
    Environment = "production"
    Team        = "orders"
  }
}
```
