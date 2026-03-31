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
| <a name="input_name"></a> [name](#input\_name) | Name for the conformance pack. | `string` | n/a | yes |
| <a name="input_create_organization_conformance_pack"></a> [create\_organization\_conformance\_pack](#input\_create\_organization\_conformance\_pack) | Set to true to create an aws\_config\_organization\_conformance\_pack instead of<br/>an account-level aws\_config\_conformance\_pack. Requires AWS Organizations and<br/>that AWS Config is enabled in all member accounts. | `bool` | `false` | no |
| <a name="input_delivery_s3_bucket"></a> [delivery\_s3\_bucket](#input\_delivery\_s3\_bucket) | S3 bucket for conformance pack results. Required for organization conformance packs. | `string` | `null` | no |
| <a name="input_delivery_s3_key_prefix"></a> [delivery\_s3\_key\_prefix](#input\_delivery\_s3\_key\_prefix) | S3 key prefix for conformance pack delivery. | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to disable all resources in this module. | `bool` | `true` | no |
| <a name="input_excluded_account_ids"></a> [excluded\_account\_ids](#input\_excluded\_account\_ids) | List of AWS account IDs to exclude from the organization conformance pack. | `list(string)` | `[]` | no |
| <a name="input_input_parameters"></a> [input\_parameters](#input\_input\_parameters) | Map of parameter name to value passed to the conformance pack template. | `map(string)` | `{}` | no |
| <a name="input_template_body"></a> [template\_body](#input\_template\_body) | Inline YAML or JSON template body for the conformance pack.<br/>Exactly one of template\_body or template\_s3\_uri must be provided. | `string` | `null` | no |
| <a name="input_template_s3_uri"></a> [template\_s3\_uri](#input\_template\_s3\_uri) | S3 URI (s3://bucket/key) of the conformance pack template.<br/>Exactly one of template\_body or template\_s3\_uri must be provided. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_conformance_pack_arn"></a> [conformance\_pack\_arn](#output\_conformance\_pack\_arn) | ARN of the account-level conformance pack. Null when create\_organization\_conformance\_pack is true. |
| <a name="output_conformance_pack_id"></a> [conformance\_pack\_id](#output\_conformance\_pack\_id) | ID (name) of the account-level conformance pack. Null when create\_organization\_conformance\_pack is true. |
| <a name="output_organization_conformance_pack_arn"></a> [organization\_conformance\_pack\_arn](#output\_organization\_conformance\_pack\_arn) | ARN of the organization conformance pack. Null when create\_organization\_conformance\_pack is false. |
| <a name="output_organization_conformance_pack_id"></a> [organization\_conformance\_pack\_id](#output\_organization\_conformance\_pack\_id) | ID (name) of the organization conformance pack. Null when create\_organization\_conformance\_pack is false. |
<!-- END_TF_DOCS -->