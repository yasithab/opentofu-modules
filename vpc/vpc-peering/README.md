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
| <a name="input_acceptor_allow_remote_vpc_dns_resolution"></a> [acceptor\_allow\_remote\_vpc\_dns\_resolution](#input\_acceptor\_allow\_remote\_vpc\_dns\_resolution) | Allow acceptor VPC to resolve public DNS hostnames to private IP addresses when queried from instances in the requestor VPC | `bool` | `true` | no |
| <a name="input_acceptor_aws_account_id"></a> [acceptor\_aws\_account\_id](#input\_acceptor\_aws\_account\_id) | The AWS account id of the acceptor | `string` | `null` | no |
| <a name="input_acceptor_aws_region"></a> [acceptor\_aws\_region](#input\_acceptor\_aws\_region) | The AWS account id of the acceptor | `string` | `null` | no |
| <a name="input_acceptor_cidr_blocks"></a> [acceptor\_cidr\_blocks](#input\_acceptor\_cidr\_blocks) | accepter cidr blocks | `list(string)` | `[]` | no |
| <a name="input_acceptor_vpc_id"></a> [acceptor\_vpc\_id](#input\_acceptor\_vpc\_id) | Acceptor VPC ID | `string` | `null` | no |
| <a name="input_create_timeout"></a> [create\_timeout](#input\_create\_timeout) | VPC peering connection create timeout. For more details, see https://www.terraform.io/docs/configuration/resources.html#operation-timeouts | `string` | `"3m"` | no |
| <a name="input_delete_timeout"></a> [delete\_timeout](#input\_delete\_timeout) | VPC peering connection delete timeout. For more details, see https://www.terraform.io/docs/configuration/resources.html#operation-timeouts | `string` | `"5m"` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_requestor_allow_remote_vpc_dns_resolution"></a> [requestor\_allow\_remote\_vpc\_dns\_resolution](#input\_requestor\_allow\_remote\_vpc\_dns\_resolution) | Allow requestor VPC to resolve public DNS hostnames to private IP addresses when queried from instances in the acceptor VPC | `bool` | `true` | no |
| <a name="input_requestor_route_table_tags"></a> [requestor\_route\_table\_tags](#input\_requestor\_route\_table\_tags) | Only add peer routes to requestor VPC route tables matching these tags | `map(string)` | `{}` | no |
| <a name="input_requestor_vpc_id"></a> [requestor\_vpc\_id](#input\_requestor\_vpc\_id) | Requestor VPC ID | `string` | `null` | no |
| <a name="input_requestor_vpc_tags"></a> [requestor\_vpc\_tags](#input\_requestor\_vpc\_tags) | Requestor VPC tags | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_update_timeout"></a> [update\_timeout](#input\_update\_timeout) | VPC peering connection update timeout. For more details, see https://www.terraform.io/docs/configuration/resources.html#operation-timeouts | `string` | `"3m"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_accept_status"></a> [accept\_status](#output\_accept\_status) | The status of the VPC peering connection request |
| <a name="output_connection_id"></a> [connection\_id](#output\_connection\_id) | VPC peering connection ID |
<!-- END_TF_DOCS -->