<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.11.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.37.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.37.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_health_checks"></a> [health\_checks](#input\_health\_checks) | Map of Route53 health checks to create | <pre>map(object({<br/>    type                            = string<br/>    fqdn                            = optional(string)<br/>    ip_address                      = optional(string)<br/>    port                            = optional(number)<br/>    resource_path                   = optional(string)<br/>    failure_threshold               = optional(number, 3)<br/>    request_interval                = optional(number, 30)<br/>    regions                         = optional(list(string))<br/>    measure_latency                 = optional(bool, false)<br/>    invert_healthcheck              = optional(bool, false)<br/>    disabled                        = optional(bool, false)<br/>    enable_sni                      = optional(bool)<br/>    reference_name                  = optional(string)<br/>    child_health_threshold          = optional(number)<br/>    child_healthchecks              = optional(list(string))<br/>    cloudwatch_alarm_name           = optional(string)<br/>    cloudwatch_alarm_region         = optional(string)<br/>    insufficient_data_health_status = optional(string)<br/>    search_string                   = optional(string)<br/>    routing_control_arn             = optional(string)<br/>    triggers                        = optional(map(string))<br/>    tags                            = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_private_zone"></a> [private\_zone](#input\_private\_zone) | Whether Route53 zone is private or public | `bool` | `false` | no |
| <a name="input_records"></a> [records](#input\_records) | List of objects of DNS records | `any` | `[]` | no |
| <a name="input_records_jsonencoded"></a> [records\_jsonencoded](#input\_records\_jsonencoded) | List of map of DNS records (stored as jsonencoded string, for terragrunt) | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | ID of DNS zone | `string` | `null` | no |
| <a name="input_zone_name"></a> [zone\_name](#input\_zone\_name) | Name of DNS zone | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_health_check_arns"></a> [health\_check\_arns](#output\_health\_check\_arns) | Map of health check names to their ARNs |
| <a name="output_health_check_ids"></a> [health\_check\_ids](#output\_health\_check\_ids) | Map of health check names to their IDs |
| <a name="output_record_fqdn"></a> [record\_fqdn](#output\_record\_fqdn) | FQDN built using the zone domain and name |
| <a name="output_record_name"></a> [record\_name](#output\_record\_name) | The name of the record |
<!-- END_TF_DOCS -->