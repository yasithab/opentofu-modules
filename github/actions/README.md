<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.11.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.38.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.38.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_github_oidc_arn"></a> [github\_oidc\_arn](#input\_github\_oidc\_arn) | The GitHub openid connect provider arn | `string` | `null` | no |
| <a name="input_github_organization_name"></a> [github\_organization\_name](#input\_github\_organization\_name) | The GitHub organization name | `string` | `null` | no |
| <a name="input_iam_policy_delay_after_creation_in_ms"></a> [iam\_policy\_delay\_after\_creation\_in\_ms](#input\_iam\_policy\_delay\_after\_creation\_in\_ms) | Number of milliseconds to wait between creating the policy and setting its version as default | `number` | `null` | no |
| <a name="input_iam_policy_description"></a> [iam\_policy\_description](#input\_iam\_policy\_description) | The description of the GitHub actions IAM policy | `string` | `"GitHub Actions Policy"` | no |
| <a name="input_iam_policy_document"></a> [iam\_policy\_document](#input\_iam\_policy\_document) | The JSON formatted policy document | `any` | `null` | no |
| <a name="input_iam_policy_name"></a> [iam\_policy\_name](#input\_iam\_policy\_name) | The name of the GitHub actions IAM policy | `string` | `null` | no |
| <a name="input_iam_policy_path"></a> [iam\_policy\_path](#input\_iam\_policy\_path) | Path for the IAM policy | `string` | `"/"` | no |
| <a name="input_iam_role_description"></a> [iam\_role\_description](#input\_iam\_role\_description) | The description of the GitHub actions IAM role | `string` | `"GitHub Actions Role"` | no |
| <a name="input_iam_role_force_detach_policies"></a> [iam\_role\_force\_detach\_policies](#input\_iam\_role\_force\_detach\_policies) | Whether to force-detach any policies the role has before destroying it | `bool` | `false` | no |
| <a name="input_iam_role_max_session_duration"></a> [iam\_role\_max\_session\_duration](#input\_iam\_role\_max\_session\_duration) | Maximum session duration (in seconds) for the IAM role. Value between 3600 and 43200. | `number` | `3600` | no |
| <a name="input_iam_role_name"></a> [iam\_role\_name](#input\_iam\_role\_name) | The name of the GitHub actions IAM role | `string` | `null` | no |
| <a name="input_iam_role_path"></a> [iam\_role\_path](#input\_iam\_role\_path) | Path for the IAM role | `string` | `"/"` | no |
| <a name="input_iam_role_permissions_boundary"></a> [iam\_role\_permissions\_boundary](#input\_iam\_role\_permissions\_boundary) | ARN of the policy used as permissions boundary for the IAM role | `string` | `null` | no |
| <a name="input_repo_names"></a> [repo\_names](#input\_repo\_names) | List of GitHub repository names | `list(string)` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policy_arn"></a> [policy\_arn](#output\_policy\_arn) | ARN of the GitHub Actions IAM policy |
| <a name="output_policy_name"></a> [policy\_name](#output\_policy\_name) | Name of the GitHub Actions IAM policy |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the GitHub Actions IAM role |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | Name of the GitHub Actions IAM role |
<!-- END_TF_DOCS -->
