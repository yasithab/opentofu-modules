# AWS EMR Serverless

OpenTofu module for provisioning and managing AWS EMR Serverless applications with support for Spark and Hive workloads, capacity configuration, VPC networking, and IAM execution roles.

## Features

- **Application Types** - Support for both Spark and Hive EMR Serverless applications
- **Capacity Management** - Configurable initial capacity (pre-warmed workers) and maximum capacity limits per application
- **Worker Configuration** - Fine-grained CPU, memory, and disk settings per worker type (Driver, Executor)
- **Auto Start/Stop** - Automatic application lifecycle management with configurable idle timeout
- **VPC Networking** - Deploy applications within VPC subnets with security group controls
- **Custom Images** - Use custom container images for application runtime environments
- **Interactive Sessions** - Optional EMR Studio and Livy endpoint integration
- **IAM Execution Role** - Automatically create an execution role with S3 and Glue access policies
- **Architecture Selection** - Choose between ARM64 and X86_64 CPU architectures
- **Production Defaults** - Auto-start/stop enabled, Glue access included, X86_64 architecture

## Usage

```hcl
module "emr_serverless" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//emr-serverless?depth=1&ref=master"

  name             = "spark-analytics"
  application_type = "Spark"
  release_label    = "emr-7.1.0"

  execution_role_s3_bucket_arns = ["arn:aws:s3:::my-data-bucket"]

  tags = {
    Environment = "production"
  }
}
```

## Examples

### Basic Spark Application

A simple Spark application with auto start/stop and an execution role with S3 and Glue access.

```hcl
module "emr_spark" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//emr-serverless?depth=1&ref=master"

  enabled          = true
  name             = "etl-spark"
  application_type = "Spark"
  release_label    = "emr-7.1.0"

  auto_start_enabled             = true
  auto_stop_enabled              = true
  auto_stop_idle_timeout_minutes = 15

  maximum_capacity = {
    cpu    = "200 vCPU"
    memory = "400 GB"
    disk   = "2000 GB"
  }

  execution_role_s3_bucket_arns      = ["arn:aws:s3:::data-lake-raw", "arn:aws:s3:::data-lake-processed"]
  execution_role_glue_access_enabled = true

  tags = {
    Environment = "production"
    Team        = "data-engineering"
  }
}
```

### Pre-warmed Spark Application in VPC

A Spark application with initial capacity for fast job startup, deployed within a VPC for private data access.

```hcl
module "emr_spark_vpc" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//emr-serverless?depth=1&ref=master"

  enabled          = true
  name             = "realtime-spark"
  application_type = "Spark"
  release_label    = "emr-7.1.0"

  subnet_ids         = ["subnet-aaa111", "subnet-bbb222"]
  security_group_ids = ["sg-emr-serverless"]

  initial_capacity = {
    Driver = {
      worker_count = 2
      worker_configuration = {
        cpu    = "4 vCPU"
        memory = "16 GB"
        disk   = "120 GB"
      }
    }
    Executor = {
      worker_count = 10
      worker_configuration = {
        cpu    = "4 vCPU"
        memory = "32 GB"
        disk   = "120 GB"
      }
    }
  }

  maximum_capacity = {
    cpu    = "400 vCPU"
    memory = "1024 GB"
    disk   = "4000 GB"
  }

  execution_role_s3_bucket_arns = [
    "arn:aws:s3:::data-lake-raw",
    "arn:aws:s3:::data-lake-curated",
    "arn:aws:s3:::emr-logs"
  ]

  tags = {
    Environment = "production"
    Team        = "real-time"
  }
}
```

### Hive Application with Custom Image

A Hive application using a custom container image for specialized dependencies.

```hcl
module "emr_hive" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//emr-serverless?depth=1&ref=master"

  enabled          = true
  name             = "hive-warehouse"
  application_type = "Hive"
  release_label    = "emr-7.1.0"
  architecture     = "ARM64"

  image_uri = "123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/emr-hive-custom:latest"

  auto_stop_idle_timeout_minutes = 30

  maximum_capacity = {
    cpu    = "100 vCPU"
    memory = "200 GB"
  }

  execution_role_s3_bucket_arns      = ["arn:aws:s3:::hive-warehouse"]
  execution_role_glue_access_enabled = true

  tags = {
    Environment = "production"
    Team        = "analytics"
  }
}
```
