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

## Usage

```hcl
module "eventbridge" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eventbridge?depth=1&ref=master"

  bus_name = "my-app-bus"

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


## Examples

## Basic Usage

Custom EventBridge bus with a cron schedule that triggers a Lambda function.

```hcl
module "eventbridge" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eventbridge?depth=1&ref=master"

  enabled  = true
  bus_name = "app-events"

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
  bus_name = "order-events"

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
  bus_name = "default"

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
  bus_name     = "platform-events"
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
    allow_account_b = {
      action    = "events:PutEvents"
      principal = "123456789013"
      statement_id = "AllowAccountBPutEvents"
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
