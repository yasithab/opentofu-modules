<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.34 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.34 |
| <a name="provider_null"></a> [null](#provider\_null) | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_region"></a> [region](#input\_region) | The AWS region to bootstrap | `string` | n/a | yes |
| <a name="input_cloudformation_execution_policy_arns"></a> [cloudformation\_execution\_policy\_arns](#input\_cloudformation\_execution\_policy\_arns) | List of IAM policy ARNs to use as the CloudFormation execution policies for CDK bootstrap. Defaults to AdministratorAccess when not set. | `list(string)` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_trust_account_ids"></a> [trust\_account\_ids](#input\_trust\_account\_ids) | List of AWS account IDs to trust for cross-account deployments (e.g. a central CI/CD account). | `list(string)` | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->