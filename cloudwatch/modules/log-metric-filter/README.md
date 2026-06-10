# CloudWatch Log Metric Filter

OpenTofu module to create an AWS CloudWatch Log Metric Filter. Extracts metric data from log events using filter patterns and publishes the results as CloudWatch metrics.

## Features

- **Pattern-Based Filtering** - Define filter patterns to extract metric data from ingested log events
- **Metric Transformation** - Publish matched log events as CloudWatch metrics with configurable namespace, value, and unit
- **Dimensions Support** - Attach custom dimensions to emitted metrics for granular filtering
- **Default Value** - Optionally emit a default value when no log events match the filter pattern
- **Lifecycle Management** - Toggle resource creation with the `enabled` variable

> **Note — no `tags` variable:** `aws_cloudwatch_log_metric_filter` does not support resource tagging, so this module intentionally omits the repo-standard `tags` variable. This is a deliberate exemption from the module conventions for untaggable resources.

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
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| log\_group\_name | The name of the log group to associate the metric filter with. | `string` | n/a | yes |
| metric\_transformation\_default\_value | The value to emit when a filter pattern does not match a log event. Conflicts with `metric_transformation_dimensions`. | `string` | `null` | no |
| metric\_transformation\_dimensions | Map of fields to use as dimensions for the metric. Conflicts with `metric_transformation_default_value`. | `map(string)` | `null` | no |
| metric\_transformation\_name | The name of the CloudWatch metric to which the monitored log information should be published. | `string` | n/a | yes |
| metric\_transformation\_namespace | The destination namespace of the CloudWatch metric. | `string` | n/a | yes |
| metric\_transformation\_unit | The unit to assign to the metric. | `string` | `null` | no |
| metric\_transformation\_value | The value to publish to the CloudWatch metric. Each log event is assigned this value. | `string` | `"1"` | no |
| name | The name of the CloudWatch Log Metric Filter. | `string` | n/a | yes |
| pattern | A valid CloudWatch Logs filter pattern for extracting metric data out of ingested log events. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| metric\_filter\_id | The ID of the CloudWatch Log Metric Filter. |
| metric\_filter\_log\_group\_name | The name of the log group associated with the metric filter. |
| metric\_filter\_name | The name of the CloudWatch Log Metric Filter. |
<!-- END_TF_DOCS -->
