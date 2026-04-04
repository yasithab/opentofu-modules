<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.11.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.39.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.39.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_delegation_sets"></a> [delegation\_sets](#input\_delegation\_sets) | Map of Route53 delegation set parameters | `any` | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_delegation_set_id"></a> [delegation\_set\_id](#output\_delegation\_set\_id) | ID of Route53 delegation set |
| <a name="output_delegation_set_name_servers"></a> [delegation\_set\_name\_servers](#output\_delegation\_set\_name\_servers) | Name servers in the Route53 delegation set |
| <a name="output_delegation_set_reference_name"></a> [delegation\_set\_reference\_name](#output\_delegation\_set\_reference\_name) | Reference name used when the Route53 delegation set has been created |
<!-- END_TF_DOCS -->