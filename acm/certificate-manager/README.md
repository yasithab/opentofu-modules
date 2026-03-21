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
| <a name="input_acm_certificate_domain_validation_options"></a> [acm\_certificate\_domain\_validation\_options](#input\_acm\_certificate\_domain\_validation\_options) | A list of domain\_validation\_options created by the ACM certificate to create required Route53 records from it (used when create\_route53\_records\_only is set to true) | `any` | `{}` | no |
| <a name="input_certificate_body"></a> [certificate\_body](#input\_certificate\_body) | Certificate's PEM-formatted public key. Required when importing an existing certificate. | `string` | `null` | no |
| <a name="input_certificate_chain"></a> [certificate\_chain](#input\_certificate\_chain) | Certificate's PEM-formatted chain. Optional when importing an existing certificate. | `string` | `null` | no |
| <a name="input_certificate_export"></a> [certificate\_export](#input\_certificate\_export) | Whether the certificate can be exported. Valid values: ENABLED, DISABLED | `string` | `null` | no |
| <a name="input_certificate_transparency_logging_preference"></a> [certificate\_transparency\_logging\_preference](#input\_certificate\_transparency\_logging\_preference) | Specifies whether certificate details should be added to a certificate transparency log | `bool` | `true` | no |
| <a name="input_create_route53_records"></a> [create\_route53\_records](#input\_create\_route53\_records) | When validation is set to DNS, define whether to create the DNS records internally via Route53 or externally using any DNS provider | `bool` | `true` | no |
| <a name="input_create_route53_records_only"></a> [create\_route53\_records\_only](#input\_create\_route53\_records\_only) | Whether to create only Route53 records (e.g. using separate AWS provider) | `bool` | `false` | no |
| <a name="input_distinct_domain_names"></a> [distinct\_domain\_names](#input\_distinct\_domain\_names) | List of distinct domains and SANs (used when create\_route53\_records\_only is set to true) | `list(string)` | `[]` | no |
| <a name="input_dns_ttl"></a> [dns\_ttl](#input\_dns\_ttl) | The TTL of DNS recursive resolvers to cache information about this record. | `number` | `60` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | A domain name for which the certificate should be issued | `string` | `null` | no |
| <a name="input_early_renewal_duration"></a> [early\_renewal\_duration](#input\_early\_renewal\_duration) | Amount of time to start automatic renewal process before expiration. Represented in RFC3339 duration format (e.g. 2160h = 90 days). | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create ACM certificate | `bool` | `true` | no |
| <a name="input_key_algorithm"></a> [key\_algorithm](#input\_key\_algorithm) | Specifies the algorithm of the public and private key pair that your Amazon issued certificate uses to encrypt data | `string` | `null` | no |
| <a name="input_private_authority_arn"></a> [private\_authority\_arn](#input\_private\_authority\_arn) | Private Certificate Authority ARN for issuing private certificates | `string` | `null` | no |
| <a name="input_private_key"></a> [private\_key](#input\_private\_key) | Certificate's PEM-formatted private key. Required when importing an existing certificate. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Region to create the resources into | `string` | `null` | no |
| <a name="input_subject_alternative_names"></a> [subject\_alternative\_names](#input\_subject\_alternative\_names) | A list of domains that should be SANs in the issued certificate | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource | `map(string)` | `{}` | no |
| <a name="input_validate_certificate"></a> [validate\_certificate](#input\_validate\_certificate) | Whether to validate certificate by creating Route53 record | `bool` | `true` | no |
| <a name="input_validation_allow_overwrite_records"></a> [validation\_allow\_overwrite\_records](#input\_validation\_allow\_overwrite\_records) | Whether to allow overwrite of Route53 records | `bool` | `true` | no |
| <a name="input_validation_method"></a> [validation\_method](#input\_validation\_method) | Which method to use for validation. DNS, EMAIL or NONE are valid. NONE is used for certificates that were imported into ACM. This parameter must not be set for certificates that were imported into ACM and then into Terraform. | `string` | `null` | no |
| <a name="input_validation_option"></a> [validation\_option](#input\_validation\_option) | The domain name that you want ACM to use to send you validation emails. This domain name is the suffix of the email addresses that you want ACM to use. | `any` | `{}` | no |
| <a name="input_validation_record_fqdns"></a> [validation\_record\_fqdns](#input\_validation\_record\_fqdns) | When validation is set to DNS and the DNS validation records are set externally, provide the fqdns for the validation | `list(string)` | `[]` | no |
| <a name="input_validation_timeout"></a> [validation\_timeout](#input\_validation\_timeout) | Define maximum timeout to wait for the validation to complete | `string` | `null` | no |
| <a name="input_wait_for_validation"></a> [wait\_for\_validation](#input\_wait\_for\_validation) | Whether to wait for the validation to complete | `bool` | `true` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | The ID of the hosted zone to contain this record. Required when validating via Route53 | `string` | `null` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | Map containing the Route53 Zone IDs for additional domains. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_acm_certificate_arn"></a> [acm\_certificate\_arn](#output\_acm\_certificate\_arn) | The ARN of the certificate |
| <a name="output_acm_certificate_domain_validation_options"></a> [acm\_certificate\_domain\_validation\_options](#output\_acm\_certificate\_domain\_validation\_options) | A list of attributes to feed into other resources to complete certificate validation. Can have more than one element, e.g. if SANs are defined. Only set if DNS-validation was used. |
| <a name="output_acm_certificate_status"></a> [acm\_certificate\_status](#output\_acm\_certificate\_status) | Status of the certificate. |
| <a name="output_acm_certificate_validation_emails"></a> [acm\_certificate\_validation\_emails](#output\_acm\_certificate\_validation\_emails) | A list of addresses that received a validation E-Mail. Only set if EMAIL-validation was used. |
| <a name="output_distinct_domain_names"></a> [distinct\_domain\_names](#output\_distinct\_domain\_names) | List of distinct domains names used for the validation. |
| <a name="output_validation_domains"></a> [validation\_domains](#output\_validation\_domains) | List of distinct domain validation options. This is useful if subject alternative names contain wildcards. |
| <a name="output_validation_route53_record_fqdns"></a> [validation\_route53\_record\_fqdns](#output\_validation\_route53\_record\_fqdns) | List of FQDNs built using the zone domain and name. |
<!-- END_TF_DOCS -->