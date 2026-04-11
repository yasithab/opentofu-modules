# CloudWatch Metric Stream

OpenTofu module to create an AWS CloudWatch Metric Stream. Continuously streams CloudWatch metrics to a destination (Amazon Kinesis Data Firehose) in near real-time for analysis, storage, or forwarding to third-party observability platforms.

## Features

- **Multiple Output Formats** - Stream metrics in JSON, OpenTelemetry 0.7, or OpenTelemetry 1.0 format
- **Include/Exclude Filters** - Selectively stream metrics by namespace and metric name using include or exclude filters
- **Statistics Configuration** - Stream additional statistics (percentiles, etc.) for specific metrics beyond the default set
- **Name Prefix Support** - Use either a fixed name or an auto-generated unique name with a prefix
- **Lifecycle Management** - Toggle resource creation with the `enabled` variable

## Usage

```hcl
module "metric_stream" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/metric-stream?depth=1&ref=master"

  name          = "my-metric-stream"
  firehose_arn  = "arn:aws:firehose:us-east-1:123456789012:deliverystream/my-stream"
  role_arn      = "arn:aws:iam::123456789012:role/MetricStreamRole"
  output_format = "opentelemetry1.0"

  tags = {
    Environment = "production"
  }
}
```

### With Include Filters

```hcl
module "metric_stream" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/metric-stream?depth=1&ref=master"

  name          = "selective-stream"
  firehose_arn  = "arn:aws:firehose:us-east-1:123456789012:deliverystream/my-stream"
  role_arn      = "arn:aws:iam::123456789012:role/MetricStreamRole"
  output_format = "json"

  include_filter = {
    "AWS/EC2" = {
      metric_names = ["CPUUtilization", "NetworkIn", "NetworkOut"]
    }
    "AWS/ELB" = {}
  }

  statistics_configuration = [
    {
      additional_statistics = ["p99", "p95"]
      include_metric = [
        {
          metric_name = "CPUUtilization"
          namespace   = "AWS/EC2"
        }
      ]
    }
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `firehose_arn` | ARN of the Amazon Kinesis Firehose delivery stream | `string` | n/a | yes |
| `role_arn` | ARN of the IAM role for accessing Kinesis Firehose | `string` | n/a | yes |
| `output_format` | Output format for the metric stream (json, opentelemetry0.7, opentelemetry1.0) | `string` | n/a | yes |
| `name` | The name of the CloudWatch Metric Stream (conflicts with `name_prefix`) | `string` | `null` | no |
| `name_prefix` | Creates a unique name beginning with the specified prefix (conflicts with `name`) | `string` | `null` | no |
| `exclude_filter` | Map of exclusive metric filters keyed by namespace (conflicts with `include_filter`) | `any` | `{}` | no |
| `include_filter` | Map of inclusive metric filters keyed by namespace (conflicts with `exclude_filter`) | `any` | `{}` | no |
| `statistics_configuration` | List of statistics configurations for streaming additional statistics | `any` | `[]` | no |
| `enabled` | Set to false to prevent the module from creating any resources | `bool` | `true` | no |
| `tags` | Map of tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `metric_stream_arn` | The ARN of the CloudWatch Metric Stream |
| `metric_stream_name` | The name of the CloudWatch Metric Stream |
| `metric_stream_creation_date` | The date the metric stream was created |
| `metric_stream_last_update_date` | The date the metric stream was last updated |
| `metric_stream_state` | The state of the metric stream (running or stopped) |
