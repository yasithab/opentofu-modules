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
| <a name="input_attach_ous"></a> [attach\_ous](#input\_attach\_ous) | List of OU IDs to attach the tag policies to | `list(string)` | `[]` | no |
| <a name="input_attach_to_org"></a> [attach\_to\_org](#input\_attach\_to\_org) | Whether to attach the tag policy to the organization (set to false if you want to attach to OUs) | `bool` | `false` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the tag policy | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to use for resource naming and tagging. | `string` | `null` | no |
| <a name="input_skip_destroy"></a> [skip\_destroy](#input\_skip\_destroy) | If set to true, the policy will not be deleted when the resource is destroyed. This is useful to prevent accidental deletion of tag policies attached to the organization. | `bool` | `false` | no |
| <a name="input_tag_policy"></a> [tag\_policy](#input\_tag\_policy) | List of tag policies to create | <pre>map(object({<br/>    enforced_for                                      = optional(list(string), [])<br/>    enforced_for_operator                             = optional(string)<br/>    enforced_for_operators_allowed_for_child_policies = optional(list(string))<br/>    tag_key                                           = string<br/>    tag_key_operator                                  = optional(string)<br/>    tag_key_operators_allowed_for_child_policies      = optional(list(string))<br/>    values                                            = optional(list(string))<br/>    values_operator                                   = optional(string)<br/>    values_operators_allowed_for_child_policies       = optional(list(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_attached_org_root_id"></a> [attached\_org\_root\_id](#output\_attached\_org\_root\_id) | Organization root ID the policy is attached to if the policy is attached to the root |
| <a name="output_attached_ou_ids"></a> [attached\_ou\_ids](#output\_attached\_ou\_ids) | List of OU IDs the policy is attached to |
| <a name="output_policy_id"></a> [policy\_id](#output\_policy\_id) | ID of the created tag policy |
<!-- END_TF_DOCS -->