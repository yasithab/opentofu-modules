# AWS Step Functions

OpenTofu module for creating and managing AWS Step Functions state machines with IAM roles, CloudWatch logging, X-Ray tracing, alarms, and EventBridge triggers.

## Features

- **Standard and Express Workflows** - Support for both STANDARD and EXPRESS state machine types
- **IAM Role Management** - Automatic IAM role creation with configurable trust policy, managed policies, and inline policies
- **CloudWatch Logging** - Configurable log group with retention, KMS encryption, and execution data inclusion
- **X-Ray Tracing** - Optional X-Ray tracing integration with automatic IAM permissions
- **Version Publishing** - Support for publishing state machine versions
- **CloudWatch Alarms** - Pre-configured alarms for execution failures, throttling, and timeouts
- **EventBridge Integration** - Create EventBridge rules to trigger state machine executions on schedule or event patterns
- **Security by Default** - Logging enabled by default, least-privilege IAM policies

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
