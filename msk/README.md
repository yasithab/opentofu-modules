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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11.0 |
| aws | >= 6.49, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| broker\_az\_distribution | Distribution of broker nodes across AZs. Currently only DEFAULT is supported | `string` | `"DEFAULT"` | no |
| broker\_ebs\_provisioned\_throughput | Provisioned throughput configuration for EBS volumes. Object with 'enabled' (bool) and 'volume\_throughput' (number in MiB/s) | <pre>object({<br/>    enabled           = optional(bool, true)<br/>    volume_throughput = optional(number)<br/>  })</pre> | `null` | no |
| broker\_ebs\_volume\_size | Size in GiB of the EBS volume for each broker node | `number` | `100` | no |
| broker\_instance\_type | EC2 instance type for the Kafka broker nodes | `string` | `"kafka.m5.large"` | no |
| broker\_public\_access\_type | Public access type for the cluster. Valid values: DISABLED, SERVICE\_PROVIDED\_EIPS | `string` | `null` | no |
| broker\_security\_groups | List of security group IDs to associate with the broker ENIs | `list(string)` | `[]` | no |
| broker\_subnets | List of subnet IDs for the broker nodes. Must be in at least 2 AZs | `list(string)` | `[]` | no |
| broker\_vpc\_connectivity | VPC connectivity configuration for multi-VPC private connectivity | `any` | `{}` | no |
| client\_authentication\_enabled | Whether to enable client authentication configuration | `bool` | `true` | no |
| client\_authentication\_sasl\_iam | Whether IAM authentication is enabled for the cluster | `bool` | `true` | no |
| client\_authentication\_sasl\_scram | Whether SASL/SCRAM authentication is enabled for the cluster | `bool` | `false` | no |
| client\_authentication\_tls\_certificate\_authority\_arns | List of ACM Private CA ARNs for TLS client authentication | `list(string)` | `[]` | no |
| client\_authentication\_unauthenticated | Whether to allow unauthenticated access | `bool` | `false` | no |
| cloudwatch\_log\_group | Existing CloudWatch Log Group name for broker logs. When `null` (default) and logging is enabled, the module creates a log group named `/aws/msk/<name>`. | `string` | `null` | no |
| cloudwatch\_log\_group\_retention\_in\_days | Retention in days for the module-created CloudWatch log group | `number` | `90` | no |
| cluster\_policy | IAM resource policy (JSON) to attach to the MSK cluster, e.g. for cross-account access via multi-VPC private connectivity. Set to `null` (default) to skip creating a cluster policy | `string` | `null` | no |
| configuration\_description | Description of the MSK configuration | `string` | `"MSK cluster configuration managed by OpenTofu"` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| encryption\_at\_rest\_kms\_key\_arn | KMS key ARN for encrypting data at rest. Uses AWS managed key if not specified | `string` | `null` | no |
| encryption\_in\_transit\_client\_broker | Encryption setting for data in transit between clients and brokers. Valid values: TLS, TLS\_PLAINTEXT, PLAINTEXT | `string` | `"TLS"` | no |
| encryption\_in\_transit\_in\_cluster | Whether data communication between brokers is encrypted | `bool` | `true` | no |
| enhanced\_monitoring | Monitoring level for the MSK cluster. Valid values: DEFAULT, PER\_BROKER, PER\_TOPIC\_PER\_BROKER, PER\_TOPIC\_PER\_PARTITION | `string` | `"PER_BROKER"` | no |
| firehose\_delivery\_stream | Kinesis Data Firehose delivery stream name for broker logs | `string` | `null` | no |
| kafka\_version | Version of Apache Kafka to deploy (e.g., '3.6.0') | `string` | `"3.6.0"` | no |
| logging\_enabled | Whether to enable broker log delivery configuration. When enabled and no `cloudwatch_log_group` is provided, the module creates a CloudWatch log group for broker logs. | `bool` | `true` | no |
| name | Name of the MSK cluster | `string` | n/a | yes |
| number\_of\_broker\_nodes | Total number of broker nodes across all AZs. Must be a multiple of the number of AZs | `number` | `3` | no |
| prometheus\_jmx\_exporter\_enabled | Whether to enable Prometheus JMX Exporter for open monitoring | `bool` | `true` | no |
| prometheus\_node\_exporter\_enabled | Whether to enable Prometheus Node Exporter for open monitoring | `bool` | `true` | no |
| s3\_logs\_bucket | S3 bucket name for broker logs | `string` | `null` | no |
| s3\_logs\_prefix | S3 key prefix for broker logs | `string` | `null` | no |
| scram\_secret\_arns | List of Secrets Manager secret ARNs to associate with the MSK cluster for SASL/SCRAM authentication | `list(string)` | `[]` | no |
| server\_properties | Contents of the server.properties file for Kafka broker configuration | `string` | `null` | no |
| serverless\_enabled | Whether to create a serverless MSK cluster instead of a provisioned one | `bool` | `false` | no |
| serverless\_vpc\_configs | List of VPC configurations for the serverless cluster. Each item requires 'subnet\_ids' and optionally 'security\_group\_ids' | <pre>list(object({<br/>    subnet_ids         = list(string)<br/>    security_group_ids = optional(list(string), [])<br/>  }))</pre> | `[]` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| bootstrap\_brokers | Comma-separated list of one or more hostname:port pairs of Kafka brokers for plaintext connections |
| bootstrap\_brokers\_sasl\_iam | Comma-separated list of one or more hostname:port pairs of Kafka brokers for SASL/IAM connections |
| bootstrap\_brokers\_sasl\_scram | Comma-separated list of one or more hostname:port pairs of Kafka brokers for SASL/SCRAM connections |
| bootstrap\_brokers\_tls | Comma-separated list of one or more hostname:port pairs of Kafka brokers for TLS connections |
| cluster\_arn | ARN of the MSK cluster |
| cluster\_name | Name of the MSK cluster |
| cluster\_policy\_current\_version | Current version of the MSK cluster policy |
| configuration\_arn | ARN of the MSK configuration |
| configuration\_latest\_revision | Latest revision of the MSK configuration |
| current\_version | Current version of the MSK cluster (used for updates) |
| serverless\_cluster\_arn | ARN of the MSK serverless cluster |
| zookeeper\_connect\_string | Comma-separated list of one or more hostname:port pairs of Apache Zookeeper nodes |
| zookeeper\_connect\_string\_tls | Comma-separated list of one or more hostname:port pairs of Apache Zookeeper nodes for TLS connections |
<!-- END_TF_DOCS -->

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
