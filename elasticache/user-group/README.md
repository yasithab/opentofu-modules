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
| <a name="input_create_default_user"></a> [create\_default\_user](#input\_create\_default\_user) | Determines whether a default user will be created | `bool` | `true` | no |
| <a name="input_create_group"></a> [create\_group](#input\_create\_group) | Determines whether a user group will be created | `bool` | `true` | no |
| <a name="input_default_user"></a> [default\_user](#input\_default\_user) | A map of default user attributes | `any` | `{}` | no |
| <a name="input_default_user_id"></a> [default\_user\_id](#input\_default\_user\_id) | The ID of the default user | `string` | `"default"` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_engine"></a> [engine](#input\_engine) | The current supported value is `REDIS` | `string` | `"REDIS"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region where the resource(s) will be managed. Defaults to the region set in the provider configuration | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_user_group_id"></a> [user\_group\_id](#input\_user\_group\_id) | The ID of the user group | `string` | `null` | no |
| <a name="input_users"></a> [users](#input\_users) | A map of users to create | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_group_arn"></a> [group\_arn](#output\_group\_arn) | The ARN that identifies the user group |
| <a name="output_group_id"></a> [group\_id](#output\_group\_id) | The user group identifier |
| <a name="output_users"></a> [users](#output\_users) | A map of users created and their attributes |
<!-- END_TF_DOCS -->