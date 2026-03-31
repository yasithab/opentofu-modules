<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.11.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.37.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.37.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_account_id"></a> [admin\_account\_id](#input\_admin\_account\_id) | AWS account ID to associate as the FMS administrator. Defaults to the current account when null. | `string` | `null` | no |
| <a name="input_associate_admin_account"></a> [associate\_admin\_account](#input\_associate\_admin\_account) | Whether to associate an AWS account as the FMS administrator account. | `bool` | `false` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_firehose_arn"></a> [firehose\_arn](#input\_firehose\_arn) | ARN of the Kinesis Firehose delivery stream for WAF logging (used when firehose\_enabled is false). | `string` | `null` | no |
| <a name="input_firehose_enabled"></a> [firehose\_enabled](#input\_firehose\_enabled) | Whether to use firehose\_kinesis\_id instead of firehose\_arn for WAF logging configuration. | `bool` | `false` | no |
| <a name="input_firehose_kinesis_id"></a> [firehose\_kinesis\_id](#input\_firehose\_kinesis\_id) | Kinesis Firehose stream ID for WAF logging (used when firehose\_enabled is true). | `string` | `null` | no |
| <a name="input_logging_configuration_enabled"></a> [logging\_configuration\_enabled](#input\_logging\_configuration\_enabled) | Whether to enable WAF logging configuration in the managed\_service\_data. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_waf_v2_policies"></a> [waf\_v2\_policies](#input\_waf\_v2\_policies) | List of WAFv2 FMS policy configurations. Each entry supports:<br/><br/>name:<br/>  The friendly name of the AWS Firewall Manager Policy.<br/>description:<br/>  Optional description for the policy.<br/>delete\_all\_policy\_resources:<br/>  Whether to perform a clean-up process when the policy is deleted.<br/>  Defaults to true.<br/>delete\_unused\_fm\_managed\_resources:<br/>  Whether to delete unused FM managed resources.<br/>  Defaults to false.<br/>exclude\_resource\_tags:<br/>  If true, resources with the specified resource\_tags are NOT protected.<br/>  If false, resources WITH the tags are protected.<br/>  Defaults to false.<br/>remediation\_enabled:<br/>  Whether the policy should automatically apply to resources that already exist.<br/>  Defaults to false.<br/>resource\_type\_list:<br/>  List of resource types to protect. Conflicts with resource\_type.<br/>resource\_type:<br/>  A single resource type to protect. Conflicts with resource\_type\_list.<br/>resource\_tags:<br/>  Map of resource tags used to filter protected resources based on exclude\_resource\_tags.<br/>include\_account\_ids:<br/>  List of AWS Organization member account IDs to include for this policy.<br/>include\_orgunit\_ids:<br/>  List of AWS Organizational Unit IDs to include for this policy.<br/>exclude\_account\_ids:<br/>  List of AWS Organization member account IDs to exclude from this policy.<br/>exclude\_orgunit\_ids:<br/>  List of AWS Organizational Unit IDs to exclude from this policy.<br/>tags:<br/>  Map of additional tags to apply to this specific policy.<br/>policy\_data:<br/>  default\_action:<br/>    The action AWS WAF should take. Values: ALLOW, BLOCK, or COUNT.<br/>  override\_customer\_web\_acl\_association:<br/>    Whether to override customer Web ACL association. Defaults to false.<br/>  logging\_configuration:<br/>    WAFv2 Web ACL logging configuration JSON. Overrides module-level logging config.<br/>  pre\_process\_rule\_groups:<br/>    List of pre-process rule groups.<br/>  post\_process\_rule\_groups:<br/>    List of post-process rule groups.<br/>  custom\_request\_handling:<br/>    Custom header for custom request handling. Defaults to null.<br/>  custom\_response:<br/>    Custom response for the web request. Defaults to null.<br/>  sampled\_requests\_enabled\_for\_default\_actions:<br/>    Whether WAF should store a sampling of web requests that match rules.<br/>  token\_domains:<br/>    List of token domains for the Web ACL.<br/>  web\_acl\_source:<br/>    Source of the Web ACL configuration.<br/>  optimize\_unassociated\_web\_acl:<br/>    Whether to optimize unassociated Web ACLs. Defaults to false. | `list(any)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_account_id"></a> [admin\_account\_id](#output\_admin\_account\_id) | AWS account ID of the FMS administrator account. |
| <a name="output_waf_v2_policy_arns"></a> [waf\_v2\_policy\_arns](#output\_waf\_v2\_policy\_arns) | Map of WAFv2 policy names to their ARNs. |
| <a name="output_waf_v2_policy_ids"></a> [waf\_v2\_policy\_ids](#output\_waf\_v2\_policy\_ids) | Map of WAFv2 policy names to their IDs. |
<!-- END_TF_DOCS -->