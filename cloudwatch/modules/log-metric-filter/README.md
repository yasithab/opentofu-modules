# CloudWatch Log Metric Filter

OpenTofu module to create an AWS CloudWatch Log Metric Filter. Extracts metric data from log events using filter patterns and publishes the results as CloudWatch metrics.

## Features

- **Pattern-Based Filtering** - Define filter patterns to extract metric data from ingested log events
- **Metric Transformation** - Publish matched log events as CloudWatch metrics with configurable namespace, value, and unit
- **Dimensions Support** - Attach custom dimensions to emitted metrics for granular filtering
- **Default Value** - Optionally emit a default value when no log events match the filter pattern
- **Lifecycle Management** - Toggle resource creation with the `enabled` variable

## Usage

```hcl
module "error_metric_filter" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/log-metric-filter?depth=1&ref=master"

  name           = "error-count"
  pattern        = "ERROR"
  log_group_name = "/aws/lambda/my-function"

  metric_transformation_name      = "ErrorCount"
  metric_transformation_namespace = "Custom/MyApp"
  metric_transformation_value     = "1"
}
```

### With Default Value

```hcl
module "error_metric_filter" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/log-metric-filter?depth=1&ref=master"

  name           = "error-count"
  pattern        = "[level = ERROR]"
  log_group_name = "/aws/ecs/my-service"

  metric_transformation_name          = "ErrorCount"
  metric_transformation_namespace     = "Custom/MyApp"
  metric_transformation_value         = "1"
  metric_transformation_default_value = "0"
  metric_transformation_unit          = "Count"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | The name of the CloudWatch Log Metric Filter | `string` | n/a | yes |
| `pattern` | A valid CloudWatch Logs filter pattern for extracting metric data | `string` | n/a | yes |
| `log_group_name` | The name of the log group to associate the metric filter with | `string` | n/a | yes |
| `metric_transformation_name` | The name of the CloudWatch metric to publish | `string` | n/a | yes |
| `metric_transformation_namespace` | The destination namespace of the CloudWatch metric | `string` | n/a | yes |
| `metric_transformation_value` | The value to publish to the CloudWatch metric | `string` | `"1"` | no |
| `metric_transformation_default_value` | The value to emit when no log events match (conflicts with dimensions) | `string` | `null` | no |
| `metric_transformation_unit` | The unit to assign to the metric | `string` | `null` | no |
| `metric_transformation_dimensions` | Map of fields to use as dimensions (conflicts with default_value) | `map(string)` | `null` | no |
| `enabled` | Set to false to prevent the module from creating any resources | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| `metric_filter_id` | The ID of the CloudWatch Log Metric Filter |
| `metric_filter_name` | The name of the CloudWatch Log Metric Filter |
| `metric_filter_log_group_name` | The name of the log group associated with the metric filter |
