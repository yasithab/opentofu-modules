# ACM

AWS Certificate Manager (ACM) modules for provisioning, validating, and managing SSL/TLS certificates.

## Submodules

| Submodule | Description |
|-----------|-------------|
| [certificate-manager](certificate-manager/) | Provisions and validates ACM certificates with DNS/email validation, certificate imports, and Private CA support |

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
