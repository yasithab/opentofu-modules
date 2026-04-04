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
| <a name="input_autoscaling_capacity_providers"></a> [autoscaling\_capacity\_providers](#input\_autoscaling\_capacity\_providers) | Map of autoscaling capacity provider definitions to create for the cluster | `any` | `{}` | no |
| <a name="input_cloudwatch_log_group_class"></a> [cloudwatch\_log\_group\_class](#input\_cloudwatch\_log\_group\_class) | Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT\_ACCESS | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_deletion_protection_enabled"></a> [cloudwatch\_log\_group\_deletion\_protection\_enabled](#input\_cloudwatch\_log\_group\_deletion\_protection\_enabled) | Whether to enable deletion protection on the CloudWatch log group. If enabled, the log group cannot be deleted. | `bool` | `null` | no |
| <a name="input_cloudwatch_log_group_kms_key_id"></a> [cloudwatch\_log\_group\_kms\_key\_id](#input\_cloudwatch\_log\_group\_kms\_key\_id) | If a KMS Key ARN is set, this key will be used to encrypt the corresponding log group. Please be sure that the KMS Key has an appropriate key policy (https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html) | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#input\_cloudwatch\_log\_group\_name) | Custom name of CloudWatch Log Group for ECS cluster | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch\_log\_group\_retention\_in\_days](#input\_cloudwatch\_log\_group\_retention\_in\_days) | Number of days to retain log events | `number` | `60` | no |
| <a name="input_cloudwatch_log_group_skip_destroy"></a> [cloudwatch\_log\_group\_skip\_destroy](#input\_cloudwatch\_log\_group\_skip\_destroy) | Set to true to prevent the log group from being deleted on module destroy. Preserves audit and execute-command logs. | `bool` | `false` | no |
| <a name="input_cloudwatch_log_group_tags"></a> [cloudwatch\_log\_group\_tags](#input\_cloudwatch\_log\_group\_tags) | A map of additional tags to add to the log group created | `map(string)` | `{}` | no |
| <a name="input_cluster_configuration"></a> [cluster\_configuration](#input\_cluster\_configuration) | The execute command configuration for the cluster | `any` | `{}` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the cluster (up to 255 letters, numbers, hyphens, and underscores) | `string` | `null` | no |
| <a name="input_cluster_service_connect_defaults"></a> [cluster\_service\_connect\_defaults](#input\_cluster\_service\_connect\_defaults) | Configures a default Service Connect namespace | `map(string)` | `{}` | no |
| <a name="input_cluster_settings"></a> [cluster\_settings](#input\_cluster\_settings) | List of configuration block(s) with cluster settings. For example, this can be used to enable CloudWatch Container Insights for a cluster | `any` | <pre>[<br/>  {<br/>    "name": "containerInsights",<br/>    "value": "enabled"<br/>  }<br/>]</pre> | no |
| <a name="input_create_cloudwatch_log_group"></a> [create\_cloudwatch\_log\_group](#input\_create\_cloudwatch\_log\_group) | Determines whether a log group is created by this module for the cluster logs. If not, AWS will automatically create one if logging is enabled | `bool` | `true` | no |
| <a name="input_create_node_iam_role"></a> [create\_node\_iam\_role](#input\_create\_node\_iam\_role) | Determines whether the ECS node IAM role and instance profile should be created. Required for EC2 launch type | `bool` | `false` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Determines whether a security group is created for the cluster (used with EC2 launch type) | `bool` | `false` | no |
| <a name="input_create_task_exec_iam_role"></a> [create\_task\_exec\_iam\_role](#input\_create\_task\_exec\_iam\_role) | Determines whether the ECS task definition IAM role should be created | `bool` | `false` | no |
| <a name="input_create_task_exec_policy"></a> [create\_task\_exec\_policy](#input\_create\_task\_exec\_policy) | Determines whether the ECS task definition IAM policy should be created. This includes permissions included in AmazonECSTaskExecutionRolePolicy as well as access to secrets and SSM parameters | `bool` | `true` | no |
| <a name="input_default_capacity_provider_use_fargate"></a> [default\_capacity\_provider\_use\_fargate](#input\_default\_capacity\_provider\_use\_fargate) | Determines whether to use Fargate or autoscaling for default capacity provider strategy | `bool` | `true` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Determines whether resources will be created (affects all resources) | `bool` | `true` | no |
| <a name="input_fargate_capacity_providers"></a> [fargate\_capacity\_providers](#input\_fargate\_capacity\_providers) | Map of Fargate capacity provider definitions to use for the cluster | `any` | `{}` | no |
| <a name="input_node_iam_role_attach_ssm_policy"></a> [node\_iam\_role\_attach\_ssm\_policy](#input\_node\_iam\_role\_attach\_ssm\_policy) | Whether to attach the AmazonSSMManagedInstanceCore policy to the node IAM role, enabling SSM Session Manager on EC2 nodes | `bool` | `true` | no |
| <a name="input_node_iam_role_description"></a> [node\_iam\_role\_description](#input\_node\_iam\_role\_description) | Description of the node IAM role | `string` | `null` | no |
| <a name="input_node_iam_role_name"></a> [node\_iam\_role\_name](#input\_node\_iam\_role\_name) | Name to use on the node IAM role created | `string` | `null` | no |
| <a name="input_node_iam_role_path"></a> [node\_iam\_role\_path](#input\_node\_iam\_role\_path) | IAM role path for the node role | `string` | `null` | no |
| <a name="input_node_iam_role_permissions_boundary"></a> [node\_iam\_role\_permissions\_boundary](#input\_node\_iam\_role\_permissions\_boundary) | ARN of the policy used as permissions boundary for the node IAM role | `string` | `null` | no |
| <a name="input_node_iam_role_policies"></a> [node\_iam\_role\_policies](#input\_node\_iam\_role\_policies) | Map of IAM policy ARNs to attach to the node IAM role in addition to the defaults | `map(string)` | `{}` | no |
| <a name="input_node_iam_role_tags"></a> [node\_iam\_role\_tags](#input\_node\_iam\_role\_tags) | A map of additional tags to add to the node IAM role created | `map(string)` | `{}` | no |
| <a name="input_node_iam_role_use_name_prefix"></a> [node\_iam\_role\_use\_name\_prefix](#input\_node\_iam\_role\_use\_name\_prefix) | Determines whether the node IAM role name is used as a prefix | `bool` | `true` | no |
| <a name="input_security_group_description"></a> [security\_group\_description](#input\_security\_group\_description) | Description of the security group | `string` | `null` | no |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | Name to use on the security group created | `string` | `null` | no |
| <a name="input_security_group_rules"></a> [security\_group\_rules](#input\_security\_group\_rules) | Map of security group rule objects to add to the security group. Keys are rule names, values accept type (ingress/egress), ip\_protocol, from\_port, to\_port, and cidr\_ipv4/cidr\_ipv6/referenced\_security\_group\_id | `any` | `{}` | no |
| <a name="input_security_group_tags"></a> [security\_group\_tags](#input\_security\_group\_tags) | A map of additional tags to add to the security group created | `map(string)` | `{}` | no |
| <a name="input_security_group_use_name_prefix"></a> [security\_group\_use\_name\_prefix](#input\_security\_group\_use\_name\_prefix) | Determines whether the security group name is used as a prefix | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_task_exec_iam_role_description"></a> [task\_exec\_iam\_role\_description](#input\_task\_exec\_iam\_role\_description) | Description of the role | `string` | `null` | no |
| <a name="input_task_exec_iam_role_name"></a> [task\_exec\_iam\_role\_name](#input\_task\_exec\_iam\_role\_name) | Name to use on IAM role created | `string` | `null` | no |
| <a name="input_task_exec_iam_role_path"></a> [task\_exec\_iam\_role\_path](#input\_task\_exec\_iam\_role\_path) | IAM role path | `string` | `null` | no |
| <a name="input_task_exec_iam_role_permissions_boundary"></a> [task\_exec\_iam\_role\_permissions\_boundary](#input\_task\_exec\_iam\_role\_permissions\_boundary) | ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| <a name="input_task_exec_iam_role_policies"></a> [task\_exec\_iam\_role\_policies](#input\_task\_exec\_iam\_role\_policies) | Map of IAM role policy ARNs to attach to the IAM role | `map(string)` | `{}` | no |
| <a name="input_task_exec_iam_role_tags"></a> [task\_exec\_iam\_role\_tags](#input\_task\_exec\_iam\_role\_tags) | A map of additional tags to add to the IAM role created | `map(string)` | `{}` | no |
| <a name="input_task_exec_iam_role_use_name_prefix"></a> [task\_exec\_iam\_role\_use\_name\_prefix](#input\_task\_exec\_iam\_role\_use\_name\_prefix) | Determines whether the IAM role name (`task_exec_iam_role_name`) is used as a prefix | `bool` | `true` | no |
| <a name="input_task_exec_iam_statements"></a> [task\_exec\_iam\_statements](#input\_task\_exec\_iam\_statements) | A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage | `any` | `{}` | no |
| <a name="input_task_exec_secret_arns"></a> [task\_exec\_secret\_arns](#input\_task\_exec\_secret\_arns) | List of SecretsManager secret ARNs the task execution role will be permitted to get/read. Provide specific ARNs instead of wildcards to follow least-privilege | `list(string)` | `[]` | no |
| <a name="input_task_exec_ssm_param_arns"></a> [task\_exec\_ssm\_param\_arns](#input\_task\_exec\_ssm\_param\_arns) | List of SSM parameter ARNs the task execution role will be permitted to get/read. Provide specific ARNs instead of wildcards to follow least-privilege | `list(string)` | `[]` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC where the security group will be created | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | ARN that identifies the cluster |
| <a name="output_autoscaling_capacity_providers"></a> [autoscaling\_capacity\_providers](#output\_autoscaling\_capacity\_providers) | Map of autoscaling capacity providers created and their attributes |
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | ARN of CloudWatch log group created |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | Name of CloudWatch log group created |
| <a name="output_cluster_capacity_providers"></a> [cluster\_capacity\_providers](#output\_cluster\_capacity\_providers) | Map of cluster capacity providers attributes |
| <a name="output_id"></a> [id](#output\_id) | ID that identifies the cluster |
| <a name="output_name"></a> [name](#output\_name) | Name that identifies the cluster |
| <a name="output_node_iam_instance_profile_arn"></a> [node\_iam\_instance\_profile\_arn](#output\_node\_iam\_instance\_profile\_arn) | Node IAM instance profile ARN |
| <a name="output_node_iam_instance_profile_name"></a> [node\_iam\_instance\_profile\_name](#output\_node\_iam\_instance\_profile\_name) | Node IAM instance profile name |
| <a name="output_node_iam_role_arn"></a> [node\_iam\_role\_arn](#output\_node\_iam\_role\_arn) | Node IAM role ARN |
| <a name="output_node_iam_role_name"></a> [node\_iam\_role\_name](#output\_node\_iam\_role\_name) | Node IAM role name |
| <a name="output_node_iam_role_unique_id"></a> [node\_iam\_role\_unique\_id](#output\_node\_iam\_role\_unique\_id) | Stable and unique string identifying the node IAM role |
| <a name="output_security_group_arn"></a> [security\_group\_arn](#output\_security\_group\_arn) | Amazon Resource Name (ARN) of the cluster security group |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the cluster security group |
| <a name="output_task_exec_iam_role_arn"></a> [task\_exec\_iam\_role\_arn](#output\_task\_exec\_iam\_role\_arn) | Task execution IAM role ARN |
| <a name="output_task_exec_iam_role_name"></a> [task\_exec\_iam\_role\_name](#output\_task\_exec\_iam\_role\_name) | Task execution IAM role name |
| <a name="output_task_exec_iam_role_unique_id"></a> [task\_exec\_iam\_role\_unique\_id](#output\_task\_exec\_iam\_role\_unique\_id) | Stable and unique string identifying the task execution IAM role |
<!-- END_TF_DOCS -->