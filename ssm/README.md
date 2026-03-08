<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.34 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.35.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_ignore_value_changes"></a> [ignore\_value\_changes](#input\_ignore\_value\_changes) | Whether to ignore future external changes in paramater values | `bool` | `false` | no |
| <a name="input_kms_arn"></a> [kms\_arn](#input\_kms\_arn) | The ARN of a KMS key used to encrypt and decrypt SecretString values | `string` | `null` | no |
| <a name="input_parameter_read"></a> [parameter\_read](#input\_parameter\_read) | List of parameters to read from SSM. These must already exist otherwise an error is returned. Can be used with `parameter_write` as long as the parameters are different. | `list(string)` | `[]` | no |
| <a name="input_parameter_write"></a> [parameter\_write](#input\_parameter\_write) | List of maps with the parameter values to write to SSM Parameter Store | `list(map(string))` | `[]` | no |
| <a name="input_parameter_write_defaults"></a> [parameter\_write\_defaults](#input\_parameter\_write\_defaults) | Parameter write default settings | `map(any)` | <pre>{<br/>  "allowed_pattern": null,<br/>  "data_type": "text",<br/>  "description": null,<br/>  "overwrite": null,<br/>  "tier": "Standard",<br/>  "type": "SecureString"<br/>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn_map"></a> [arn\_map](#output\_arn\_map) | A map of the names and ARNs created |
| <a name="output_map"></a> [map](#output\_map) | A map of the names and values created |
| <a name="output_names"></a> [names](#output\_names) | A list of all of the parameter names |
| <a name="output_values"></a> [values](#output\_values) | A list of all of the parameter values |
<!-- END_TF_DOCS -->