# Route 53

AWS Route 53 modules for managing DNS zones, records, delegation sets, resolver endpoints, and resolver rule associations.

## Submodules

| Submodule | Description |
|-----------|-------------|
| [zone](zone/) | Creates public and private Route 53 hosted zones with VPC associations and delegation set support |
| [records](records/) | Manages DNS records with support for alias, failover, latency, weighted, geolocation, geoproximity, and CIDR routing policies, plus health checks |
| [delegation-sets](delegation-sets/) | Creates reusable Route 53 delegation sets for consistent name server assignments across zones |
| [resolver-endpoints](resolver-endpoints/) | Provisions Route 53 Resolver endpoints (inbound, outbound, bidirectional) with security group management |
| [resolver-rule-associations](resolver-rule-associations/) | Creates Route 53 Resolver rules and associates them with VPCs for hybrid DNS forwarding |

## Usage

```hcl
module "zone" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/zone?depth=1&ref=master"

  zones = {
    "example.com" = {
      comment = "Production zone"
    }
  }

  tags = {
    Environment = "production"
  }
}

module "records" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/records?depth=1&ref=master"

  zone_id = module.zone.zone_id["example.com"]

  records = [
    {
      name    = "www"
      type    = "A"
      ttl     = 300
      records = ["1.2.3.4"]
    }
  ]
}
```
