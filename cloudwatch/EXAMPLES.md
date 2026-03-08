# CloudWatch Module - Examples

## Basic Log Group

Create a CloudWatch Log Group with 90-day retention.

```hcl
module "cloudwatch_log_group" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch?depth=1&ref=v2.0.0"

  enabled        = true
  log_group_name = "/app/my-service"

  tags = {
    Environment = "production"
    Service     = "my-service"
  }
}
```

## Encrypted Log Group with Custom Retention

Create a KMS-encrypted log group with 365-day retention and log streams.

```hcl
module "cloudwatch_encrypted" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch?depth=1&ref=v2.0.0"

  enabled           = true
  log_group_name    = "/app/payment-service"
  retention_in_days = 365
  kms_key_id        = "arn:aws:kms:eu-west-1:123456789012:key/mrk-00000000000000000000000000000000"

  create_log_streams = true
  log_streams = {
    application = {}
    error       = {}
    audit       = {}
  }

  tags = {
    Environment = "production"
    Service     = "payment-service"
    Compliance  = "pci-dss"
  }
}
```

## Infrequent Access Log Group

Create a log group using the INFREQUENT_ACCESS storage class for cost savings.

```hcl
module "cloudwatch_infrequent" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch?depth=1&ref=v2.0.0"

  enabled           = true
  log_group_name    = "/app/batch-jobs"
  retention_in_days = 30
  log_group_class   = "INFREQUENT_ACCESS"

  tags = {
    Environment = "production"
    Service     = "batch"
  }
}
```

## Metric Alarm for High CPU

Create a CloudWatch Metric Alarm that triggers when EC2 instance CPU exceeds 80%.

```hcl
module "cpu_alarm" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/metric-alarm?depth=1&ref=v2.0.0"

  enabled = true

  alarm_name          = "high-cpu-utilization"
  alarm_description   = "CPU utilization exceeded 80% for 5 minutes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  threshold           = 80

  metric_name = "CPUUtilization"
  namespace   = "AWS/EC2"
  period      = 300
  statistic   = "Average"

  dimensions = {
    InstanceId = "i-0123456789abcdef0"
  }

  alarm_actions = ["arn:aws:sns:eu-west-1:123456789012:ops-alerts"]
  ok_actions    = ["arn:aws:sns:eu-west-1:123456789012:ops-alerts"]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Metric Alarm with Math Expression

Create an alarm based on a metric math expression combining multiple metrics.

```hcl
module "error_rate_alarm" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/metric-alarm?depth=1&ref=v2.0.0"

  enabled = true

  alarm_name          = "api-error-rate"
  alarm_description   = "API error rate exceeds 5%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 5

  metric_query = [
    {
      id          = "error_rate"
      expression  = "(errors / requests) * 100"
      label       = "Error Rate"
      return_data = true
    },
    {
      id = "errors"
      metric = {
        metric_name = "5XXError"
        namespace   = "AWS/ApiGateway"
        period      = 300
        stat        = "Sum"
        dimensions = {
          ApiName = "my-api"
        }
      }
    },
    {
      id = "requests"
      metric = {
        metric_name = "Count"
        namespace   = "AWS/ApiGateway"
        period      = 300
        stat        = "Sum"
        dimensions = {
          ApiName = "my-api"
        }
      }
    },
  ]

  alarm_actions = ["arn:aws:sns:eu-west-1:123456789012:ops-alerts"]

  tags = {
    Environment = "production"
    Service     = "api"
  }
}
```

## Composite Alarm

Create a composite alarm that triggers only when both CPU and memory alarms are in ALARM state.

```hcl
module "composite_alarm" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/composite-alarm?depth=1&ref=v2.0.0"

  enabled = true

  alarm_name        = "service-health-critical"
  alarm_description = "Both CPU and memory are in alarm state"
  alarm_rule        = "ALARM(high-cpu-alarm) AND ALARM(high-memory-alarm)"

  alarm_actions = ["arn:aws:sns:eu-west-1:123456789012:critical-alerts"]
  ok_actions    = ["arn:aws:sns:eu-west-1:123456789012:critical-alerts"]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Log Metric Filter with Alarm

Create a metric filter to count error log entries, then alarm on it.

```hcl
module "error_metric_filter" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/log-metric-filter?depth=1&ref=v2.0.0"

  enabled = true

  name           = "application-errors"
  pattern        = "{ $.level = \"ERROR\" }"
  log_group_name = "/app/my-service"

  metric_transformation_name      = "ApplicationErrorCount"
  metric_transformation_namespace = "Custom/MyService"
  metric_transformation_value     = "1"
}

module "error_count_alarm" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/metric-alarm?depth=1&ref=v2.0.0"

  enabled = true

  alarm_name          = "high-error-count"
  alarm_description   = "More than 10 application errors in 5 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 10

  metric_name = "ApplicationErrorCount"
  namespace   = "Custom/MyService"
  period      = 300
  statistic   = "Sum"

  alarm_actions = ["arn:aws:sns:eu-west-1:123456789012:ops-alerts"]

  tags = {
    Environment = "production"
    Service     = "my-service"
  }
}
```

## Log Subscription Filter to Lambda

Stream log events from a log group to a Lambda function for processing.

```hcl
module "log_subscription" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/log-subscription-filter?depth=1&ref=v2.0.0"

  enabled = true

  name            = "error-log-processor"
  log_group_name  = "/app/my-service"
  destination_arn = "arn:aws:lambda:eu-west-1:123456789012:function:log-processor"
  filter_pattern  = "{ $.level = \"ERROR\" }"
}
```

## Metric Stream to Firehose

Stream CloudWatch metrics to a Kinesis Data Firehose for external observability platforms.

```hcl
module "metric_stream" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/metric-stream?depth=1&ref=v2.0.0"

  enabled = true

  name          = "datadog-metrics"
  firehose_arn  = "arn:aws:firehose:eu-west-1:123456789012:deliverystream/datadog-metrics"
  role_arn      = "arn:aws:iam::123456789012:role/cloudwatch-metric-stream"
  output_format = "opentelemetry1.0"

  include_filter = {
    "AWS/EC2"  = { metric_names = [] }
    "AWS/ELB"  = { metric_names = [] }
    "AWS/RDS"  = { metric_names = [] }
    "AWS/Lambda" = { metric_names = [] }
  }

  tags = {
    Environment = "production"
    Team        = "observability"
  }
}
```

## CloudWatch Logs Insights Query

Save a reusable CloudWatch Logs Insights query definition.

```hcl
module "error_query" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/query-definition?depth=1&ref=v2.0.0"

  enabled = true

  name            = "top-errors-last-hour"
  log_group_names = ["/app/my-service", "/app/payment-service"]

  query_string = <<-EOQ
    fields @timestamp, @message, @logStream
    | filter @message like /ERROR/
    | stats count(*) as errorCount by @logStream
    | sort errorCount desc
    | limit 20
  EOQ
}
```
