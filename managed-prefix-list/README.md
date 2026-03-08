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
| <a name="input_enable_ram_share"></a> [enable\_ram\_share](#input\_enable\_ram\_share) | Whether to enable RAM sharing for prefix lists | `bool` | `false` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_prefix_lists"></a> [prefix\_lists](#input\_prefix\_lists) | Map of prefix list configurations. Each entry in cidr\_list must be an object with a 'cidr' key (required) and optional 'description' key. | <pre>map(object({<br/>    name           = string<br/>    cidr_list      = list(object({ cidr = string, description = optional(string) }))<br/>    address_family = optional(string, "IPv4")<br/>    tags           = optional(map(string), {})<br/>  }))</pre> | `null` | no |
| <a name="input_ram_allow_external_principals"></a> [ram\_allow\_external\_principals](#input\_ram\_allow\_external\_principals) | Indicates whether principals outside your organization can be associated with a resource share | `bool` | `false` | no |
| <a name="input_ram_permission_arns"></a> [ram\_permission\_arns](#input\_ram\_permission\_arns) | Specifies the ARNs of the RAM permissions to associate with the resource share. If not specified, RAM automatically attaches the default version of the permission for each resource type. | `list(string)` | `null` | no |
| <a name="input_ram_principals"></a> [ram\_principals](#input\_ram\_principals) | A list of principals to share prefix lists with | `set(string)` | `[]` | no |
| <a name="input_ram_tags"></a> [ram\_tags](#input\_ram\_tags) | Additional tags for the RAM resource share | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_prefix_list_arns"></a> [prefix\_list\_arns](#output\_prefix\_list\_arns) | Map of prefix list names to their ARNs |
| <a name="output_prefix_list_ids"></a> [prefix\_list\_ids](#output\_prefix\_list\_ids) | Map of prefix list names to their IDs |
| <a name="output_ram_resource_share_arns"></a> [ram\_resource\_share\_arns](#output\_ram\_resource\_share\_arns) | Map of prefix list names to their RAM resource share ARNs |
<!-- END_TF_DOCS -->