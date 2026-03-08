# Lambda Module - Examples

## Basic Usage

Deploy a simple Python Lambda function packaged from a local directory.

```hcl
module "lambda_function" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda?depth=1&ref=v2.0.0"

  enabled = true

  function_name = "my-api-handler"
  description   = "Handles API Gateway requests"
  handler       = "index.handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 256

  source_path = "${path.module}/src"

  environment_variables = {
    LOG_LEVEL = "INFO"
    STAGE     = "production"
  }

  tags = {
    Environment = "production"
    Team        = "backend"
  }
}
```

## VPC-Attached Function with KMS and Dead Letter Queue

Deploy a function inside a VPC with customer-managed encryption and an SQS dead letter queue.

```hcl
module "lambda_vpc" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda?depth=1&ref=v2.0.0"

  enabled = true

  function_name = "order-processor"
  description   = "Processes order events from SQS"
  handler       = "processor.handler"
  runtime       = "python3.12"
  timeout       = 60
  memory_size   = 512

  source_path = "${path.module}/src/order_processor"

  vpc_subnet_ids         = ["subnet-0abc123def456", "subnet-0def456abc123"]
  vpc_security_group_ids = ["sg-0abc123def456789"]

  kms_key_arn            = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"
  dead_letter_target_arn = "arn:aws:sqs:us-east-1:123456789012:order-processor-dlq"
  attach_dead_letter_policy = true
  attach_network_policy  = true

  tracing_mode          = "Active"
  attach_tracing_policy = true

  cloudwatch_logs_retention_in_days = 30
  cloudwatch_logs_kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"

  environment_variables = {
    DB_HOST   = "mydb.cluster-xyz.us-east-1.rds.amazonaws.com"
    LOG_LEVEL = "INFO"
  }

  tags = {
    Environment = "production"
    Domain      = "orders"
  }
}
```

## Container Image Function from ECR

Deploy a Lambda function from a container image stored in ECR.

```hcl
module "lambda_container" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda?depth=1&ref=v2.0.0"

  enabled = true

  function_name  = "ml-inference"
  description    = "Machine learning inference endpoint"
  package_type   = "Image"
  image_uri      = "123456789012.dkr.ecr.us-east-1.amazonaws.com/ml-inference:latest"
  architectures  = ["arm64"]
  timeout        = 120
  memory_size    = 4096
  ephemeral_storage_size = 2048

  create_package = false

  environment_variables = {
    MODEL_PATH = "/opt/models/v2"
    LOG_LEVEL  = "WARNING"
  }

  tags = {
    Environment = "production"
    Purpose     = "ml-inference"
  }
}
```

## With Event Source Mapping and Provisioned Concurrency

Process Kinesis stream events with provisioned concurrency to eliminate cold starts.

```hcl
module "lambda_kinesis_consumer" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda?depth=1&ref=v2.0.0"

  enabled = true

  function_name = "kinesis-event-consumer"
  description   = "Consumes events from Kinesis stream"
  handler       = "consumer.handler"
  runtime       = "python3.12"
  timeout       = 120
  memory_size   = 512
  publish       = true

  source_path = "${path.module}/src/consumer"

  provisioned_concurrent_executions = 5

  event_source_mapping = {
    kinesis = {
      event_source_arn                   = "arn:aws:kinesis:us-east-1:123456789012:stream/app-events"
      function_response_types            = ["ReportBatchItemFailures"]
      starting_position                  = "LATEST"
      batch_size                         = 100
      maximum_batching_window_in_seconds = 30
    }
  }

  cloudwatch_logs_retention_in_days = 30

  tags = {
    Environment = "production"
    Source      = "kinesis"
  }
}
```
