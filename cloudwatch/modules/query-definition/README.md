# CloudWatch Query Definition

OpenTofu module to create an AWS CloudWatch Logs Insights query definition. Saves reusable queries that can be executed against log groups from the CloudWatch Logs Insights console or API.

## Features

- **Saved Queries** - Store frequently used CloudWatch Logs Insights queries for reuse
- **Log Group Scoping** - Optionally scope queries to specific log groups, or leave unscoped to apply to all log groups
- **Lifecycle Management** - Toggle resource creation with the `enabled` variable

## Usage

```hcl
module "error_query" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/query-definition?depth=1&ref=master"

  name         = "ErrorsByService"
  query_string = <<-EOT
    fields @timestamp, @message
    | filter @message like /ERROR/
    | stats count(*) as errorCount by bin(5m)
    | sort errorCount desc
  EOT

  log_group_names = [
    "/aws/ecs/my-service",
    "/aws/lambda/my-function"
  ]
}
```

### Global Query (All Log Groups)

```hcl
module "global_query" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/query-definition?depth=1&ref=master"

  name         = "RecentLogs"
  query_string = <<-EOT
    fields @timestamp, @message
    | sort @timestamp desc
    | limit 100
  EOT
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | The name of the CloudWatch Logs Insights query definition | `string` | n/a | yes |
| `query_string` | The query to save as a CloudWatch Logs Insights query definition | `string` | n/a | yes |
| `log_group_names` | Specific log groups to use with the query (null applies to all log groups) | `list(string)` | `null` | no |
| `enabled` | Set to false to prevent the module from creating any resources | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| `query_definition_id` | The ID of the CloudWatch Logs Insights query definition |
| `query_definition_name` | The name of the CloudWatch Logs Insights query definition |
