# Lambda

OpenTofu module for deploying AWS Lambda functions and layers with built-in support for packaging, IAM role management, event source mappings, CloudWatch logging, and function URLs.

## Features

- **Functions and layers** - deploy Lambda functions or Lambda layers from local source, local zip, S3 packages, or container images (ECR)
- **Automatic packaging** - build and package source code automatically with support for Docker-based builds
- **IAM role management** - create and configure an execution role with fine-grained policy attachments for CloudWatch, VPC, X-Ray, dead letter queues, and custom policies
- **Event source mappings** - connect to Kinesis, SQS, DynamoDB, Kafka (MSK and self-managed), and DocumentDB event sources with filtering and batching
- **Function URLs** - create HTTP(S) endpoints with configurable CORS and authorization (IAM or public)
- **VPC networking** - deploy functions inside a VPC with configurable subnets and security groups
- **Provisioned concurrency** - eliminate cold starts by allocating provisioned concurrency on published versions
- **Async event configuration** - configure retry policies and destination routing for failed/successful invocations
- **Advanced logging** - structured JSON or text log formats with configurable application and system log levels
- **Lambda@Edge** - deploy functions to CloudFront edge locations with automatic timeout constraints

## Prerequisites

- **python3** must be available on `PATH` (or `python.exe` on Windows). The packaging pipeline (`package.tf` / `package.py`) shells out to Python to compute source hashes and build deployment archives whenever `create_package = true`. Set `create_package = false` (e.g. when deploying from a container image or an existing zip) to avoid the Python dependency.

## Notes

- `environment_variables` is marked `sensitive`, so plans will hide environment variable diffs (you will see `(sensitive value)` instead of individual key changes).
- `authorization_type` for Lambda Function URLs defaults to `AWS_IAM`. Set it explicitly to `NONE` if you need a public endpoint (previous default).
- `s3_server_side_encryption` defaults to `AES256` for packages stored on S3.
- `cors` is now a typed object (`allow_credentials`, `allow_headers`, `allow_methods`, `allow_origins`, `expose_headers`, `max_age` - all optional) and defaults to `null` instead of `{}`.
- **BREAKING:** `policy_statements`, `assume_role_policy_statements`, `event_source_mapping`, and `trusted_entities` are now fully typed (`map(object)` / `list(object)` with `optional()` attributes); unknown attributes are rejected. See `variables.tf` for the full schemas. In particular:
  - `trusted_entities` no longer accepts plain service-name strings; express service principals as `{ type = "Service", identifiers = ["foo.amazonaws.com"] }`.
  - `event_source_mapping` entry `filter_criteria` is always a list of `{ pattern }` objects (a single bare object is no longer accepted), and per-entry `enabled` must be a bool.

## Usage

```hcl
module "lambda" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda?depth=1&ref=master"

  name          = "my-api-handler"
  handler       = "index.handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 256

  source_path = "${path.module}/src"

  environment_variables = {
    LOG_LEVEL = "INFO"
  }

  tags = {
    Environment = "production"
  }
}
```

## Examples

## Basic Usage

Deploy a simple Python Lambda function packaged from a local directory.

```hcl
module "lambda_function" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda?depth=1&ref=master"

  enabled = true

  name          = "my-api-handler"
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
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda?depth=1&ref=master"

  enabled = true

  name          = "order-processor"
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
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda?depth=1&ref=master"

  enabled = true

  name           = "ml-inference"
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
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda?depth=1&ref=master"

  enabled = true

  name          = "kinesis-event-consumer"
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

## Reference

<details>
<summary>Requirements, providers, inputs and outputs (generated by terraform-docs)</summary>

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11.0 |
| aws | >= 6.49, < 7.0 |
| external | ~> 2.0 |
| local | ~> 2.0 |
| null | ~> 3.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |
| external | ~> 2.0 |
| local | ~> 2.0 |
| null | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| allowed\_triggers | Map of allowed triggers to create Lambda permissions | <pre>map(object({<br/>    statement_id           = optional(string)<br/>    action                 = optional(string, "lambda:InvokeFunction")<br/>    principal              = optional(string)<br/>    service                = optional(string)<br/>    principal_org_id       = optional(string)<br/>    source_arn             = optional(string)<br/>    source_account         = optional(string)<br/>    event_source_token     = optional(string)<br/>    function_url_auth_type = optional(string)<br/>  }))</pre> | `{}` | no |
| architectures | Instruction set architecture for your Lambda function. Valid values are ["x86\_64"] and ["arm64"]. | `list(string)` | `null` | no |
| artifacts\_dir | Directory name where artifacts should be stored | `string` | `"builds"` | no |
| assume\_role\_policy\_statements | Map of dynamic policy statements for assuming Lambda Function role (trust relationship) | <pre>map(object({<br/>    sid         = optional(string)<br/>    effect      = optional(string)<br/>    actions     = optional(list(string))<br/>    not_actions = optional(list(string))<br/>    principals = optional(list(object({<br/>      type        = string<br/>      identifiers = list(string)<br/>    })), [])<br/>    not_principals = optional(list(object({<br/>      type        = string<br/>      identifiers = list(string)<br/>    })), [])<br/>    condition = optional(list(object({<br/>      test     = string<br/>      variable = string<br/>      values   = list(string)<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| attach\_async\_event\_policy | Controls whether async event policy should be added to IAM role for Lambda Function | `bool` | `false` | no |
| attach\_cloudwatch\_logs\_policy | Controls whether CloudWatch Logs policy should be added to IAM role for Lambda Function | `bool` | `true` | no |
| attach\_create\_log\_group\_permission | Controls whether to add the create log group permission to the CloudWatch logs policy | `bool` | `true` | no |
| attach\_dead\_letter\_policy | Controls whether SNS/SQS dead letter notification policy should be added to IAM role for Lambda Function | `bool` | `false` | no |
| attach\_network\_policy | Controls whether VPC/network policy should be added to IAM role for Lambda Function | `bool` | `false` | no |
| attach\_policies | Controls whether list of policies should be added to IAM role for Lambda Function | `bool` | `false` | no |
| attach\_policy | Controls whether policy should be added to IAM role for Lambda Function | `bool` | `false` | no |
| attach\_policy\_json | Controls whether policy\_json should be added to IAM role for Lambda Function | `bool` | `false` | no |
| attach\_policy\_jsons | Controls whether policy\_jsons should be added to IAM role for Lambda Function | `bool` | `false` | no |
| attach\_policy\_statements | Controls whether policy\_statements should be added to IAM role for Lambda Function | `bool` | `false` | no |
| attach\_tracing\_policy | Controls whether X-Ray tracing policy should be added to IAM role for Lambda Function | `bool` | `false` | no |
| authorization\_type | The type of authentication that the Lambda Function URL uses. Set to 'AWS\_IAM' to restrict access to authenticated IAM users only. Set to 'NONE' to bypass IAM authentication and create a public endpoint. | `string` | `"AWS_IAM"` | no |
| build\_in\_docker | Whether to build dependencies in Docker | `bool` | `false` | no |
| capacity\_provider\_config | Configuration block for Lambda Capacity Provider. Contains lambda\_managed\_instances\_capacity\_provider\_config sub-block. | `any` | `null` | no |
| cloudwatch\_logs\_deletion\_protection\_enabled | Whether to enable deletion protection on the CloudWatch log group. | `bool` | `null` | no |
| cloudwatch\_logs\_kms\_key\_id | The ARN of the KMS Key to use when encrypting log data. | `string` | `null` | no |
| cloudwatch\_logs\_log\_group\_class | Specified the log class of the log group. Possible values are: `STANDARD` or `INFREQUENT_ACCESS` | `string` | `null` | no |
| cloudwatch\_logs\_retention\_in\_days | Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653. | `number` | `30` | no |
| cloudwatch\_logs\_skip\_destroy | Whether to keep the log group (and any logs it may contain) at destroy time. | `bool` | `false` | no |
| cloudwatch\_logs\_tags | A map of tags to assign to the resource. | `map(string)` | `{}` | no |
| code\_sha256 | Base64-encoded representation of the source code package file. Used to trigger updates. | `string` | `null` | no |
| code\_signing\_config\_arn | Amazon Resource Name (ARN) for a Code Signing Configuration | `string` | `null` | no |
| compatible\_architectures | A list of Architectures Lambda layer is compatible with. Currently x86\_64 and arm64 can be specified. | `list(string)` | `null` | no |
| compatible\_runtimes | A list of Runtimes this layer is compatible with. Up to 5 runtimes can be specified. | `list(string)` | `[]` | no |
| cors | CORS settings to be used by the Lambda Function URL | <pre>object({<br/>    allow_credentials = optional(bool)<br/>    allow_headers     = optional(list(string))<br/>    allow_methods     = optional(list(string))<br/>    allow_origins     = optional(list(string))<br/>    expose_headers    = optional(list(string))<br/>    max_age           = optional(number)<br/>  })</pre> | `null` | no |
| create\_async\_event\_config | Controls whether async event configuration for Lambda Function/Alias should be created | `bool` | `false` | no |
| create\_current\_version\_allowed\_triggers | Whether to allow triggers on current version of Lambda Function (this will revoke permissions from previous version because Terraform manages only current resources) | `bool` | `true` | no |
| create\_current\_version\_async\_event\_config | Whether to allow async event configuration on current version of Lambda Function (this will revoke permissions from previous version because Terraform manages only current resources) | `bool` | `true` | no |
| create\_function | Controls whether Lambda Function resource should be created | `bool` | `true` | no |
| create\_lambda\_function\_url | Controls whether the Lambda Function URL resource should be created | `bool` | `false` | no |
| create\_layer | Controls whether Lambda Layer resource should be created | `bool` | `false` | no |
| create\_package | Controls whether Lambda package should be created | `bool` | `true` | no |
| create\_role | Controls whether IAM role for Lambda Function should be created | `bool` | `true` | no |
| create\_sam\_metadata | Controls whether the SAM metadata null resource should be created | `bool` | `false` | no |
| create\_unqualified\_alias\_allowed\_triggers | Whether to allow triggers on unqualified alias pointing to $LATEST version | `bool` | `true` | no |
| create\_unqualified\_alias\_async\_event\_config | Whether to allow async event configuration on unqualified alias pointing to $LATEST version | `bool` | `true` | no |
| create\_unqualified\_alias\_lambda\_function\_url | Whether to use unqualified alias pointing to $LATEST version in Lambda Function URL | `bool` | `true` | no |
| dead\_letter\_target\_arn | The ARN of an SNS topic or SQS queue to notify when an invocation fails. | `string` | `null` | no |
| description | Description of your Lambda Function (or Layer) | `string` | `null` | no |
| destination\_on\_failure | Amazon Resource Name (ARN) of the destination resource for failed asynchronous invocations | `string` | `null` | no |
| destination\_on\_success | Amazon Resource Name (ARN) of the destination resource for successful asynchronous invocations | `string` | `null` | no |
| docker\_additional\_options | Additional options to pass to the docker run command (e.g. to set environment variables, volumes, etc.) | `list(string)` | `[]` | no |
| docker\_build\_root | Root dir where to build in Docker | `string` | `null` | no |
| docker\_entrypoint | Path to the Docker entrypoint to use | `string` | `null` | no |
| docker\_file | Path to a Dockerfile when building in Docker | `string` | `null` | no |
| docker\_image | Docker image to use for the build | `string` | `null` | no |
| docker\_pip\_cache | Whether to mount a shared pip cache folder into docker environment or not | `any` | `null` | no |
| docker\_with\_ssh\_agent | Whether to pass SSH\_AUTH\_SOCK into docker environment or not | `bool` | `false` | no |
| durable\_config | Configuration block for durable function settings. Requires execution\_timeout; optionally accepts retention\_period. | `any` | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| environment\_variables | A map that defines environment variables for the Lambda Function. Marked sensitive, so plans will hide environment variable diffs. | `map(string)` | `{}` | no |
| ephemeral\_storage\_size | Amount of ephemeral storage (/tmp) in MB your Lambda Function can use at runtime. Valid value between 512 MB to 10,240 MB (10 GB). | `number` | `512` | no |
| event\_source\_mapping | Map of event source mapping configurations. Set `enabled = false` on an entry to skip creating it. | <pre>map(object({<br/>    enabled                            = optional(bool, true)<br/>    event_source_arn                   = optional(string)<br/>    kms_key_arn                        = optional(string)<br/>    batch_size                         = optional(number)<br/>    maximum_batching_window_in_seconds = optional(number)<br/>    starting_position                  = optional(string)<br/>    starting_position_timestamp        = optional(string)<br/>    parallelization_factor             = optional(number)<br/>    maximum_retry_attempts             = optional(number)<br/>    maximum_record_age_in_seconds      = optional(number)<br/>    bisect_batch_on_function_error     = optional(bool)<br/>    topics                             = optional(list(string))<br/>    queues                             = optional(list(string))<br/>    function_response_types            = optional(list(string))<br/>    tumbling_window_in_seconds         = optional(number)<br/>    destination_arn_on_failure         = optional(string)<br/>    scaling_config = optional(object({<br/>      maximum_concurrency = optional(number)<br/>    }))<br/>    self_managed_event_source = optional(list(object({<br/>      endpoints = map(string)<br/>    })), [])<br/>    self_managed_kafka_event_source_config = optional(list(object({<br/>      consumer_group_id = optional(string)<br/>      schema_registry_config = optional(object({<br/>        event_record_format = optional(string)<br/>        schema_registry_uri = optional(string)<br/>        access_config = optional(list(object({<br/>          type = string<br/>          uri  = string<br/>        })), [])<br/>        schema_validation_config = optional(object({<br/>          attribute = string<br/>        }))<br/>      }))<br/>    })), [])<br/>    amazon_managed_kafka_event_source_config = optional(list(object({<br/>      consumer_group_id = optional(string)<br/>      schema_registry_config = optional(object({<br/>        event_record_format = optional(string)<br/>        schema_registry_uri = optional(string)<br/>        access_config = optional(list(object({<br/>          type = string<br/>          uri  = string<br/>        })), [])<br/>        schema_validation_config = optional(object({<br/>          attribute = string<br/>        }))<br/>      }))<br/>    })), [])<br/>    source_access_configuration = optional(list(object({<br/>      type = string<br/>      uri  = string<br/>    })), [])<br/>    filter_criteria = optional(list(object({<br/>      pattern = optional(string)<br/>    })))<br/>    document_db_event_source_config = optional(list(object({<br/>      database_name   = string<br/>      collection_name = optional(string)<br/>      full_document   = optional(string)<br/>    })), [])<br/>    metrics_config = optional(object({<br/>      metrics = list(string)<br/>    }))<br/>    provisioned_poller_config = optional(object({<br/>      maximum_pollers   = optional(number)<br/>      minimum_pollers   = optional(number)<br/>      poller_group_name = optional(string)<br/>    }))<br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| file\_system\_arn | The Amazon Resource Name (ARN) of the Amazon EFS Access Point that provides access to the file system. | `string` | `null` | no |
| file\_system\_local\_mount\_path | The path where the function can access the file system, starting with /mnt/. | `string` | `null` | no |
| function\_tags | A map of tags to assign only to the lambda function | `map(string)` | `{}` | no |
| handler | Lambda Function entrypoint in your code | `string` | `null` | no |
| hash\_extra | The string to add into hashing function. Useful when building same source path for different functions. | `string` | `""` | no |
| ignore\_source\_code\_hash | Whether to ignore changes to the function's source code hash. Set to true if you manage infrastructure and code deployments separately. | `bool` | `false` | no |
| image\_config\_command | The CMD for the docker image | `list(string)` | `[]` | no |
| image\_config\_entry\_point | The ENTRYPOINT for the docker image | `list(string)` | `[]` | no |
| image\_config\_working\_directory | The working directory for the docker image | `string` | `null` | no |
| image\_uri | The ECR image URI containing the function's deployment package. | `string` | `null` | no |
| invoke\_mode | Invoke mode of the Lambda Function URL. Valid values are BUFFERED (default) and RESPONSE\_STREAM. | `string` | `null` | no |
| ipv6\_allowed\_for\_dual\_stack | Allows outbound IPv6 traffic on VPC functions that are connected to dual-stack subnets | `bool` | `null` | no |
| kms\_key\_arn | The ARN of KMS key to use by your Lambda Function | `string` | `null` | no |
| lambda\_at\_edge | Set this to true if using Lambda@Edge, to enable publishing, limit the timeout, and allow edgelambda.amazonaws.com to invoke the function | `bool` | `false` | no |
| lambda\_at\_edge\_logs\_all\_regions | Whether to specify a wildcard in IAM policy used by Lambda@Edge to allow logging in all regions | `bool` | `true` | no |
| lambda\_role | IAM role ARN attached to the Lambda Function. This governs both who / what can invoke your Lambda Function, as well as what resources our Lambda Function has access to. See Lambda Permission Model for more details. | `string` | `null` | no |
| layer\_name | Name of Lambda Layer to create | `string` | `null` | no |
| layer\_skip\_destroy | Whether to retain the old version of a previously deployed Lambda Layer. | `bool` | `false` | no |
| layers | List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function. | `list(string)` | `null` | no |
| license\_info | License info for your Lambda Layer. Eg, MIT or full url of a license. | `string` | `null` | no |
| local\_existing\_package | The absolute path to an existing zip-file to use | `string` | `null` | no |
| logging\_application\_log\_level | The application log level of the Lambda Function. Valid values are "TRACE", "DEBUG", "INFO", "WARN", "ERROR", or "FATAL". | `string` | `"INFO"` | no |
| logging\_log\_format | The log format of the Lambda Function. Valid values are "JSON" or "Text". | `string` | `"Text"` | no |
| logging\_log\_group | The CloudWatch log group to send logs to. | `string` | `null` | no |
| logging\_system\_log\_level | The system log level of the Lambda Function. Valid values are "DEBUG", "INFO", or "WARN". | `string` | `"INFO"` | no |
| maximum\_event\_age\_in\_seconds | Maximum age of a request that Lambda sends to a function for processing in seconds. Valid values between 60 and 21600. | `number` | `null` | no |
| maximum\_retry\_attempts | Maximum number of times to retry when the function returns an error. Valid values between 0 and 2. Defaults to 2. | `number` | `null` | no |
| memory\_size | Amount of memory in MB your Lambda Function can use at runtime. Valid value between 128 MB to 10,240 MB (10 GB), in 64 MB increments. | `number` | `128` | no |
| name | A unique name for your Lambda Function | `string` | `null` | no |
| number\_of\_policies | Number of policies to attach to IAM role for Lambda Function | `number` | `0` | no |
| number\_of\_policy\_jsons | Number of policies JSON to attach to IAM role for Lambda Function | `number` | `0` | no |
| package\_type | The Lambda deployment package type. Valid options: Zip or Image | `string` | `"Zip"` | no |
| policies | List of policy statements ARN to attach to Lambda Function role | `list(string)` | `[]` | no |
| policy | An additional policy document ARN to attach to the Lambda Function role | `string` | `null` | no |
| policy\_json | An additional policy document as JSON to attach to the Lambda Function role | `string` | `null` | no |
| policy\_jsons | List of additional policy documents as JSON to attach to Lambda Function role | `list(string)` | `[]` | no |
| policy\_name | IAM policy name. It override the default value, which is the same as role\_name | `string` | `null` | no |
| policy\_path | Path of policies to that should be added to IAM role for Lambda Function | `string` | `null` | no |
| policy\_statements | Map of dynamic policy statements to attach to Lambda Function role | <pre>map(object({<br/>    sid           = optional(string)<br/>    effect        = optional(string)<br/>    actions       = optional(list(string))<br/>    not_actions   = optional(list(string))<br/>    resources     = optional(list(string))<br/>    not_resources = optional(list(string))<br/>    principals = optional(list(object({<br/>      type        = string<br/>      identifiers = list(string)<br/>    })), [])<br/>    not_principals = optional(list(object({<br/>      type        = string<br/>      identifiers = list(string)<br/>    })), [])<br/>    condition = optional(list(object({<br/>      test     = string<br/>      variable = string<br/>      values   = list(string)<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| provisioned\_concurrency\_skip\_destroy | Whether to retain the provisioned concurrency configuration upon destruction. Defaults to false. Useful when you want to destroy the function but keep the concurrency config (e.g. to avoid cold starts on re-creation). | `bool` | `false` | no |
| provisioned\_concurrent\_executions | Amount of capacity to allocate. Set to 1 or greater to enable, or set to 0 to disable provisioned concurrency. | `number` | `-1` | no |
| publish | Whether to publish creation/change as new Lambda Function Version. | `bool` | `false` | no |
| publish\_to | Whether to publish to an alias or version number. Omit for regular version publishing. Option is LATEST\_PUBLISHED. | `string` | `null` | no |
| recreate\_missing\_package | Whether to recreate missing Lambda package if it is missing locally or not | `bool` | `true` | no |
| recursive\_loop | Lambda function recursion configuration. Valid values are Allow or Terminate. | `string` | `null` | no |
| replace\_security\_groups\_on\_destroy | (Optional) When true, all security groups defined in vpc\_security\_group\_ids will be replaced with the default security group after the function is destroyed. Set the replacement\_security\_group\_ids variable to use a custom list of security groups for replacement instead. | `bool` | `null` | no |
| replacement\_security\_group\_ids | (Optional) List of security group IDs to assign to orphaned Lambda function network interfaces upon destruction. replace\_security\_groups\_on\_destroy must be set to true to use this attribute. | `list(string)` | `null` | no |
| reserved\_concurrent\_executions | The amount of reserved concurrent executions for this Lambda Function. A value of 0 disables Lambda Function from being triggered and -1 removes any concurrency limitations. Defaults to Unreserved Concurrency Limits -1. | `number` | `-1` | no |
| role\_description | Description of IAM role to use for Lambda Function | `string` | `null` | no |
| role\_force\_detach\_policies | Specifies to force detaching any policies the IAM role has before destroying it. | `bool` | `true` | no |
| role\_maximum\_session\_duration | Maximum session duration, in seconds, for the IAM role | `number` | `3600` | no |
| role\_name | Name of IAM role to use for Lambda Function | `string` | `null` | no |
| role\_path | Path of IAM role to use for Lambda Function | `string` | `null` | no |
| role\_permissions\_boundary | The ARN of the policy that is used to set the permissions boundary for the IAM role used by Lambda Function | `string` | `null` | no |
| role\_tags | A map of tags to assign to IAM role | `map(string)` | `{}` | no |
| runtime | Lambda Function runtime | `string` | `null` | no |
| s3\_acl | The canned ACL to apply. Valid values are private, public-read, public-read-write, aws-exec-read, authenticated-read, bucket-owner-read, and bucket-owner-full-control. Defaults to private. | `string` | `"private"` | no |
| s3\_bucket | S3 bucket to store artifacts | `string` | `null` | no |
| s3\_existing\_package | The S3 bucket object with keys bucket, key, version pointing to an existing zip-file to use | `map(string)` | `null` | no |
| s3\_kms\_key\_id | Specifies a custom KMS key to use for S3 object encryption. | `string` | `null` | no |
| s3\_object\_override\_default\_tags | Whether to override the default\_tags from provider? NB: S3 objects support a maximum of 10 tags. | `bool` | `false` | no |
| s3\_object\_storage\_class | Specifies the desired Storage Class for the artifact uploaded to S3. Can be either STANDARD, REDUCED\_REDUNDANCY, ONEZONE\_IA, INTELLIGENT\_TIERING, or STANDARD\_IA. | `string` | `"ONEZONE_IA"` | no |
| s3\_object\_tags | A map of tags to assign to S3 bucket object. | `map(string)` | `{}` | no |
| s3\_object\_tags\_only | Set to true to not merge tags with s3\_object\_tags. Useful to avoid breaching S3 Object 10 tag limit. | `bool` | `false` | no |
| s3\_prefix | Directory name where artifacts should be stored in the S3 bucket. If unset, the path from `artifacts_dir` is used | `string` | `null` | no |
| s3\_server\_side\_encryption | Specifies server-side encryption of the object in S3. Valid values are "AES256" and "aws:kms". | `string` | `"AES256"` | no |
| skip\_destroy | Set to true if you do not wish the function to be deleted at destroy time, and instead just remove the function from the Terraform state. Useful for Lambda@Edge functions attached to CloudFront distributions. | `bool` | `null` | no |
| snap\_start | (Optional) Snap start settings for low-latency startups | `bool` | `false` | no |
| source\_kms\_key\_arn | ARN of the KMS key used to encrypt the function's deployment package | `string` | `null` | no |
| source\_path | The absolute path to a local file or directory containing your Lambda source code | `any` | `null` | no |
| store\_on\_s3 | Whether to store produced artifacts on S3 or locally. | `bool` | `false` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| tenancy\_config | Configuration for Lambda function tenancy. Supports mode attribute | `any` | `null` | no |
| timeout | The amount of time your Lambda Function has to run in seconds. | `number` | `3` | no |
| timeouts | Define maximum timeout for creating, updating, and deleting Lambda Function resources | `map(string)` | `{}` | no |
| tracing\_mode | Tracing mode of the Lambda Function. Valid value can be either PassThrough or Active. | `string` | `null` | no |
| trigger\_on\_package\_timestamp | Whether to recreate the Lambda package if the timestamp changes | `bool` | `true` | no |
| trusted\_entities | List of additional trusted entities for assuming Lambda Function role (trust relationship). Each entry is an object with `type` (e.g. `Service`, `AWS`) and `identifiers`. Plain service-name strings are no longer accepted; express them as `{ type = "Service", identifiers = [...] }`. | <pre>list(object({<br/>    type        = string<br/>    identifiers = list(string)<br/>  }))</pre> | `[]` | no |
| use\_existing\_cloudwatch\_log\_group | Whether to use an existing CloudWatch log group or create new | `bool` | `false` | no |
| vpc\_security\_group\_ids | List of security group ids when Lambda Function should run in the VPC. | `list(string)` | `null` | no |
| vpc\_subnet\_ids | List of subnet ids when Lambda Function should run in the VPC. Usually private or intra subnets. | `list(string)` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| lambda\_cloudwatch\_log\_group\_arn | The ARN of the Cloudwatch Log Group |
| lambda\_cloudwatch\_log\_group\_name | The name of the Cloudwatch Log Group |
| lambda\_event\_source\_mapping\_arn | The event source mapping ARN |
| lambda\_event\_source\_mapping\_function\_arn | The the ARN of the Lambda function the event source mapping is sending events to |
| lambda\_event\_source\_mapping\_state | The state of the event source mapping |
| lambda\_event\_source\_mapping\_state\_transition\_reason | The reason the event source mapping is in its current state |
| lambda\_event\_source\_mapping\_uuid | The UUID of the created event source mapping |
| lambda\_function\_arn | The ARN of the Lambda Function |
| lambda\_function\_arn\_static | The static ARN of the Lambda Function. Use this to avoid cycle errors between resources (e.g., Step Functions) |
| lambda\_function\_invoke\_arn | The Invoke ARN of the Lambda Function |
| lambda\_function\_kms\_key\_arn | The ARN for the KMS encryption key of Lambda Function |
| lambda\_function\_last\_modified | The date Lambda Function resource was last modified |
| lambda\_function\_name | The name of the Lambda Function |
| lambda\_function\_qualified\_arn | The ARN identifying your Lambda Function Version |
| lambda\_function\_qualified\_invoke\_arn | The Invoke ARN identifying your Lambda Function Version |
| lambda\_function\_signing\_job\_arn | ARN of the signing job |
| lambda\_function\_signing\_profile\_version\_arn | ARN of the signing profile version |
| lambda\_function\_source\_code\_hash | Base64-encoded representation of raw SHA-256 sum of the zip file |
| lambda\_function\_source\_code\_size | The size in bytes of the function .zip file |
| lambda\_function\_url | The URL of the Lambda Function URL |
| lambda\_function\_url\_id | The Lambda Function URL generated id |
| lambda\_function\_version | Latest published version of Lambda Function |
| lambda\_layer\_arn | The ARN of the Lambda Layer with version |
| lambda\_layer\_created\_date | The date Lambda Layer resource was created |
| lambda\_layer\_layer\_arn | The ARN of the Lambda Layer without version |
| lambda\_layer\_source\_code\_size | The size in bytes of the Lambda Layer .zip file |
| lambda\_layer\_version | The Lambda Layer version |
| lambda\_role\_arn | The ARN of the IAM role created for the Lambda Function |
| lambda\_role\_name | The name of the IAM role created for the Lambda Function |
| lambda\_role\_unique\_id | The unique id of the IAM role created for the Lambda Function |
| local\_filename | The filename of zip archive deployed (if deployment was from local) |
| s3\_object | The map with S3 object data of zip archive deployed (if deployment was from S3) |
<!-- END_TF_DOCS -->

</details>
