# CloudWatch Dashboard

Provisions a CloudWatch dashboard with a JSON-defined widget layout for monitoring AWS resources.

## Features

- **JSON Dashboard Body** - Define dashboards using CloudWatch's JSON widget format via `jsonencode()` or raw JSON
- **Multi-Widget Support** - Combine metric, text, log, alarm, and explorer widgets in a single dashboard
- **Cross-Account/Region** - Reference metrics from other accounts and regions in widget definitions
- **Lifecycle Toggle** - Enable/disable dashboard creation via the `enabled` variable

## Usage

```hcl
module "dashboard" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/dashboard?depth=1&ref=master"

  dashboard_name = "app-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", "my-cluster", "ServiceName", "my-service"]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "ECS CPU Utilization"
        }
      }
    ]
  })

  tags = {
    Environment = "production"
  }
}
```

## Examples

### Multi-Widget Dashboard

```hcl
module "dashboard" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/dashboard?depth=1&ref=master"

  dashboard_name = "production-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", "prod-cluster", "ServiceName", "api"],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", "prod-cluster", "ServiceName", "api"]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "ECS Resource Utilization"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "app/prod-alb/abc123", { stat = "Sum" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "app/prod-alb/abc123", { stat = "Sum" }]
          ]
          period = 60
          region = "us-east-1"
          title  = "ALB Request Metrics"
          view   = "timeSeries"
        }
      },
      {
        type   = "text"
        x      = 0
        y      = 6
        width  = 24
        height = 1
        properties = {
          markdown = "## Database Metrics"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", "prod-aurora"],
            ["AWS/RDS", "CPUUtilization", "DBClusterIdentifier", "prod-aurora"]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Aurora Cluster Metrics"
        }
      },
      {
        type   = "alarm"
        x      = 12
        y      = 7
        width  = 12
        height = 6
        properties = {
          alarms = [
            "arn:aws:cloudwatch:us-east-1:123456789012:alarm:high-cpu",
            "arn:aws:cloudwatch:us-east-1:123456789012:alarm:high-memory",
            "arn:aws:cloudwatch:us-east-1:123456789012:alarm:5xx-errors"
          ]
          title = "Active Alarms"
        }
      }
    ]
  })

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

### Dashboard with Log Widgets

```hcl
module "dashboard" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/dashboard?depth=1&ref=master"

  dashboard_name = "application-logs"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "log"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          query   = "fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 50"
          region  = "us-east-1"
          stacked = false
          view    = "table"
          title   = "Recent Errors"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        properties = {
          metrics = [
            [{ expression = "SEARCH('{AWS/Lambda,FunctionName} Errors', 'Sum', 300)", id = "errors", label = "Lambda Errors" }]
          ]
          region = "us-east-1"
          title  = "Lambda Error Rates (All Functions)"
          view   = "timeSeries"
        }
      }
    ]
  })
}
```
