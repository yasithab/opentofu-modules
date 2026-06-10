# ACM Certificate Manager

Provisions and validates AWS Certificate Manager (ACM) certificates with support for DNS and email validation, Route 53 record creation, certificate imports, and private CA-issued certificates.

## Features

- **DNS and Email Validation** - Automatically creates Route 53 validation records and optionally waits for certificate issuance
- **Subject Alternative Names** - Supports wildcard and multi-domain certificates with distinct SANs
- **Certificate Import** - Import existing certificates by providing private key, certificate body, and chain
- **Private CA Support** - Issue certificates through AWS Private Certificate Authority
- **Cross-Account Validation** - Create Route 53 validation records separately using a different AWS provider
- **Multi-Zone Validation** - Map individual domain names to different Route 53 hosted zones for validation

## Usage

```hcl
module "certificate" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//acm/certificate-manager?depth=1&ref=master"

  domain_name               = "example.com"
  subject_alternative_names = ["*.example.com"]
  validation_method         = "DNS"
  zone_id                   = "Z0123456789ABCDEFGHIJ"

  tags = {
    Environment = "production"
  }
}
```


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11.0 |
| aws | >= 6.49, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| acm\_certificate\_domain\_validation\_options | A list of domain\_validation\_options created by the ACM certificate to create required Route53 records from it (used when create\_route53\_records\_only is set to true) | `any` | `{}` | no |
| certificate\_body | Certificate's PEM-formatted public key. Required when importing an existing certificate. | `string` | `null` | no |
| certificate\_chain | Certificate's PEM-formatted chain. Optional when importing an existing certificate. | `string` | `null` | no |
| certificate\_export | Whether the certificate can be exported. Valid values: ENABLED, DISABLED | `string` | `null` | no |
| certificate\_transparency\_logging\_preference | Specifies whether certificate details should be added to a certificate transparency log | `bool` | `true` | no |
| create\_route53\_records | When validation is set to DNS, define whether to create the DNS records internally via Route53 or externally using any DNS provider | `bool` | `true` | no |
| create\_route53\_records\_only | Whether to create only Route53 records (e.g. using separate AWS provider) | `bool` | `false` | no |
| distinct\_domain\_names | List of distinct domains and SANs (used when create\_route53\_records\_only is set to true) | `list(string)` | `[]` | no |
| dns\_ttl | The TTL of DNS recursive resolvers to cache information about this record. | `number` | `60` | no |
| domain\_name | A domain name for which the certificate should be issued | `string` | `null` | no |
| early\_renewal\_duration | Amount of time to start automatic renewal process before expiration. Represented in RFC3339 duration format (e.g. 2160h = 90 days). | `string` | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| key\_algorithm | Specifies the algorithm of the public and private key pair that your Amazon issued certificate uses to encrypt data | `string` | `null` | no |
| private\_authority\_arn | Private Certificate Authority ARN for issuing private certificates | `string` | `null` | no |
| private\_key | Certificate's PEM-formatted private key. Required when importing an existing certificate. | `string` | `null` | no |
| region | Region to create the resources into | `string` | `null` | no |
| subject\_alternative\_names | A list of domains that should be SANs in the issued certificate | `list(string)` | `[]` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| validate\_certificate | Whether to validate certificate by creating Route53 record | `bool` | `true` | no |
| validation\_allow\_overwrite\_records | Whether to allow overwrite of Route53 records. BREAKING: previously defaulted to true; now defaults to false so existing DNS records are never silently overwritten - set to true explicitly if you rely on overwriting | `bool` | `false` | no |
| validation\_method | Which method to use for validation. DNS, EMAIL or NONE are valid. NONE is used for certificates that were imported into ACM. This parameter must not be set for certificates that were imported into ACM and then into Terraform. | `string` | `null` | no |
| validation\_option | The domain name that you want ACM to use to send you validation emails. This domain name is the suffix of the email addresses that you want ACM to use. The map key is used as the domain\_name when not set explicitly. | <pre>map(object({<br/>    domain_name       = optional(string)<br/>    validation_domain = string<br/>  }))</pre> | `{}` | no |
| validation\_record\_fqdns | When validation is set to DNS and the DNS validation records are set externally, provide the fqdns for the validation | `list(string)` | `[]` | no |
| validation\_timeout | Define maximum timeout to wait for the validation to complete | `string` | `null` | no |
| wait\_for\_validation | Whether to wait for the validation to complete | `bool` | `true` | no |
| zone\_id | The ID of the hosted zone to contain this record. Required when validating via Route53 | `string` | `null` | no |
| zones | Map containing the Route53 Zone IDs for additional domains. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| acm\_certificate\_arn | The ARN of the certificate |
| acm\_certificate\_domain\_validation\_options | A list of attributes to feed into other resources to complete certificate validation. Can have more than one element, e.g. if SANs are defined. Only set if DNS-validation was used. |
| acm\_certificate\_status | Status of the certificate. |
| acm\_certificate\_validation\_emails | A list of addresses that received a validation E-Mail. Only set if EMAIL-validation was used. |
| distinct\_domain\_names | List of distinct domains names used for the validation. |
| validation\_domains | List of distinct domain validation options. This is useful if subject alternative names contain wildcards. |
| validation\_route53\_record\_fqdns | List of FQDNs built using the zone domain and name. |
<!-- END_TF_DOCS -->

## Examples

## Basic Usage

Creates a public ACM certificate for a single domain with DNS validation via Route53. The module automatically creates the Route53 validation record and waits for the certificate to become active.

```hcl
module "acm_certificate" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//acm/certificate-manager?depth=1&ref=master"

  enabled = true

  domain_name       = "api.example.com"
  validation_method = "DNS"
  zone_id           = "Z0123456789ABCDEFGHIJ"

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## With Subject Alternative Names

Issues a certificate that covers multiple subdomains under the same hosted zone.

```hcl
module "acm_certificate_multi_domain" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//acm/certificate-manager?depth=1&ref=master"

  enabled = true

  domain_name = "example.com"
  subject_alternative_names = [
    "www.example.com",
    "api.example.com",
    "admin.example.com",
  ]
  validation_method = "DNS"
  zone_id           = "Z0123456789ABCDEFGHIJ"

  early_renewal_duration = "720h" # 30 days before expiry

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## With Multiple Hosted Zones

Issues a wildcard certificate that spans domains living in different Route53 hosted zones.

```hcl
module "acm_certificate_multi_zone" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//acm/certificate-manager?depth=1&ref=master"

  enabled = true

  domain_name = "example.com"
  subject_alternative_names = [
    "*.example.com",
    "api.internal.example.net",
  ]
  validation_method = "DNS"

  # Map each domain to the correct hosted zone
  zones = {
    "example.com"          = "Z0123456789ABCDEFGHIJ"
    "internal.example.net" = "Z9876543210ZYXWVUTSRQ"
  }

  certificate_transparency_logging_preference = true
  key_algorithm                               = "EC_prime256v1"

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Private Certificate via ACM Private CA

Issues a certificate from an AWS Certificate Manager Private Certificate Authority (PCA) for internal services that should not appear in public certificate transparency logs.

```hcl
module "acm_private_certificate" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//acm/certificate-manager?depth=1&ref=master"

  enabled = true

  domain_name = "internal-service.corp.example.com"
  subject_alternative_names = [
    "grpc.corp.example.com",
  ]

  # Use a private CA - no public DNS validation needed
  validation_method  = "NONE"
  private_authority_arn = "arn:aws:acm-pca:us-east-1:123456789012:certificate-authority/abcd1234-ab12-ab12-ab12-abcd12345678"

  validate_certificate = false
  wait_for_validation  = false

  certificate_transparency_logging_preference = false

  tags = {
    Environment = "production"
    Team        = "platform"
    Visibility  = "internal"
  }
}
```

## Notes

### `validation_allow_overwrite_records` defaults to `false` (security)

Overwriting pre-existing Route53 records with the same name/type can silently hijack DNS
entries managed elsewhere, so the module does not overwrite by default. Set
`validation_allow_overwrite_records = true` explicitly if you depend on overwriting (e.g.
recreating certificates that reuse the same validation records).

### Records-only mode

When `create_route53_records_only = true` with `distinct_domain_names` and
`acm_certificate_domain_validation_options` supplied, `domain_name` can be left `null`.
