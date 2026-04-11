# Route 53 Zone

Creates public and private AWS Route 53 hosted zones with support for VPC associations, delegation sets, and accelerated recovery.

## Features

- **Public and Private Zones** - Create public hosted zones or private zones associated with one or more VPCs
- **Multiple Zones** - Provision multiple hosted zones in a single module invocation using a map-based configuration
- **Delegation Sets** - Assign reusable delegation sets to zones for consistent name server assignments
- **Multi-VPC Association** - Associate private zones with one or more VPCs for cross-VPC DNS resolution
- **Accelerated Recovery** - Optionally enable accelerated recovery for faster failover
- **Force Destroy** - Set `force_destroy = true` on a zone to allow deleting it even when it contains records (defaults to false for safety)

## Usage

```hcl
module "zone" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/zone?depth=1&ref=master"

  zones = {
    "example.com" = {
      comment = "Production public zone"
    }
    "internal.example.com" = {
      comment = "Private zone"
      vpc = {
        vpc_id     = "vpc-0123456789abcdef0"
        vpc_region = "us-east-1"
      }
    }
  }

  tags = {
    Environment = "production"
  }
}
```


## Examples

## Basic Public Hosted Zone

Create a public Route53 hosted zone for an internet-facing domain.

```hcl
module "zone_public" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/zone?depth=1&ref=master"

  enabled = true

  zones = {
    "example.com" = {
      comment = "Public zone managed by Terraform"
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Private Hosted Zone Attached to a VPC

Create a private hosted zone for internal service discovery, visible only within the specified VPC.

```hcl
module "zone_private" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/zone?depth=1&ref=master"

  enabled = true

  zones = {
    "internal.example.com" = {
      comment = "Private zone for VPC internal resolution"
      vpc = {
        vpc_id     = "vpc-0abc123456def7890"
        vpc_region = "eu-west-1"
      }
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Multiple Zones with Delegation Set

Create several public zones that share the same set of name servers using a reusable delegation set - useful for maintaining consistent NS records across domains.

```hcl
module "zones_multi" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/zone?depth=1&ref=master"

  enabled = true

  zones = {
    "example.com" = {
      comment           = "Primary domain"
      delegation_set_id = "N0123456789ABCDEFGHIJ"
    }
    "example.io" = {
      comment           = "Alternative TLD"
      delegation_set_id = "N0123456789ABCDEFGHIJ"
    }
    "example.co.uk" = {
      comment           = "UK regional domain"
      delegation_set_id = "N0123456789ABCDEFGHIJ"
    }
  }

  tags = {
    Environment = "production"
    ManagedBy   = "platform-team"
  }
}
```

## Private Zone with Multiple VPCs

Associate a private hosted zone with multiple VPCs so that resources across both VPCs can resolve the same internal domain.

```hcl
module "zone_multi_vpc" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/zone?depth=1&ref=master"

  enabled = true

  zones = {
    "services.internal" = {
      comment = "Shared internal zone for multi-VPC resolution"
      vpc = [
        {
          vpc_id     = "vpc-0abc123456def7890"
          vpc_region = "eu-west-1"
        },
        {
          vpc_id     = "vpc-0def987654321fedcb"
          vpc_region = "eu-west-1"
        },
      ]
    }
  }

  tags = {
    Environment = "production"
    Team        = "networking"
  }
}
```
