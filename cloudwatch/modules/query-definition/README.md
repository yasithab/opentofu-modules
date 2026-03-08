<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.34 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.34 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | The name of the CloudWatch Logs Insights query definition. | `string` | n/a | yes |
| <a name="input_query_string"></a> [query\_string](#input\_query\_string) | The query to save as a CloudWatch Logs Insights query definition. | `string` | n/a | yes |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_log_group_names"></a> [log\_group\_names](#input\_log\_group\_names) | Specific log groups to use with the query. If not provided, the query applies to all log groups. | `list(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_query_definition_id"></a> [query\_definition\_id](#output\_query\_definition\_id) | The ID of the CloudWatch Logs Insights query definition. |
| <a name="output_query_definition_name"></a> [query\_definition\_name](#output\_query\_definition\_name) | The name of the CloudWatch Logs Insights query definition. |
<!-- END_TF_DOCS -->
