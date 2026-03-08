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
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to use for resource naming and tagging. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_attachments"></a> [vpc\_attachments](#input\_vpc\_attachments) | Map of VPC attachment configurations. Each entry requires tgw\_id, vpc\_id, and subnet\_ids. | <pre>map(object({<br/>    tgw_id                                          = string<br/>    vpc_id                                          = string<br/>    subnet_ids                                      = list(string)<br/>    dns_support                                     = optional(bool, true)<br/>    ipv6_support                                    = optional(bool, false)<br/>    appliance_mode_support                          = optional(bool, false)<br/>    security_group_referencing_support              = optional(bool, false)<br/>    transit_gateway_default_route_table_association = optional(bool, true)<br/>    transit_gateway_default_route_table_propagation = optional(bool, true)<br/>    tags                                            = optional(map(string), {})<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ec2_transit_gateway_vpc_attachment"></a> [ec2\_transit\_gateway\_vpc\_attachment](#output\_ec2\_transit\_gateway\_vpc\_attachment) | Map of EC2 Transit Gateway VPC Attachment attributes |
| <a name="output_ec2_transit_gateway_vpc_attachment_ids"></a> [ec2\_transit\_gateway\_vpc\_attachment\_ids](#output\_ec2\_transit\_gateway\_vpc\_attachment\_ids) | List of EC2 Transit Gateway VPC Attachment identifiers |
<!-- END_TF_DOCS -->