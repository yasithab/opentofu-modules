<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.34 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.34 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_ec2_instance_types"></a> [allowed\_ec2\_instance\_types](#input\_allowed\_ec2\_instance\_types) | EC2 instance types allowed for use | `list(string)` | `[]` | no |
| <a name="input_allowed_regions"></a> [allowed\_regions](#input\_allowed\_regions) | AWS Regions allowed for use | `list(string)` | `[]` | no |
| <a name="input_attach_ous"></a> [attach\_ous](#input\_attach\_ous) | List of OU IDs to attach the tag policies to | `list(string)` | `[]` | no |
| <a name="input_attach_to_org"></a> [attach\_to\_org](#input\_attach\_to\_org) | Whether to attach the tag policy to the organization (set to false if you want to attach to OUs) | `bool` | `false` | no |
| <a name="input_deny_all"></a> [deny\_all](#input\_deny\_all) | If false, create a combined policy. If true, deny all access | `bool` | `false` | no |
| <a name="input_deny_creating_iam_users"></a> [deny\_creating\_iam\_users](#input\_deny\_creating\_iam\_users) | Deny creating IAM users | `bool` | `false` | no |
| <a name="input_deny_deleting_cloudwatch_logs"></a> [deny\_deleting\_cloudwatch\_logs](#input\_deny\_deleting\_cloudwatch\_logs) | Deny deleting CloudWatch logs | `bool` | `false` | no |
| <a name="input_deny_deleting_kms_keys"></a> [deny\_deleting\_kms\_keys](#input\_deny\_deleting\_kms\_keys) | Deny deleting KMS keys | `bool` | `false` | no |
| <a name="input_deny_deleting_route53_zones"></a> [deny\_deleting\_route53\_zones](#input\_deny\_deleting\_route53\_zones) | Deny deleting Route53 zones | `bool` | `false` | no |
| <a name="input_deny_leaving_orgs"></a> [deny\_leaving\_orgs](#input\_deny\_leaving\_orgs) | Deny leaving AWS Organizations | `bool` | `false` | no |
| <a name="input_deny_network_modifications"></a> [deny\_network\_modifications](#input\_deny\_network\_modifications) | Deny modifications to network ACLs and security groups | `bool` | `false` | no |
| <a name="input_deny_root_account"></a> [deny\_root\_account](#input\_deny\_root\_account) | Deny root account access | `bool` | `false` | no |
| <a name="input_deny_s3_bucket_public_access_resources"></a> [deny\_s3\_bucket\_public\_access\_resources](#input\_deny\_s3\_bucket\_public\_access\_resources) | S3 bucket resource ARNs to block public access | `list(string)` | `[]` | no |
| <a name="input_deny_s3_buckets_public_access"></a> [deny\_s3\_buckets\_public\_access](#input\_deny\_s3\_buckets\_public\_access) | Deny S3 buckets public access | `bool` | `false` | no |
| <a name="input_deny_vpc_modifications"></a> [deny\_vpc\_modifications](#input\_deny\_vpc\_modifications) | Deny modifications to VPC configurations | `bool` | `false` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the tag policy | `string` | `null` | no |
| <a name="input_enforce_cloudtrail_logging"></a> [enforce\_cloudtrail\_logging](#input\_enforce\_cloudtrail\_logging) | Enforce continuous CloudTrail logging | `bool` | `false` | no |
| <a name="input_enforce_resource_tagging"></a> [enforce\_resource\_tagging](#input\_enforce\_resource\_tagging) | Enforce tagging on resource creation | `bool` | `false` | no |
| <a name="input_limit_ec2_instance_types"></a> [limit\_ec2\_instance\_types](#input\_limit\_ec2\_instance\_types) | Limit allowed EC2 instance types | `bool` | `false` | no |
| <a name="input_limit_regions"></a> [limit\_regions](#input\_limit\_regions) | Limit allowed AWS regions | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to use for resource naming and tagging. | `string` | `null` | no |
| <a name="input_protect_iam_role_resources"></a> [protect\_iam\_role\_resources](#input\_protect\_iam\_role\_resources) | IAM role resource ARNs to protect | `list(string)` | `[]` | no |
| <a name="input_protect_iam_roles"></a> [protect\_iam\_roles](#input\_protect\_iam\_roles) | Protect IAM roles from modification | `bool` | `false` | no |
| <a name="input_protect_s3_bucket_resources"></a> [protect\_s3\_bucket\_resources](#input\_protect\_s3\_bucket\_resources) | S3 bucket resource ARNs to protect | `list(string)` | `[]` | no |
| <a name="input_protect_s3_buckets"></a> [protect\_s3\_buckets](#input\_protect\_s3\_buckets) | Protect S3 buckets from deletion | `bool` | `false` | no |
| <a name="input_require_mfa"></a> [require\_mfa](#input\_require\_mfa) | Require Multi-Factor Authentication for sensitive actions | `bool` | `false` | no |
| <a name="input_require_s3_encryption"></a> [require\_s3\_encryption](#input\_require\_s3\_encryption) | Require S3 bucket encryption | `bool` | `false` | no |
| <a name="input_required_tag_keys"></a> [required\_tag\_keys](#input\_required\_tag\_keys) | List of tags to enforce on resources | `list(string)` | `[]` | no |
| <a name="input_skip_destroy"></a> [skip\_destroy](#input\_skip\_destroy) | If set to true, the policy will not be deleted when the resource is destroyed. This is useful to prevent accidental deletion of SCPs that are attached to the organization. | `bool` | `false` | no |
| <a name="input_tag_enforcement_actions"></a> [tag\_enforcement\_actions](#input\_tag\_enforcement\_actions) | List of actions to enforce tagging on | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_attached_org_root_id"></a> [attached\_org\_root\_id](#output\_attached\_org\_root\_id) | Organization root ID the policy is attached to if the policy is attached to the root |
| <a name="output_attached_ou_ids"></a> [attached\_ou\_ids](#output\_attached\_ou\_ids) | List of OU IDs the policy is attached to |
| <a name="output_policy_arn"></a> [policy\_arn](#output\_policy\_arn) | The ARN of the created SCP |
| <a name="output_policy_id"></a> [policy\_id](#output\_policy\_id) | ID of the created tag policy |
| <a name="output_policy_type"></a> [policy\_type](#output\_policy\_type) | The type of the policy |
<!-- END_TF_DOCS -->