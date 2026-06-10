# Amazon MSK (Managed Streaming for Apache Kafka)

OpenTofu module for provisioning and managing Amazon MSK clusters with support for provisioned and serverless modes, encryption, authentication, and comprehensive monitoring.

> **Note — logging default:** `logging_enabled` defaults to `true`. When no `cloudwatch_log_group` is provided, the module creates a CloudWatch log group `/aws/msk/<name>` (retention configurable via `cloudwatch_log_group_retention_in_days`, default 90 days) and delivers broker logs there. Set `logging_enabled = false` to disable. Provisioned clusters require at least 2 `broker_subnets`.

## Features

- **Provisioned Clusters** - Full Kafka cluster with configurable broker count, instance types, and storage
- **Serverless Clusters** - Fully managed serverless Kafka option with automatic scaling
- **Encryption** - TLS encryption in transit (enabled by default) and KMS encryption at rest
- **Client Authentication** - Support for IAM (default), SASL/SCRAM, TLS certificate-based, and unauthenticated access
- **Monitoring** - Enhanced CloudWatch monitoring, Prometheus JMX and Node exporters for open monitoring
- **Broker Logging** - Deliver logs to CloudWatch Logs, S3, or Kinesis Data Firehose
- **Custom Configuration** - Kafka server.properties managed as a versioned MSK configuration resource
- **SCRAM Secrets** - Associate Secrets Manager secrets for SASL/SCRAM authentication
- **VPC Connectivity** - Multi-VPC private connectivity and public access options
- **Cluster Policy** - Optional IAM resource policy on the cluster (`cluster_policy`) for cross-account access
- **Production Defaults** - TLS-only client-broker encryption, IAM auth, and PER_BROKER monitoring enabled by default

## Usage

```hcl
module "msk" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//msk?depth=1&ref=master"

  name           = "my-kafka-cluster"
  broker_subnets = ["subnet-abc123", "subnet-def456", "subnet-ghi789"]

  broker_security_groups = ["sg-abc123"]

  server_properties = <<-EOT
    auto.create.topics.enable=false
    default.replication.factor=3
    min.insync.replicas=2
  EOT

  tags = {
    Environment = "production"
  }
}
```

## Examples

### Basic Provisioned Cluster with IAM Auth

A three-broker cluster using IAM authentication and TLS encryption with default monitoring.

```hcl
module "msk_basic" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//msk?depth=1&ref=master"

  enabled = true
  name    = "events-kafka"

  kafka_version          = "3.6.0"
  number_of_broker_nodes = 3
  broker_instance_type   = "kafka.m5.large"
  broker_ebs_volume_size = 100

  broker_subnets         = ["subnet-aaa111", "subnet-bbb222", "subnet-ccc333"]
  broker_security_groups = ["sg-kafka-brokers"]

  client_authentication_sasl_iam = true
  encryption_in_transit_client_broker = "TLS"

  server_properties = <<-EOT
    auto.create.topics.enable=false
    default.replication.factor=3
    min.insync.replicas=2
    num.partitions=6
    log.retention.hours=168
  EOT

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

### Cluster with SCRAM Auth and CloudWatch Logging

A production cluster using SASL/SCRAM authentication with broker logs shipped to CloudWatch.

```hcl
module "msk_scram" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//msk?depth=1&ref=master"

  enabled = true
  name    = "secure-kafka"

  kafka_version          = "3.6.0"
  number_of_broker_nodes = 6
  broker_instance_type   = "kafka.m5.xlarge"
  broker_ebs_volume_size = 500

  broker_subnets         = ["subnet-aaa111", "subnet-bbb222", "subnet-ccc333"]
  broker_security_groups = ["sg-kafka-brokers"]

  encryption_at_rest_kms_key_arn      = "arn:aws:kms:ap-southeast-1:123456789012:key/mrk-abc123"
  encryption_in_transit_client_broker = "TLS"

  client_authentication_sasl_iam   = true
  client_authentication_sasl_scram = true
  scram_secret_arns = [
    "arn:aws:secretsmanager:ap-southeast-1:123456789012:secret:AmazonMSK_user1-AbCdEf",
    "arn:aws:secretsmanager:ap-southeast-1:123456789012:secret:AmazonMSK_user2-GhIjKl"
  ]

  enhanced_monitoring = "PER_TOPIC_PER_BROKER"
  logging_enabled     = true
  cloudwatch_log_group = "/aws/msk/secure-kafka"

  server_properties = <<-EOT
    auto.create.topics.enable=false
    default.replication.factor=3
    min.insync.replicas=2
  EOT

  tags = {
    Environment = "production"
    Team        = "data"
  }
}
```

### Serverless Cluster

A serverless MSK cluster with IAM authentication for workloads with variable throughput.

```hcl
module "msk_serverless" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//msk?depth=1&ref=master"

  enabled            = true
  name               = "serverless-kafka"
  serverless_enabled = true

  serverless_vpc_configs = [
    {
      subnet_ids         = ["subnet-aaa111", "subnet-bbb222", "subnet-ccc333"]
      security_group_ids = ["sg-kafka-serverless"]
    }
  ]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

### Cluster with Cross-Account Cluster Policy

Attach an IAM resource policy to the cluster to allow another account to connect via multi-VPC private connectivity. The policy applies to the provisioned cluster, or to the serverless cluster when `serverless_enabled = true`.

```hcl
module "msk_shared" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//msk?depth=1&ref=master"

  name                   = "shared-kafka"
  kafka_version          = "3.6.0"
  number_of_broker_nodes = 3
  broker_instance_type   = "kafka.m5.large"
  broker_subnets         = ["subnet-aaa111", "subnet-bbb222", "subnet-ccc333"]
  broker_security_groups = ["sg-kafka"]

  cluster_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowConsumerAccount"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::210987654321:root"
        }
        Action = [
          "kafka:CreateVpcConnection",
          "kafka:GetBootstrapBrokers",
          "kafka:DescribeCluster",
          "kafka:DescribeClusterV2"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Environment = "production"
  }
}
```
