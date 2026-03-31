<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.11.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.38.0 |
| <a name="requirement_cloudinit"></a> [cloudinit](#requirement\_cloudinit) | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.38.0 |
| <a name="provider_cloudinit"></a> [cloudinit](#provider\_cloudinit) | >= 2.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Name for all fck-nat resources. | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Public subnet ID for the fck-nat instance. | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID to deploy fck-nat into. | `string` | n/a | yes |
| <a name="input_additional_security_group_ids"></a> [additional\_security\_group\_ids](#input\_additional\_security\_group\_ids) | Additional security group IDs to attach to the fck-nat ENIs. | `list(string)` | `[]` | no |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | Custom AMI ID. When null the latest fck-nat AL2023 AMI is auto-detected. | `string` | `null` | no |
| <a name="input_attach_ssm_patch_policy"></a> [attach\_ssm\_patch\_policy](#input\_attach\_ssm\_patch\_policy) | Attach SSM Patch Manager permissions to the IAM role (allows automated patching, no interactive access). | `bool` | `true` | no |
| <a name="input_attach_ssm_session_policy"></a> [attach\_ssm\_session\_policy](#input\_attach\_ssm\_session\_policy) | Attach SSM Session Manager permissions to the IAM role (allows interactive shell access). | `bool` | `false` | no |
| <a name="input_cloud_init_parts"></a> [cloud\_init\_parts](#input\_cloud\_init\_parts) | Additional cloud-init parts to append after the fck-nat configuration script. | <pre>list(object({<br/>    content      = string<br/>    content_type = string<br/>  }))</pre> | `[]` | no |
| <a name="input_conntrack_max"></a> [conntrack\_max](#input\_conntrack\_max) | Maximum number of concurrent tracked connections. Higher values use more memory. 0 uses the OS default. | `number` | `0` | no |
| <a name="input_credit_specification"></a> [credit\_specification](#input\_credit\_specification) | CPU credit option for burstable (T-type) instances: 'standard' or 'unlimited'. Null uses the instance default. | `string` | `null` | no |
| <a name="input_ebs_root_volume_size"></a> [ebs\_root\_volume\_size](#input\_ebs\_root\_volume\_size) | Root EBS volume size in GB. | `number` | `8` | no |
| <a name="input_eip_allocation_ids"></a> [eip\_allocation\_ids](#input\_eip\_allocation\_ids) | Elastic IP allocation IDs to associate with fck-nat (max 1). Provides a static outbound IP. | `list(string)` | `[]` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Controls if fck-nat resources should be created. | `bool` | `true` | no |
| <a name="input_encryption"></a> [encryption](#input\_encryption) | Whether to encrypt the root EBS volume. | `bool` | `true` | no |
| <a name="input_ha_mode"></a> [ha\_mode](#input\_ha\_mode) | Use an Auto Scaling Group for automatic instance recovery. | `bool` | `true` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type for fck-nat. Graviton (t4g, c6gn, c7gn) recommended. | `string` | `"t4g.nano"` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | KMS key ID for EBS volume encryption. Uses the default EBS key when null. | `string` | `null` | no |
| <a name="input_local_port_range"></a> [local\_port\_range](#input\_local\_port\_range) | Ephemeral port range as 'min max' (e.g., '1024 65535'). Wider range reduces port exhaustion under high connection rates. Empty string uses the OS default. | `string` | `""` | no |
| <a name="input_route_tables_ids"></a> [route\_tables\_ids](#input\_route\_tables\_ids) | Map of logical name to route table ID. A 0.0.0.0/0 route is created in each. | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_update_route_tables"></a> [update\_route\_tables](#input\_update\_route\_tables) | Whether to create 0.0.0.0/0 routes pointing to the fck-nat ENI in the given route tables. | `bool` | `false` | no |
| <a name="input_use_spot_instances"></a> [use\_spot\_instances](#input\_use\_spot\_instances) | Use spot instances for additional cost savings. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ami_id"></a> [ami\_id](#output\_ami\_id) | Resolved AMI ID |
| <a name="output_autoscaling_group_arn"></a> [autoscaling\_group\_arn](#output\_autoscaling\_group\_arn) | ASG ARN (null in non-HA mode) |
| <a name="output_eni_id"></a> [eni\_id](#output\_eni\_id) | Static ENI ID |
| <a name="output_eni_private_ip"></a> [eni\_private\_ip](#output\_eni\_private\_ip) | Private IP of the static ENI |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | IAM role ARN |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | IAM role name |
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | EC2 instance ID (null in HA mode) |
| <a name="output_instance_profile_arn"></a> [instance\_profile\_arn](#output\_instance\_profile\_arn) | Instance profile ARN |
| <a name="output_launch_template_id"></a> [launch\_template\_id](#output\_launch\_template\_id) | Launch template ID |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | Security group ID |
<!-- END_TF_DOCS -->
