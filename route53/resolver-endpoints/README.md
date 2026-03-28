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
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Whether to create Security Groups for Route53 Resolver Endpoints | `bool` | `true` | no |
| <a name="input_direction"></a> [direction](#input\_direction) | The resolver endpoint flow direction. Valid values are INBOUND, OUTBOUND, or BIDIRECTIONAL. | `string` | `"INBOUND"` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_ip_addresses"></a> [ip\_addresses](#input\_ip\_addresses) | A list of IP address configurations for the resolver endpoint. Each entry requires subnet\_id and optionally ip (IPv4) or ipv6. | <pre>list(object({<br/>    subnet_id = string<br/>    ip        = optional(string)<br/>    ipv6      = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to use for resource naming and tagging. | `string` | `null` | no |
| <a name="input_protocols"></a> [protocols](#input\_protocols) | The resolver endpoint protocols. Valid values are DoH, Do53, DoH-FIPS. | `list(string)` | <pre>[<br/>  "Do53"<br/>]</pre> | no |
| <a name="input_rni_enhanced_metrics_enabled"></a> [rni\_enhanced\_metrics\_enabled](#input\_rni\_enhanced\_metrics\_enabled) | (Optional) Specifies whether Resolver Query Logging enhanced metrics are enabled for the resolver endpoint. Default is false. | `bool` | `false` | no |
| <a name="input_security_group_description"></a> [security\_group\_description](#input\_security\_group\_description) | The security group description | `string` | `null` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | A list of security group IDs | `list(string)` | `[]` | no |
| <a name="input_security_group_ingress_cidr_blocks"></a> [security\_group\_ingress\_cidr\_blocks](#input\_security\_group\_ingress\_cidr\_blocks) | A list of CIDR blocks to allow on security group | `list(string)` | `[]` | no |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | The name of the security group | `string` | `null` | no |
| <a name="input_security_group_name_prefix"></a> [security\_group\_name\_prefix](#input\_security\_group\_name\_prefix) | The prefix of the security group | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_target_name_server_metrics_enabled"></a> [target\_name\_server\_metrics\_enabled](#input\_target\_name\_server\_metrics\_enabled) | (Optional) Specifies whether target name server metrics are enabled for outbound resolver endpoints. Default is false. | `bool` | `false` | no |
| <a name="input_type"></a> [type](#input\_type) | The resolver endpoint IP address type. Valid values are IPV4, IPV6, or DUALSTACK. | `string` | `"IPV4"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC ID for all the Route53 Resolver Endpoints | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_resolver_endpoint_arn"></a> [resolver\_endpoint\_arn](#output\_resolver\_endpoint\_arn) | The ARN of the Resolver Endpoint |
| <a name="output_resolver_endpoint_host_vpc_id"></a> [resolver\_endpoint\_host\_vpc\_id](#output\_resolver\_endpoint\_host\_vpc\_id) | The VPC ID used by the Resolver Endpoint |
| <a name="output_resolver_endpoint_id"></a> [resolver\_endpoint\_id](#output\_resolver\_endpoint\_id) | The ID of the Resolver Endpoint |
| <a name="output_resolver_endpoint_ip_addresses"></a> [resolver\_endpoint\_ip\_addresses](#output\_resolver\_endpoint\_ip\_addresses) | Resolver Endpoint IP Addresses |
| <a name="output_resolver_endpoint_security_group_ids"></a> [resolver\_endpoint\_security\_group\_ids](#output\_resolver\_endpoint\_security\_group\_ids) | Security Group IDs mapped to Resolver Endpoint |
<!-- END_TF_DOCS -->