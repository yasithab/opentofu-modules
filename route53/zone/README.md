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
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | Map of Route53 zone parameters | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_name_servers"></a> [name\_servers](#output\_name\_servers) | Name servers of Route53 zone |
| <a name="output_static_zone_name"></a> [static\_zone\_name](#output\_static\_zone\_name) | Name of Route53 zone created statically to avoid invalid count argument error when creating records and zones simmultaneously |
| <a name="output_zone_arn"></a> [zone\_arn](#output\_zone\_arn) | Zone ARN of Route53 zone |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | Zone ID of Route53 zone |
| <a name="output_zone_name"></a> [zone\_name](#output\_zone\_name) | Name of Route53 zone |
<!-- END_TF_DOCS -->