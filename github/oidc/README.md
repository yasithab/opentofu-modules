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
| <a name="input_openid_providers"></a> [openid\_providers](#input\_openid\_providers) | Map of OpenID Connect Providers | <pre>map(object({<br/>    url             = string<br/>    client_id_list  = list(string)<br/>    thumbprint_list = optional(list(string), [])<br/>    tags            = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_openid_provider_arns"></a> [openid\_provider\_arns](#output\_openid\_provider\_arns) | Map of OpenID Connect Provider ARNs |
<!-- END_TF_DOCS -->