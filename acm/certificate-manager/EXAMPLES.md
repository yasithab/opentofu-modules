# ACM Certificate Manager Module - Examples

## Basic Usage

Creates a public ACM certificate for a single domain with DNS validation via Route53. The module automatically creates the Route53 validation record and waits for the certificate to become active.

```hcl
module "acm_certificate" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//acm/certificate-manager?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//acm/certificate-manager?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//acm/certificate-manager?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//acm/certificate-manager?depth=1&ref=v2.0.0"

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
