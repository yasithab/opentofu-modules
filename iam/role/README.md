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
| <a name="input_role_description"></a> [role\_description](#input\_role\_description) | The description of the IAM role that is visible in the IAM role manager | `string` | n/a | yes |
| <a name="input_assume_role_actions"></a> [assume\_role\_actions](#input\_assume\_role\_actions) | The IAM action to be granted by the AssumeRole policy | `list(string)` | <pre>[<br/>  "sts:AssumeRole",<br/>  "sts:TagSession"<br/>]</pre> | no |
| <a name="input_assume_role_conditions"></a> [assume\_role\_conditions](#input\_assume\_role\_conditions) | List of conditions for the assume role policy | <pre>list(object({<br/>    test     = string<br/>    variable = string<br/>    values   = list(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_force_detach_policies"></a> [force\_detach\_policies](#input\_force\_detach\_policies) | Whether to force detaching any policies the role has before destroying it | `bool` | `false` | no |
| <a name="input_instance_profile_enabled"></a> [instance\_profile\_enabled](#input\_instance\_profile\_enabled) | Create EC2 Instance Profile for the role | `bool` | `false` | no |
| <a name="input_instance_profile_name"></a> [instance\_profile\_name](#input\_instance\_profile\_name) | EC2 Instance Profile name | `string` | `null` | no |
| <a name="input_instance_profile_name_prefix"></a> [instance\_profile\_name\_prefix](#input\_instance\_profile\_name\_prefix) | EC2 Instance Profile name prefix | `string` | `null` | no |
| <a name="input_managed_policy_arns"></a> [managed\_policy\_arns](#input\_managed\_policy\_arns) | List of managed policies to attach to created role | `set(string)` | `[]` | no |
| <a name="input_max_session_duration"></a> [max\_session\_duration](#input\_max\_session\_duration) | The maximum session duration (in seconds) for the role. Can have a value from 1 hour to 12 hours | `number` | `3600` | no |
| <a name="input_path"></a> [path](#input\_path) | Path to the role and policy. See [IAM Identifiers](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html) for more information. | `string` | `"/"` | no |
| <a name="input_permissions_boundary"></a> [permissions\_boundary](#input\_permissions\_boundary) | ARN of the policy that is used to set the permissions boundary for the role | `string` | `null` | no |
| <a name="input_policy_delay_after_creation_in_ms"></a> [policy\_delay\_after\_creation\_in\_ms](#input\_policy\_delay\_after\_creation\_in\_ms) | Number of milliseconds to wait between creating the policy and setting its version as default. Only applies when policy\_document\_count > 0. | `number` | `null` | no |
| <a name="input_policy_description"></a> [policy\_description](#input\_policy\_description) | The description of the IAM policy that is visible in the IAM policy manager | `string` | `null` | no |
| <a name="input_policy_document_count"></a> [policy\_document\_count](#input\_policy\_document\_count) | Number of policy documents (length of policy\_documents list) | `number` | `1` | no |
| <a name="input_policy_documents"></a> [policy\_documents](#input\_policy\_documents) | List of JSON IAM policy documents | `list(string)` | `[]` | no |
| <a name="input_policy_name"></a> [policy\_name](#input\_policy\_name) | The name of the IAM policy that is visible in the IAM policy manager | `string` | `null` | no |
| <a name="input_policy_name_prefix"></a> [policy\_name\_prefix](#input\_policy\_name\_prefix) | The name prefix of the IAM policy that is visible in the IAM policy manager | `string` | `null` | no |
| <a name="input_principals"></a> [principals](#input\_principals) | Map of service name as key and a list of ARNs to allow assuming the role as value (e.g. map(`AWS`, list(`arn:aws:iam:::role/admin`))) | `map(list(string))` | `{}` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | IAM role name | `string` | `null` | no |
| <a name="input_role_name_prefix"></a> [role\_name\_prefix](#input\_role\_name\_prefix) | IAM role name prefix | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_tags_enabled"></a> [tags\_enabled](#input\_tags\_enabled) | Enable/disable tags on IAM roles and policies | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The Amazon Resource Name (ARN) specifying the role |
| <a name="output_id"></a> [id](#output\_id) | The stable and unique string identifying the role |
| <a name="output_instance_profile"></a> [instance\_profile](#output\_instance\_profile) | Name of the ec2 profile (if enabled) |
| <a name="output_name"></a> [name](#output\_name) | The name of the IAM role created |
| <a name="output_policy"></a> [policy](#output\_policy) | Role policy document in json format. Outputs always, independent of `enabled` variable |
<!-- END_TF_DOCS -->