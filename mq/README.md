# MQ

OpenTofu module for provisioning Amazon MQ brokers supporting both RabbitMQ and ActiveMQ engines with configurable deployment modes, security groups, and encryption.

## Features

- **RabbitMQ and ActiveMQ** - supports both broker engine types with engine-specific default ingress rules
- **Flexible deployment modes** - single instance, active/standby multi-AZ, or cluster multi-AZ configurations
- **Security group management** - optionally create a security group with sensible default ingress rules per engine type, or bring your own
- **Encryption at rest** - configure KMS encryption with AWS-owned or customer-managed keys
- **LDAP authentication** - optional LDAP server integration for ActiveMQ authentication
- **Maintenance windows** - schedule maintenance windows for controlled broker updates
- **Data replication** - support for cross-region data replication (CRDR) between brokers
- **CloudWatch logging** - configurable audit and general log publishing

## Usage

```hcl
module "mq" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//mq?depth=1&ref=master"

  broker_name        = "my-rabbitmq"
  engine_type        = "RabbitMQ"
  engine_version     = "3.13"
  host_instance_type = "mq.m5.large"
  subnet_ids         = ["subnet-0abc123"]

  users = [
    {
      username = "appuser"
      password = var.mq_password
    }
  ]

  tags = {
    Environment = "production"
  }
}
```


## Examples

## Basic RabbitMQ (Single Instance)

A single-instance RabbitMQ broker with a module-created security group.

```hcl
module "rabbitmq" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//mq?depth=1&ref=master"

  enabled            = true
  broker_name        = "payments-rabbitmq"
  engine_type        = "RabbitMQ"
  engine_version     = "3.13"
  host_instance_type = "mq.m5.large"
  deployment_mode    = "SINGLE_INSTANCE"
  subnet_ids         = ["subnet-0aa111bbb222ccc333"]

  create_security_group = true
  vpc_id                = "vpc-0abc123def456789"

  users = [
    {
      username       = "appuser"
      password       = var.rabbitmq_password
      console_access = false
    }
  ]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## ActiveMQ with High Availability

ActiveMQ broker in ACTIVE_STANDBY_MULTI_AZ mode with encryption and CloudWatch logging.

```hcl
module "activemq_ha" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//mq?depth=1&ref=master"

  enabled            = true
  broker_name        = "orders-activemq"
  engine_type        = "ActiveMQ"
  engine_version     = "5.18"
  host_instance_type = "mq.m5.large"
  deployment_mode    = "ACTIVE_STANDBY_MULTI_AZ"
  subnet_ids         = ["subnet-0aa111bbb222", "subnet-0cc333ddd444"]

  create_security_group = true
  vpc_id                = "vpc-0abc123def456789"

  encryption_options = {
    kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"
    use_aws_owned_key = false
  }

  logs = {
    audit   = true
    general = true
  }

  maintenance_window_start_time = {
    day_of_week = "SUNDAY"
    time_of_day = "03:00"
    time_zone   = "UTC"
  }

  users = [
    {
      username       = "admin"
      password       = var.activemq_admin_password
      console_access = true
      groups         = ["admin"]
    },
    {
      username = "appuser"
      password = var.activemq_app_password
    }
  ]

  tags = {
    Environment = "production"
    Team        = "messaging"
  }
}
```

## RabbitMQ Cluster (Multi-AZ)

RabbitMQ CLUSTER_MULTI_AZ deployment with pre-existing security group and auto minor version upgrades.

```hcl
module "rabbitmq_cluster" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//mq?depth=1&ref=master"

  enabled            = true
  broker_name        = "notifications-rmq-cluster"
  engine_type        = "RabbitMQ"
  engine_version     = "3.13"
  host_instance_type = "mq.m5.xlarge"
  deployment_mode    = "CLUSTER_MULTI_AZ"
  subnet_ids         = ["subnet-0aa111bbb222", "subnet-0cc333ddd444", "subnet-0ee555fff666"]

  create_security_group = false
  security_groups       = ["sg-0abc123def456789a"]

  auto_minor_version_upgrade = true
  apply_immediately          = false

  logs = {
    general = true
  }

  users = [
    {
      username = "svcaccount"
      password = var.rmq_service_password
    }
  ]

  tags = {
    Environment = "production"
    Team        = "notifications"
    CostCenter  = "engineering"
  }
}
```
