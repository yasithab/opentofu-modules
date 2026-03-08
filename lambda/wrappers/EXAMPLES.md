# Lambda Wrappers Module - Examples

The `lambda/wrappers` module creates multiple Lambda functions in a single call using
`items` (per-function configuration) and `defaults` (shared baseline settings).

## Basic Usage

Create two simple Lambda functions sharing the same runtime and log retention defaults.

```hcl
module "lambda_functions" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/wrappers?depth=1&ref=v2.0.0"

  defaults = {
    runtime                           = "python3.12"
    timeout                           = 30
    memory_size                       = 256
    cloudwatch_logs_retention_in_days = 30
    tags = {
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }

  items = {
    api_handler = {
      function_name = "api-handler"
      handler       = "index.handler"
      description   = "Handles API Gateway requests"
      source_path   = "${path.module}/src/api_handler"
    }
    event_processor = {
      function_name = "event-processor"
      handler       = "processor.handler"
      description   = "Processes SQS events"
      source_path   = "${path.module}/src/event_processor"
      timeout       = 60
      memory_size   = 512
    }
  }
}
```

## VPC Functions With Shared Network Configuration

Deploy multiple VPC-attached functions sharing the same subnets and security groups.

```hcl
module "lambda_vpc_functions" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/wrappers?depth=1&ref=v2.0.0"

  defaults = {
    runtime                = "python3.12"
    timeout                = 60
    memory_size            = 512
    attach_network_policy  = true
    attach_tracing_policy  = true
    tracing_mode           = "Active"
    vpc_subnet_ids         = ["subnet-0abc123def456", "subnet-0def456abc123"]
    vpc_security_group_ids = ["sg-0abc123def456789"]
    cloudwatch_logs_retention_in_days = 30
    kms_key_arn            = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"
    tags = {
      Environment = "production"
      Network     = "private"
    }
  }

  items = {
    db_writer = {
      function_name = "db-writer"
      handler       = "writer.handler"
      source_path   = "${path.module}/src/db_writer"
      environment_variables = {
        DB_HOST = "mydb.cluster-xyz.us-east-1.rds.amazonaws.com"
      }
    }
    db_reader = {
      function_name = "db-reader"
      handler       = "reader.handler"
      source_path   = "${path.module}/src/db_reader"
      memory_size   = 256
      environment_variables = {
        DB_HOST = "mydb.cluster-xyz.us-east-1.rds.amazonaws.com"
      }
    }
  }
}
```

## Container Image Functions

Deploy multiple container-based Lambda functions from ECR.

```hcl
module "lambda_container_functions" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/wrappers?depth=1&ref=v2.0.0"

  defaults = {
    package_type   = "Image"
    create_package = false
    architectures  = ["arm64"]
    timeout        = 120
    tags = {
      Environment = "production"
      Delivery    = "container"
    }
  }

  items = {
    inference_v1 = {
      function_name = "ml-inference-v1"
      image_uri     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/ml-inference:v1"
      memory_size   = 3008
    }
    inference_v2 = {
      function_name = "ml-inference-v2"
      image_uri     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/ml-inference:v2"
      memory_size   = 4096
    }
  }
}
```
