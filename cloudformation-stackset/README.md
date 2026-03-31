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
| <a name="input_name"></a> [name](#input\_name) | Name of the StackSet | `string` | n/a | yes |
| <a name="input_administration_role_arn"></a> [administration\_role\_arn](#input\_administration\_role\_arn) | ARN of the IAM role in the administrator account (SELF\_MANAGED only) | `string` | `null` | no |
| <a name="input_auto_deployment_enabled"></a> [auto\_deployment\_enabled](#input\_auto\_deployment\_enabled) | Enable automatic deployment to new accounts in target OUs | `bool` | `true` | no |
| <a name="input_call_as"></a> [call\_as](#input\_call\_as) | Whether acting as account admin or delegated admin | `string` | `"SELF"` | no |
| <a name="input_capabilities"></a> [capabilities](#input\_capabilities) | List of capabilities required by the template | `list(string)` | <pre>[<br/>  "CAPABILITY_NAMED_IAM"<br/>]</pre> | no |
| <a name="input_deployments"></a> [deployments](#input\_deployments) | List of deployment configurations. For SERVICE\_MANAGED:<br/>- organizational\_unit\_ids: List of OU IDs to deploy to<br/>- account\_filter\_type: DIFFERENCE, INTERSECTION, UNION, or NONE<br/>- accounts: Account IDs for filtering<br/>- accounts\_url: S3 URL of the file containing the list of accounts<br/>- region: AWS region for deployment<br/><br/>For SELF\_MANAGED:<br/>- account\_id: Target account ID<br/>- region: AWS region for deployment<br/><br/>Optional:<br/>- parameter\_overrides: Map of parameter key-value pairs to override StackSet-level parameters for this instance<br/>- retain\_stack: If true, retains the stack when the instance is removed (default false) | <pre>list(object({<br/>    region                  = string<br/>    organizational_unit_ids = optional(list(string), [])<br/>    account_filter_type     = optional(string, "NONE")<br/>    accounts                = optional(list(string), [])<br/>    accounts_url            = optional(string)<br/>    account_id              = optional(string)<br/>    parameter_overrides     = optional(map(string))<br/>    retain_stack            = optional(bool, false)<br/>  }))</pre> | `[]` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the StackSet | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_execution_role_name"></a> [execution\_role\_name](#input\_execution\_role\_name) | Name of the IAM role in target accounts (SELF\_MANAGED only) | `string` | `"AWSCloudFormationStackSetExecutionRole"` | no |
| <a name="input_instance_timeouts"></a> [instance\_timeouts](#input\_instance\_timeouts) | Timeout configuration for stack instances | <pre>object({<br/>    create = optional(string, "30m")<br/>    update = optional(string, "30m")<br/>    delete = optional(string, "30m")<br/>  })</pre> | `{}` | no |
| <a name="input_managed_execution_enabled"></a> [managed\_execution\_enabled](#input\_managed\_execution\_enabled) | Enable managed execution for conflict prevention | `bool` | `false` | no |
| <a name="input_operation_preferences"></a> [operation\_preferences](#input\_operation\_preferences) | Preferences for how AWS CloudFormation performs stack operations | <pre>object({<br/>    failure_tolerance_count      = optional(number)<br/>    failure_tolerance_percentage = optional(number)<br/>    max_concurrent_count         = optional(number)<br/>    max_concurrent_percentage    = optional(number)<br/>    concurrency_mode             = optional(string)<br/>    region_concurrency_type      = optional(string, "PARALLEL")<br/>    region_order                 = optional(list(string), [])<br/>  })</pre> | <pre>{<br/>  "failure_tolerance_percentage": 10,<br/>  "max_concurrent_percentage": 25,<br/>  "region_concurrency_type": "PARALLEL",<br/>  "region_order": []<br/>}</pre> | no |
| <a name="input_parameters"></a> [parameters](#input\_parameters) | Map of parameters to pass to the CloudFormation template | `map(string)` | `{}` | no |
| <a name="input_permission_model"></a> [permission\_model](#input\_permission\_model) | Permission model: SERVICE\_MANAGED (uses AWS Organizations) or SELF\_MANAGED | `string` | `"SERVICE_MANAGED"` | no |
| <a name="input_retain_stacks_on_account_removal"></a> [retain\_stacks\_on\_account\_removal](#input\_retain\_stacks\_on\_account\_removal) | Retain stacks when an account is removed from the organization | `bool` | `false` | no |
| <a name="input_stackset_operation_preferences"></a> [stackset\_operation\_preferences](#input\_stackset\_operation\_preferences) | Operation preferences to apply to the StackSet itself (not per-instance). Used for managed StackSet operations. | <pre>object({<br/>    failure_tolerance_count      = optional(number)<br/>    failure_tolerance_percentage = optional(number)<br/>    max_concurrent_count         = optional(number)<br/>    max_concurrent_percentage    = optional(number)<br/>    region_concurrency_type      = optional(string)<br/>    region_order                 = optional(list(string), [])<br/>  })</pre> | `null` | no |
| <a name="input_stackset_update_timeout"></a> [stackset\_update\_timeout](#input\_stackset\_update\_timeout) | Timeout for StackSet update operations (e.g., '30m', '1h') | `string` | `"30m"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the StackSet | `map(string)` | `{}` | no |
| <a name="input_template_body"></a> [template\_body](#input\_template\_body) | CloudFormation template body (mutually exclusive with template\_url) | `string` | `null` | no |
| <a name="input_template_url"></a> [template\_url](#input\_template\_url) | S3 URL for CloudFormation template (mutually exclusive with template\_body) | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instance_ids"></a> [instance\_ids](#output\_instance\_ids) | Map of deployment index to stack instance IDs |
| <a name="output_instance_stack_ids"></a> [instance\_stack\_ids](#output\_instance\_stack\_ids) | Map of deployment index to CloudFormation stack IDs in target accounts |
| <a name="output_stack_set_id"></a> [stack\_set\_id](#output\_stack\_set\_id) | Unique identifier of the StackSet |
| <a name="output_stackset_arn"></a> [stackset\_arn](#output\_stackset\_arn) | ARN of the StackSet |
| <a name="output_stackset_id"></a> [stackset\_id](#output\_stackset\_id) | ID of the StackSet |
| <a name="output_stackset_name"></a> [stackset\_name](#output\_stackset\_name) | Name of the StackSet |
<!-- END_TF_DOCS -->