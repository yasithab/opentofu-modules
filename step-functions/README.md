# AWS Step Functions

OpenTofu module for creating and managing AWS Step Functions state machines with IAM roles, CloudWatch logging, X-Ray tracing, alarms, and EventBridge triggers.

## Features

- **Standard and Express Workflows** - Support for both STANDARD and EXPRESS state machine types
- **IAM Role Management** - Automatic IAM role creation with configurable trust policy, managed policies, and inline policies
- **CloudWatch Logging** - Configurable log group with retention, KMS encryption, and execution data inclusion
- **X-Ray Tracing** - Optional X-Ray tracing integration with automatic IAM permissions
- **Version Publishing** - Support for publishing state machine versions
- **Aliases** - Named aliases with weighted routing across published versions for gradual (canary) rollouts
- **CloudWatch Alarms** - Pre-configured alarms for execution failures, throttling, and timeouts
- **EventBridge Integration** - Create EventBridge rules to trigger state machine executions on schedule or event patterns, with optional per-rule `dead_letter_arn` (SQS DLQ) and `retry_policy` (`maximum_event_age_in_seconds`, `maximum_retry_attempts`) on the targets
- **Security by Default** - Logging enabled by default, least-privilege IAM policies (log writes are scoped to the state machine's log group)

> **Note:** when `event_rules` is set, either `create_event_role = true` or `event_role_arn` must be provided so EventBridge can start executions.

## Usage

```hcl
module "step_functions" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//step-functions?depth=1&ref=master"

  name = "my-workflow"

  definition = jsonencode({
    StartAt = "HelloWorld"
    States = {
      HelloWorld = {
        Type   = "Pass"
        Result = "Hello, World!"
        End    = true
      }
    }
  })

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
| alarm\_actions | List of ARNs to notify when the alarm transitions to ALARM state | `list(string)` | `[]` | no |
| alarm\_execution\_failed\_evaluation\_periods | Number of evaluation periods for the ExecutionsFailed alarm | `number` | `1` | no |
| alarm\_execution\_failed\_period | Period in seconds for the ExecutionsFailed alarm | `number` | `300` | no |
| alarm\_execution\_failed\_threshold | Threshold for the ExecutionsFailed alarm | `number` | `1` | no |
| alarm\_execution\_throttled\_threshold | Threshold for the ExecutionsThrottled alarm | `number` | `1` | no |
| alarm\_execution\_timed\_out\_threshold | Threshold for the ExecutionsTimedOut alarm | `number` | `1` | no |
| aliases | Map of Step Functions aliases to create. Each key is the alias name. Each routing<br/>configuration entry routes `weight` percent of traffic to a state machine version;<br/>when `state_machine_version_arn` is omitted it defaults to the version published by<br/>this module (requires `publish = true`). Weights across entries must sum to 100.<br/>Use two entries with explicit version ARNs for gradual (canary) rollouts. | <pre>map(object({<br/>    description = optional(string)<br/>    routing_configuration = list(object({<br/>      state_machine_version_arn = optional(string)<br/>      weight                    = number<br/>    }))<br/>  }))</pre> | `{}` | no |
| create\_alarms | Whether to create CloudWatch alarms for the state machine | `bool` | `false` | no |
| create\_event\_role | Whether to create an IAM role for EventBridge triggers | `bool` | `false` | no |
| create\_log\_group | Whether to create a CloudWatch log group for the state machine | `bool` | `true` | no |
| create\_role | Whether to create an IAM role for the state machine | `bool` | `true` | no |
| definition | The Amazon States Language (ASL) definition of the state machine in JSON format | `string` | n/a | yes |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| event\_role\_arn | ARN of an existing IAM role for EventBridge to use when invoking the state machine. If not set, a role is created. | `string` | `null` | no |
| event\_rules | Map of EventBridge rules to create for triggering the state machine. Each entry supports `description`, `schedule_expression`, `event_pattern`, `is_enabled`, `input`, `dead_letter_arn`, and `retry_policy` (with `maximum_event_age_in_seconds` and `maximum_retry_attempts`). | `any` | `{}` | no |
| existing\_log\_group\_arn | ARN of an existing CloudWatch log group. Used when `create_log_group` is false. | `string` | `null` | no |
| log\_group\_kms\_key\_id | KMS key ARN to use for encrypting the CloudWatch log group | `string` | `null` | no |
| log\_group\_name | Name of the CloudWatch log group. Defaults to `/aws/states/<name>`. | `string` | `null` | no |
| log\_group\_retention\_in\_days | Number of days to retain log events in the CloudWatch log group | `number` | `30` | no |
| logging\_enabled | Whether to enable logging for the state machine | `bool` | `true` | no |
| logging\_include\_execution\_data | Whether the execution data is included in the log output | `bool` | `true` | no |
| logging\_level | Defines which category of execution history events are logged. Valid values: `ALL`, `ERROR`, `FATAL`, `OFF`. | `string` | `"ALL"` | no |
| name | Name of the Step Functions state machine | `string` | n/a | yes |
| ok\_actions | List of ARNs to notify when the alarm transitions to OK state | `list(string)` | `[]` | no |
| publish | Whether to publish a version of the state machine during creation | `bool` | `false` | no |
| role\_arn | ARN of an existing IAM role to use. Required if `create_role` is false. | `string` | `null` | no |
| role\_description | Description of the IAM role | `string` | `null` | no |
| role\_force\_detach\_policies | Whether to force detaching any policies the IAM role has before destroying it | `bool` | `true` | no |
| role\_inline\_policies | Map of inline IAM policies to attach to the role. Key is the policy name, value is the JSON policy document. | `map(string)` | `{}` | no |
| role\_name | Name of the IAM role. Defaults to the state machine name with `-role` suffix. | `string` | `null` | no |
| role\_path | Path for the IAM role | `string` | `null` | no |
| role\_permissions\_boundary | ARN of the permissions boundary policy to attach to the IAM role | `string` | `null` | no |
| role\_policy\_arns | Map of IAM policy ARNs to attach to the role | `map(string)` | `{}` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| tracing\_enabled | Whether to enable X-Ray tracing for the state machine | `bool` | `false` | no |
| trusted\_account\_arns | List of trusted AWS account ARNs that can assume the role | `list(string)` | `[]` | no |
| trusted\_service\_principals | List of AWS service principals that can assume the role. Defaults to `states.amazonaws.com`. | `list(string)` | <pre>[<br/>  "states.amazonaws.com"<br/>]</pre> | no |
| type | Type of the state machine. Valid values: `STANDARD`, `EXPRESS`. | `string` | `"STANDARD"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| alarm\_execution\_failed\_arn | The ARN of the execution failed CloudWatch alarm |
| alarm\_execution\_throttled\_arn | The ARN of the execution throttled CloudWatch alarm |
| alarm\_execution\_timed\_out\_arn | The ARN of the execution timed out CloudWatch alarm |
| alias\_arns | Map of alias names to their ARNs |
| alias\_creation\_dates | Map of alias names to their creation dates |
| event\_role\_arn | The ARN of the IAM role created for EventBridge |
| event\_rule\_arns | Map of EventBridge rule ARNs |
| event\_rule\_names | Map of EventBridge rule names |
| log\_group\_arn | The ARN of the CloudWatch log group |
| log\_group\_name | The name of the CloudWatch log group |
| role\_arn | The ARN of the IAM role created for the state machine |
| role\_id | The ID of the IAM role |
| role\_name | The name of the IAM role created for the state machine |
| role\_unique\_id | The unique ID of the IAM role |
| state\_machine\_arn | The ARN of the state machine |
| state\_machine\_creation\_date | The date the state machine was created |
| state\_machine\_id | The ID of the state machine |
| state\_machine\_name | The name of the state machine |
| state\_machine\_revision\_id | The revision identifier for the state machine |
| state\_machine\_status | The current status of the state machine |
| state\_machine\_version\_arn | The ARN of the state machine version published during creation/update (when publish = true) |
<!-- END_TF_DOCS -->

## Examples

### Basic Standard Workflow

A simple STANDARD state machine with default logging and IAM role creation.

```hcl
module "order_processing" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//step-functions?depth=1&ref=master"

  name = "order-processing"

  definition = jsonencode({
    Comment = "Order processing workflow"
    StartAt = "ValidateOrder"
    States = {
      ValidateOrder = {
        Type     = "Task"
        Resource = "arn:aws:lambda:us-east-1:123456789012:function:validate-order"
        Next     = "ProcessPayment"
      }
      ProcessPayment = {
        Type     = "Task"
        Resource = "arn:aws:lambda:us-east-1:123456789012:function:process-payment"
        Next     = "FulfillOrder"
      }
      FulfillOrder = {
        Type     = "Task"
        Resource = "arn:aws:lambda:us-east-1:123456789012:function:fulfill-order"
        End      = true
      }
    }
  })

  role_inline_policies = {
    lambda-invoke = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = "arn:aws:lambda:us-east-1:123456789012:function:*"
      }]
    })
  }

  tags = {
    Environment = "production"
    Service     = "orders"
  }
}
```

### Express Workflow with Logging

An EXPRESS state machine with full logging enabled for high-throughput workloads.

```hcl
module "data_transform" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//step-functions?depth=1&ref=master"

  name = "data-transform"
  type = "EXPRESS"

  definition = jsonencode({
    Comment = "Real-time data transformation"
    StartAt = "Transform"
    States = {
      Transform = {
        Type     = "Task"
        Resource = "arn:aws:lambda:us-east-1:123456789012:function:transform"
        End      = true
      }
    }
  })

  logging_enabled                = true
  logging_level                  = "ALL"
  logging_include_execution_data = true
  log_group_retention_in_days    = 7

  tags = {
    Environment = "production"
    Service     = "data-pipeline"
  }
}
```

### Workflow with X-Ray Tracing

Enable X-Ray tracing for distributed tracing and performance analysis.

```hcl
module "api_orchestrator" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//step-functions?depth=1&ref=master"

  name            = "api-orchestrator"
  tracing_enabled = true

  definition = jsonencode({
    Comment = "API orchestration with tracing"
    StartAt = "GetUserProfile"
    States = {
      GetUserProfile = {
        Type     = "Task"
        Resource = "arn:aws:lambda:us-east-1:123456789012:function:get-user-profile"
        Next     = "GetRecommendations"
      }
      GetRecommendations = {
        Type     = "Task"
        Resource = "arn:aws:lambda:us-east-1:123456789012:function:get-recommendations"
        End      = true
      }
    }
  })

  role_inline_policies = {
    lambda-invoke = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = "arn:aws:lambda:us-east-1:123456789012:function:*"
      }]
    })
  }

  tags = {
    Environment = "production"
  }
}
```

### Workflow Calling Lambda, DynamoDB, and SQS

A state machine that integrates with multiple AWS services using SDK integrations.

```hcl
module "multi_service_workflow" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//step-functions?depth=1&ref=master"

  name = "multi-service-workflow"

  definition = jsonencode({
    Comment = "Workflow calling Lambda, DynamoDB, and SQS"
    StartAt = "InvokeLambda"
    States = {
      InvokeLambda = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = "arn:aws:lambda:us-east-1:123456789012:function:process-data"
          Payload = {
            "input.$" = "$.data"
          }
        }
        ResultPath = "$.lambdaResult"
        Next       = "WriteToDynamoDB"
      }
      WriteToDynamoDB = {
        Type     = "Task"
        Resource = "arn:aws:states:::dynamodb:putItem"
        Parameters = {
          TableName = "processing-results"
          Item = {
            id     = { "S.$" = "$.id" }
            result = { "S.$" = "$.lambdaResult.Payload.result" }
          }
        }
        ResultPath = "$.dynamoResult"
        Next       = "SendToSQS"
      }
      SendToSQS = {
        Type     = "Task"
        Resource = "arn:aws:states:::sqs:sendMessage"
        Parameters = {
          QueueUrl    = "https://sqs.us-east-1.amazonaws.com/123456789012/notifications"
          MessageBody = {
            "input.$" = "$.id"
          }
        }
        End = true
      }
    }
  })

  role_inline_policies = {
    service-integrations = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["lambda:InvokeFunction"]
          Resource = "arn:aws:lambda:us-east-1:123456789012:function:process-data"
        },
        {
          Effect   = "Allow"
          Action   = ["dynamodb:PutItem"]
          Resource = "arn:aws:dynamodb:us-east-1:123456789012:table/processing-results"
        },
        {
          Effect   = "Allow"
          Action   = ["sqs:SendMessage"]
          Resource = "arn:aws:sqs:us-east-1:123456789012:notifications"
        }
      ]
    })
  }

  tags = {
    Environment = "production"
    Service     = "data-pipeline"
  }
}
```

### Workflow with Error Handling and Retry

A state machine demonstrating Retry and Catch patterns for robust error handling.

```hcl
module "resilient_workflow" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//step-functions?depth=1&ref=master"

  name            = "resilient-workflow"
  tracing_enabled = true

  create_alarms  = true
  alarm_actions  = ["arn:aws:sns:us-east-1:123456789012:ops-alerts"]
  ok_actions     = ["arn:aws:sns:us-east-1:123456789012:ops-alerts"]

  definition = jsonencode({
    Comment = "Workflow with error handling and retry"
    StartAt = "ProcessItem"
    States = {
      ProcessItem = {
        Type     = "Task"
        Resource = "arn:aws:lambda:us-east-1:123456789012:function:process-item"
        Retry = [
          {
            ErrorEquals     = ["States.TaskFailed", "Lambda.ServiceException"]
            IntervalSeconds = 2
            MaxAttempts     = 3
            BackoffRate     = 2.0
          },
          {
            ErrorEquals     = ["States.Timeout"]
            IntervalSeconds = 5
            MaxAttempts     = 2
            BackoffRate     = 1.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next        = "HandleError"
            ResultPath  = "$.error"
          }
        ]
        Next = "NotifySuccess"
      }
      NotifySuccess = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = "arn:aws:sns:us-east-1:123456789012:processing-complete"
          Message  = { "input.$" = "$.result" }
        }
        End = true
      }
      HandleError = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = "arn:aws:sns:us-east-1:123456789012:processing-errors"
          Message  = { "input.$" = "$.error" }
        }
        Next = "FailState"
      }
      FailState = {
        Type  = "Fail"
        Error = "ProcessingFailed"
        Cause = "Item processing failed after retries"
      }
    }
  })

  role_inline_policies = {
    service-access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["lambda:InvokeFunction"]
          Resource = "arn:aws:lambda:us-east-1:123456789012:function:process-item"
        },
        {
          Effect   = "Allow"
          Action   = ["sns:Publish"]
          Resource = "arn:aws:sns:us-east-1:123456789012:processing-*"
        }
      ]
    })
  }

  tags = {
    Environment = "production"
    Service     = "processing"
  }
}
```

### Published Version with a Live Alias

Publish a version on every definition change and point a stable `live` alias at it. Callers invoke the alias ARN so executions always use the routed version.

```hcl
module "step_function" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//step-functions?depth=1&ref=master"

  name       = "order-processing"
  definition = file("${path.module}/definitions/order-processing.json")

  publish = true

  aliases = {
    live = {
      description = "Production traffic alias"
      routing_configuration = [
        {
          weight = 100 # version ARN defaults to the version published by this module
        },
      ]
    }
  }

  tags = {
    Environment = "production"
  }
}

# Invoke via the alias ARN
output "live_alias_arn" {
  value = module.step_function.alias_arns["live"]
}
```

### Canary Rollout Between Two Versions

Split traffic between two explicitly pinned versions during a rollout.

```hcl
module "step_function" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//step-functions?depth=1&ref=master"

  name       = "order-processing"
  definition = file("${path.module}/definitions/order-processing.json")

  publish = true

  aliases = {
    canary = {
      description = "Gradual rollout of version 12"
      routing_configuration = [
        {
          state_machine_version_arn = "arn:aws:states:eu-west-1:123456789012:stateMachine:order-processing:11"
          weight                    = 90
        },
        {
          state_machine_version_arn = "arn:aws:states:eu-west-1:123456789012:stateMachine:order-processing:12"
          weight                    = 10
        },
      ]
    }
  }

  tags = {
    Environment = "production"
  }
}
```
