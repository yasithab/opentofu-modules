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
| <a name="input_associations"></a> [associations](#input\_associations) | A map of transit gateway attachment IDs to associate with the Transit Gateway route table | <pre>map(object({<br/>    transit_gateway_attachment_id = optional(string)<br/>    replace_existing_association  = optional(bool)<br/>    propagate_route_table         = optional(bool, false)<br/>  }))</pre> | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Controls if resources should be created (it affects almost all resources) | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to use for resource naming and tagging. | `string` | `null` | no |
| <a name="input_routes"></a> [routes](#input\_routes) | A map of Transit Gateway routes to create in the route table | <pre>map(object({<br/>    destination_cidr_block        = string<br/>    blackhole                     = optional(bool, false)<br/>    transit_gateway_attachment_id = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_transit_gateway_id"></a> [transit\_gateway\_id](#input\_transit\_gateway\_id) | The ID of the EC2 Transit Gateway | `string` | `null` | no |
| <a name="input_vpc_routes"></a> [vpc\_routes](#input\_vpc\_routes) | A map of VPC routes to create in the route table provided | <pre>map(object({<br/>    route_table_id              = string<br/>    destination_cidr_block      = optional(string)<br/>    destination_ipv6_cidr_block = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | EC2 Transit Gateway Route Table Amazon Resource Name (ARN) |
| <a name="output_id"></a> [id](#output\_id) | EC2 Transit Gateway Route Table identifier |
<!-- END_TF_DOCS -->