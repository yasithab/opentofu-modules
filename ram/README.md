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
| <a name="input_ram_resource_arn"></a> [ram\_resource\_arn](#input\_ram\_resource\_arn) | (Required) Amazon Resource Name (ARN) of the resource to associate with the RAM Resource Share | `string` | n/a | yes |
| <a name="input_ram_resource_share_name"></a> [ram\_resource\_share\_name](#input\_ram\_resource\_share\_name) | (Required) The name of the resource share | `string` | n/a | yes |
| <a name="input_allow_external_principals"></a> [allow\_external\_principals](#input\_allow\_external\_principals) | Indicates whether principals outside your organization can be associated with a resource share | `bool` | `false` | no |
| <a name="input_enable_sharing_with_organization"></a> [enable\_sharing\_with\_organization](#input\_enable\_sharing\_with\_organization) | Whether to enable sharing resources with AWS Organizations. When enabled, allows principals within the organization to access shared resources without individual invitations | `bool` | `false` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_permission_arns"></a> [permission\_arns](#input\_permission\_arns) | Specifies the Amazon Resource Names (ARNs) of the RAM permission to associate with the resource share. If you do not specify an ARN for the permission, RAM automatically attaches the default version of the permission for each resource type. You can associate only one permission with each resource type included in the resource share. | `list(string)` | `[]` | no |
| <a name="input_ram_principals"></a> [ram\_principals](#input\_ram\_principals) | A list of principals to associate with the resource share. Possible values<br/>are:<br/><br/>* AWS account ID<br/>* Organization ARN<br/>* Organization Unit ARN<br/><br/>If this is not provided and<br/>`ram_resource_share_enabled` is `true`, the Organization ARN will be used. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_resource_share_id"></a> [resource\_share\_id](#output\_resource\_share\_id) | RAM resource share ID |
<!-- END_TF_DOCS -->