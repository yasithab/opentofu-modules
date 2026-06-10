# EventBridge

Comprehensive Amazon EventBridge module that provisions event buses, rules, targets, schedules, pipes, and supporting resources in a single, composable configuration.

## Features

- **Custom Event Bus** - Create and manage custom event buses with optional KMS encryption and schema discovery
- **Rules and Targets** - Define event pattern or schedule-based rules with one or more targets per rule
- **Schedules and Schedule Groups** - Provision EventBridge Scheduler schedules with flexible grouping
- **Pipes** - Configure EventBridge Pipes for point-to-point integrations between sources and targets
- **Connections and API Destinations** - Set up authenticated HTTP endpoints as event targets
- **Archives** - Automatically archive events for replay
- **Log Delivery** - Route bus activity logs to CloudWatch Logs, S3, or Firehose
- **IAM Role Management** - Automatically create and attach least-privilege IAM roles with built-in policies for Lambda, SQS, SNS, ECS, Kinesis, Step Functions, CloudWatch, and API Destinations
- **Custom Policies** - Attach inline JSON policies, managed policy ARNs, or dynamic policy statements to the EventBridge IAM role

## Notes

- **BREAKING:** when `attach_ecs_policy = true`, `ecs_pass_role_resources` is now required. The `iam:PassRole` statement is scoped to the role ARNs you provide and no longer falls back to `"*"`.
- `name` must not be `"default"` when `create_bus = true` - the default event bus already exists. Set `create_bus = false` to reference the default bus.
- `permissions` map keys must be in the format `"<principal> <statement_id>"` (e.g. `"123456789012 AllowAccountX"`).
- **BREAKING:** rule `role_arn` accepts only an IAM role ARN (string) or null. The previous boolean form (`role_arn = true` to use the module-created role) has been removed; reference the role ARN explicitly (e.g. via the module's `eventbridge_role_arn` output from a separate instance, or an externally managed role).
- `connections` values (auth parameters) are sensitive; only the map keys are unwrapped with `nonsensitive()` to drive resource creation, so secrets stay hidden in plans but the set of connections must be known at plan time.

## Usage

```hcl
module "eventbridge" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eventbridge?depth=1&ref=master"

  name     = "my-app-bus"

  rules = {
    cron_schedule = {
      description         = "Trigger every 5 minutes"
      schedule_expression = "rate(5 minutes)"
    }
  }

  targets = {
    cron_schedule = [
      {
        name = "send-to-lambda"
        arn  = "arn:aws:lambda:us-east-1:123456789012:function:my-function"
      }
    ]
  }

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
| api\_destinations | A map of objects with EventBridge Destination definitions. | `map(any)` | `{}` | no |
| append\_connection\_postfix | Controls whether to append '-connection' to the name of the connection | `bool` | `true` | no |
| append\_destination\_postfix | Controls whether to append '-destination' to the name of the destination | `bool` | `true` | no |
| append\_pipe\_postfix | Controls whether to append '-pipe' to the name of the pipe | `bool` | `true` | no |
| append\_rule\_postfix | Controls whether to append '-rule' to the name of the rule | `bool` | `true` | no |
| append\_schedule\_group\_postfix | Controls whether to append '-group' to the name of the schedule group | `bool` | `true` | no |
| append\_schedule\_postfix | Controls whether to append '-schedule' to the name of the schedule | `bool` | `true` | no |
| archives | A map of objects with the EventBridge Archive definitions. | `map(any)` | `{}` | no |
| attach\_api\_destination\_policy | Controls whether the API Destination policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| attach\_cloudwatch\_policy | Controls whether the Cloudwatch policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| attach\_ecs\_policy | Controls whether the ECS policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| attach\_kinesis\_firehose\_policy | Controls whether the Kinesis Firehose policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| attach\_kinesis\_policy | Controls whether the Kinesis policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| attach\_lambda\_policy | Controls whether the Lambda Function policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| attach\_policies | Controls whether list of policies should be added to IAM role | `bool` | `false` | no |
| attach\_policy | Controls whether policy should be added to IAM role | `bool` | `false` | no |
| attach\_policy\_json | Controls whether policy\_json should be added to IAM role | `bool` | `false` | no |
| attach\_policy\_jsons | Controls whether policy\_jsons should be added to IAM role | `bool` | `false` | no |
| attach\_policy\_statements | Controls whether policy\_statements should be added to IAM role | `bool` | `false` | no |
| attach\_sfn\_policy | Controls whether the StepFunction policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| attach\_sns\_policy | Controls whether the SNS policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| attach\_sqs\_policy | Controls whether the SQS policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| attach\_tracing\_policy | Controls whether X-Ray tracing policy should be added to IAM role for EventBridge | `bool` | `false` | no |
| bus\_description | Event bus description | `string` | `null` | no |
| cloudwatch\_target\_arns | The Amazon Resource Name (ARN) of the Cloudwatch Log Streams you want to use as EventBridge targets | `list(string)` | `[]` | no |
| connections | A map of objects with EventBridge Connection definitions. Note: auth\_parameters passwords will be stored in state as the provider does not support write\_only for this field | `any` | `{}` | no |
| create\_api\_destinations | Controls whether EventBridge Destination resources should be created | `bool` | `false` | no |
| create\_archives | Controls whether EventBridge Archive resources should be created | `bool` | `false` | no |
| create\_bus | Controls whether EventBridge Bus resource should be created | `bool` | `true` | no |
| create\_connections | Controls whether EventBridge Connection resources should be created | `bool` | `false` | no |
| create\_log\_delivery | Controls whether EventBridge log delivery resources should be created | `bool` | `true` | no |
| create\_log\_delivery\_source | Controls whether EventBridge log delivery source resource should be created | `bool` | `true` | no |
| create\_permissions | Controls whether EventBridge Permission resources should be created | `bool` | `true` | no |
| create\_pipe\_role\_only | Controls whether an IAM role should be created for the pipes only | `bool` | `false` | no |
| create\_pipes | Controls whether EventBridge Pipes resources should be created | `bool` | `true` | no |
| create\_role | Controls whether IAM roles should be created | `bool` | `true` | no |
| create\_rules | Controls whether EventBridge Rule resources should be created | `bool` | `true` | no |
| create\_schedule\_groups | Controls whether EventBridge Schedule Group resources should be created | `bool` | `true` | no |
| create\_schedules | Controls whether EventBridge Schedule resources should be created | `bool` | `true` | no |
| create\_schemas\_discoverer | Controls whether default schemas discoverer should be created | `bool` | `false` | no |
| create\_targets | Controls whether EventBridge Target resources should be created | `bool` | `true` | no |
| dead\_letter\_config | Configuration details of the Amazon SQS queue for EventBridge to use as a dead-letter queue (DLQ) | `any` | `{}` | no |
| ecs\_pass\_role\_resources | List of IAM role ARNs (task role / task execution role) that EventBridge is allowed to pass to ECS. Required when `attach_ecs_policy = true` - there is no wildcard fallback | `list(string)` | `[]` | no |
| ecs\_target\_arns | The Amazon Resource Name (ARN) of the AWS ECS Tasks you want to use as EventBridge targets | `list(string)` | `[]` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| event\_source\_name | The partner event source that the new event bus will be matched with. Must match name. | `string` | `null` | no |
| kinesis\_firehose\_target\_arns | The Amazon Resource Name (ARN) of the Kinesis Firehose Delivery Streams you want to use as EventBridge targets | `list(string)` | `[]` | no |
| kinesis\_target\_arns | The Amazon Resource Name (ARN) of the Kinesis Streams you want to use as EventBridge targets | `list(string)` | `[]` | no |
| kms\_key\_identifier | The identifier of the AWS KMS customer managed key for EventBridge to use, if you choose to use a customer managed key to encrypt events on this event bus. The identifier can be the key Amazon Resource Name (ARN), KeyId, key alias, or key alias ARN. | `string` | `null` | no |
| lambda\_target\_arns | The Amazon Resource Name (ARN) of the Lambda Functions you want to use as EventBridge targets | `list(string)` | `[]` | no |
| log\_config | The configuration block for the EventBridge bus log config settings | <pre>object({<br/>    include_detail = string<br/>    level          = string<br/>  })</pre> | `null` | no |
| log\_delivery | Map of the configuration block for the EventBridge bus log delivery settings (key is the type of log delivery: cloudwatch\_logs, s3, firehose) | <pre>map(object({<br/>    enabled                   = optional(bool, true)<br/>    destination_arn           = string<br/>    delivery_destination_type = optional(string)<br/>    source_name               = optional(string)<br/>    name                      = optional(string)<br/>    output_format             = optional(string)<br/>    field_delimiter           = optional(string)<br/>    record_fields             = optional(list(string))<br/>    s3_delivery_configuration = optional(object({<br/>      enable_hive_compatible_path = optional(bool)<br/>      suffix_path                 = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| log\_delivery\_source\_name | Name of log delivery source | `string` | `null` | no |
| name | A unique name for your EventBridge Bus | `string` | `"default"` | no |
| number\_of\_policies | Number of policies to attach to IAM role | `number` | `0` | no |
| number\_of\_policy\_jsons | Number of policies JSON to attach to IAM role | `number` | `0` | no |
| permissions | A map of objects with EventBridge Permission definitions. Map keys must be in the format "<principal> <statement\_id>" (e.g. "123456789012 AllowAccountX"). | `map(any)` | `{}` | no |
| pipes | A map of objects with EventBridge Pipe definitions. | `any` | `{}` | no |
| policies | List of policy statements ARN to attach to IAM role | `list(string)` | `[]` | no |
| policy | An additional policy document ARN to attach to IAM role | `string` | `null` | no |
| policy\_json | An additional policy document as JSON to attach to IAM role | `string` | `null` | no |
| policy\_jsons | List of additional policy documents as JSON to attach to IAM role | `list(string)` | `[]` | no |
| policy\_path | Path of IAM policy to use for EventBridge | `string` | `null` | no |
| policy\_statements | Map of dynamic policy statements to attach to IAM role | `any` | `{}` | no |
| region | Region where the resource(s) will be managed. Defaults to the region set in the provider configuration | `string` | `null` | no |
| role\_description | Description of IAM role to use for EventBridge | `string` | `null` | no |
| role\_force\_detach\_policies | Specifies to force detaching any policies the IAM role has before destroying it. | `bool` | `true` | no |
| role\_name | Name of IAM role to use for EventBridge | `string` | `null` | no |
| role\_path | Path of IAM role to use for EventBridge | `string` | `null` | no |
| role\_permissions\_boundary | The ARN of the policy that is used to set the permissions boundary for the IAM role used by EventBridge | `string` | `null` | no |
| role\_tags | A map of tags to assign to IAM role | `map(string)` | `{}` | no |
| rules | A map of objects with EventBridge Rule definitions. `role_arn` accepts only an IAM role ARN (string) or null; the previous boolean form (`role_arn = true`) is no longer supported. | `map(any)` | `{}` | no |
| schedule\_group\_timeouts | A map of objects with EventBridge Schedule Group create and delete timeouts. | `map(string)` | `{}` | no |
| schedule\_groups | A map of objects with EventBridge Schedule Group definitions. | `any` | `{}` | no |
| schedules | A map of objects with EventBridge Schedule definitions. | `map(any)` | `{}` | no |
| schemas\_discoverer\_description | Default schemas discoverer description | `string` | `"Auto schemas discoverer event"` | no |
| sfn\_target\_arns | The Amazon Resource Name (ARN) of the StepFunctions you want to use as EventBridge targets | `list(string)` | `[]` | no |
| sns\_kms\_arns | The Amazon Resource Name (ARN) of the AWS KMS's configured for AWS SNS you want Decrypt/GenerateDataKey for | `list(string)` | <pre>[<br/>  "*"<br/>]</pre> | no |
| sns\_target\_arns | The Amazon Resource Name (ARN) of the AWS SNS's you want to use as EventBridge targets | `list(string)` | `[]` | no |
| sqs\_target\_arns | The Amazon Resource Name (ARN) of the AWS SQS Queues you want to use as EventBridge targets | `list(string)` | `[]` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| targets | A map of objects with EventBridge Target definitions. | `any` | `{}` | no |
| trusted\_entities | Additional trusted entities for assuming roles (trust relationship) | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| eventbridge\_api\_destination\_arns | The EventBridge API Destination ARNs |
| eventbridge\_api\_destinations | The EventBridge API Destinations created and their attributes |
| eventbridge\_archive\_arns | The EventBridge Archive ARNs |
| eventbridge\_archives | The EventBridge Archives created and their attributes |
| eventbridge\_bus | The EventBridge Bus created and their attributes |
| eventbridge\_bus\_arn | The EventBridge Bus ARN |
| eventbridge\_bus\_name | The EventBridge Bus Name |
| eventbridge\_connection\_arns | The EventBridge Connection Arns |
| eventbridge\_connection\_ids | The EventBridge Connection IDs |
| eventbridge\_connections | The EventBridge Connections created and their attributes |
| eventbridge\_iam\_roles | The EventBridge IAM roles created and their attributes |
| eventbridge\_log\_delivery\_source\_arn | The EventBridge Bus CloudWatch Log Delivery Source ARN |
| eventbridge\_log\_delivery\_source\_name | The EventBridge Bus CloudWatch Log Delivery Source Name |
| eventbridge\_permission\_ids | The EventBridge Permission IDs |
| eventbridge\_permissions | The EventBridge Permissions created and their attributes |
| eventbridge\_pipe\_arns | The EventBridge Pipes ARNs |
| eventbridge\_pipe\_ids | The EventBridge Pipes IDs |
| eventbridge\_pipe\_role\_arns | The ARNs of the IAM role created for EventBridge Pipes |
| eventbridge\_pipe\_role\_names | The names of the IAM role created for EventBridge Pipes |
| eventbridge\_pipes | The EventBridge Pipes created and their attributes |
| eventbridge\_pipes\_iam\_roles | The EventBridge Pipes IAM roles created and their attributes |
| eventbridge\_role\_arn | The ARN of the IAM role created for EventBridge |
| eventbridge\_role\_name | The name of the IAM role created for EventBridge |
| eventbridge\_rule\_arns | The EventBridge Rule ARNs |
| eventbridge\_rule\_ids | The EventBridge Rule IDs |
| eventbridge\_rules | The EventBridge Rules created and their attributes |
| eventbridge\_schedule\_arns | The EventBridge Schedule ARNs created |
| eventbridge\_schedule\_group\_arns | The EventBridge Schedule Group ARNs |
| eventbridge\_schedule\_group\_ids | The EventBridge Schedule Group IDs |
| eventbridge\_schedule\_group\_states | The EventBridge Schedule Group states |
| eventbridge\_schedule\_groups | The EventBridge Schedule Groups created and their attributes |
| eventbridge\_schedule\_ids | The EventBridge Schedule IDs created |
| eventbridge\_schedules | The EventBridge Schedules created and their attributes |
| eventbridge\_targets | The EventBridge Targets created and their attributes |
<!-- END_TF_DOCS -->

## Examples

## Basic Usage

Custom EventBridge bus with a cron schedule that triggers a Lambda function.

```hcl
module "eventbridge" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eventbridge?depth=1&ref=master"

  enabled  = true
  name     = "app-events"

  create_rules   = true
  create_targets = true

  rules = {
    nightly_cleanup = {
      description         = "Trigger nightly cleanup Lambda"
      schedule_expression = "cron(0 2 * * ? *)"
      state               = "ENABLED"
    }
  }

  targets = {
    nightly_cleanup = [
      {
        name = "nightly-cleanup-lambda"
        arn  = "arn:aws:lambda:ap-southeast-1:123456789012:function:nightly-cleanup"
      }
    ]
  }

  attach_lambda_policy = true
  lambda_target_arns   = ["arn:aws:lambda:ap-southeast-1:123456789012:function:nightly-cleanup"]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## With Event Pattern Rules and SQS Target

Event-driven bus with pattern-matching rules forwarding order events to an SQS queue.

```hcl
module "eventbridge" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eventbridge?depth=1&ref=master"

  enabled  = true
  name     = "order-events"

  create_rules   = true
  create_targets = true

  rules = {
    order_placed = {
      description  = "Route order-placed events to fulfillment queue"
      event_pattern = jsonencode({
        source      = ["com.myapp.orders"]
        detail-type = ["OrderPlaced"]
      })
      state = "ENABLED"
    }
    order_cancelled = {
      description  = "Route order-cancelled events to refund queue"
      event_pattern = jsonencode({
        source      = ["com.myapp.orders"]
        detail-type = ["OrderCancelled"]
      })
      state = "ENABLED"
    }
  }

  targets = {
    order_placed = [
      {
        name = "fulfillment-queue"
        arn  = "arn:aws:sqs:ap-southeast-1:123456789012:fulfillment-queue"
      }
    ]
    order_cancelled = [
      {
        name = "refund-queue"
        arn  = "arn:aws:sqs:ap-southeast-1:123456789012:refund-queue"
      }
    ]
  }

  attach_sqs_policy = true
  sqs_target_arns = [
    "arn:aws:sqs:ap-southeast-1:123456789012:fulfillment-queue",
    "arn:aws:sqs:ap-southeast-1:123456789012:refund-queue"
  ]

  tags = {
    Environment = "production"
    Domain      = "orders"
  }
}
```

## With Scheduler and ECS Task Target

EventBridge Scheduler groups and schedules to run an ECS task on a fixed rate.

```hcl
module "eventbridge" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eventbridge?depth=1&ref=master"

  enabled  = true
  name     = "default"

  create_bus             = false
  create_rules           = false
  create_targets         = false
  create_schedule_groups = true
  create_schedules       = true

  schedule_groups = {
    batch_jobs = {
      name = "batch-jobs"
    }
  }

  schedules = {
    report_generator = {
      name                         = "report-generator"
      group_name                   = "batch-jobs"
      description                  = "Generate daily sales report"
      schedule_expression          = "cron(0 6 * * ? *)"
      schedule_expression_timezone = "Asia/Dubai"
      flexible_time_window         = { mode = "OFF" }
      target = {
        arn      = "arn:aws:ecs:ap-southeast-1:123456789012:cluster/prod-cluster"
        role_arn = "arn:aws:iam::123456789012:role/EventBridgeSchedulerRole"
        ecs_parameters = {
          task_definition_arn = "arn:aws:ecs:ap-southeast-1:123456789012:task-definition/report-generator:5"
          task_count          = 1
          launch_type         = "FARGATE"
          network_configuration = {
            assign_public_ip = "DISABLED"
            subnets          = ["subnet-0aaa111", "subnet-0bbb222"]
            security_groups  = ["sg-0abc123def456789"]
          }
        }
      }
    }
  }

  attach_ecs_policy = true
  ecs_target_arns   = ["arn:aws:ecs:ap-southeast-1:123456789012:cluster/prod-cluster"]

  ecs_pass_role_resources = [
    "arn:aws:iam::123456789012:role/ECSTaskRole"
  ]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Advanced - Event Bus with Archive, Cross-Account Permissions, and Dead-Letter Queue

Full-featured event bus with event archiving, cross-account ingestion permissions, X-Ray tracing, and a DLQ.

```hcl
module "eventbridge" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eventbridge?depth=1&ref=master"

  enabled      = true
  name         = "platform-events"
  bus_description = "Central event bus for platform-wide events"

  create_rules        = true
  create_targets      = true
  create_archives     = true
  create_permissions  = true

  kms_key_identifier = "arn:aws:kms:ap-southeast-1:123456789012:key/mrk-abc123"

  dead_letter_config = {
    arn = "arn:aws:sqs:ap-southeast-1:123456789012:platform-events-dlq"
  }

  archives = {
    all_events = {
      description    = "Archive all platform events for 90 days"
      retention_days = 90
    }
  }

  permissions = {
    # Key format: "<principal> <statement_id>"
    "123456789013 AllowAccountBPutEvents" = {
      action = "events:PutEvents"
    }
  }

  rules = {
    infra_alerts = {
      description   = "Route infrastructure alert events to SNS"
      event_pattern = jsonencode({
        source      = ["aws.ec2", "aws.rds"]
        detail-type = ["EC2 Instance State-change Notification", "RDS DB Instance Event"]
      })
      state = "ENABLED"
    }
  }

  targets = {
    infra_alerts = [
      {
        name = "ops-sns-topic"
        arn  = "arn:aws:sns:ap-southeast-1:123456789012:ops-alerts"
      }
    ]
  }

  attach_sns_policy   = true
  attach_tracing_policy = true
  sns_target_arns     = ["arn:aws:sns:ap-southeast-1:123456789012:ops-alerts"]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    Domain      = "platform"
  }
}
```
