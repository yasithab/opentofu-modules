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
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_resolver_rule_associations"></a> [resolver\_rule\_associations](#input\_resolver\_rule\_associations) | Map of Route53 Resolver rule associations parameters. Use resolver\_rule\_id to reference an existing rule, or the key must match a resolver\_rules key to use a rule created by this module. | <pre>map(object({<br/>    name             = optional(string)<br/>    vpc_id           = optional(string)<br/>    resolver_rule_id = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_resolver_rules"></a> [resolver\_rules](#input\_resolver\_rules) | Map of Route53 Resolver rules to create | <pre>map(object({<br/>    domain_name          = string<br/>    rule_type            = string<br/>    name                 = optional(string)<br/>    resolver_endpoint_id = optional(string)<br/>    target_ips = optional(list(object({<br/>      ip       = optional(string)<br/>      ipv6     = optional(string)<br/>      port     = optional(number, 53)<br/>      protocol = optional(string, "Do53")<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | Default VPC ID for all the Route53 Resolver rule associations | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_resolver_rule_arns"></a> [resolver\_rule\_arns](#output\_resolver\_rule\_arns) | Map of Route53 Resolver rule ARNs |
| <a name="output_resolver_rule_association_id"></a> [resolver\_rule\_association\_id](#output\_resolver\_rule\_association\_id) | ID of Route53 Resolver rule associations |
| <a name="output_resolver_rule_association_name"></a> [resolver\_rule\_association\_name](#output\_resolver\_rule\_association\_name) | Name of Route53 Resolver rule associations |
| <a name="output_resolver_rule_association_resolver_rule_id"></a> [resolver\_rule\_association\_resolver\_rule\_id](#output\_resolver\_rule\_association\_resolver\_rule\_id) | ID of Route53 Resolver rule associations resolver rule |
| <a name="output_resolver_rule_ids"></a> [resolver\_rule\_ids](#output\_resolver\_rule\_ids) | Map of Route53 Resolver rule IDs |
| <a name="output_resolver_rules"></a> [resolver\_rules](#output\_resolver\_rules) | Map of Route53 Resolver rules created |
<!-- END_TF_DOCS -->