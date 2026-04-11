# Managed Prefix List

OpenTofu module for creating and managing AWS EC2 Managed Prefix Lists with optional cross-account sharing via Resource Access Manager (RAM).

## Features

- **Multiple prefix lists** - define several prefix lists in a single module call using a map-based configuration
- **IPv4 and IPv6** - supports both address families via the `address_family` attribute
- **Automatic max entries** - calculates `max_entries` from the provided CIDR list length
- **RAM sharing** - optionally share prefix lists across AWS accounts or an entire AWS Organization using RAM
- **Per-list tags** - apply tags globally and per prefix list for fine-grained resource organization

## Usage

```hcl
module "prefix_list" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//managed-prefix-list?depth=1&ref=master"

  prefix_lists = {
    office_ips = {
      name = "office-egress-cidrs"
      cidr_list = [
        { cidr = "203.0.113.0/24", description = "HQ egress" },
        { cidr = "198.51.100.0/24", description = "Branch office" },
      ]
    }
  }

  tags = {
    Environment = "shared"
  }
}
```


## Examples

## Basic Usage

A single managed prefix list grouping office CIDR ranges.

```hcl
module "office_prefix_list" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//managed-prefix-list?depth=1&ref=master"

  enabled = true

  prefix_lists = {
    office_ips = {
      name           = "office-egress-cidrs"
      address_family = "IPv4"
      cidr_list = [
        { cidr = "203.0.113.0/24", description = "Dubai HQ" },
        { cidr = "198.51.100.0/24", description = "London Office" },
      ]
    }
  }

  tags = {
    Environment = "shared"
    Team        = "network"
  }
}
```

## Multiple Prefix Lists

Multiple prefix lists for different environments defined in a single module call.

```hcl
module "env_prefix_lists" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//managed-prefix-list?depth=1&ref=master"

  enabled = true

  prefix_lists = {
    production_ingress = {
      name           = "prod-allowed-ingress"
      address_family = "IPv4"
      cidr_list = [
        { cidr = "10.0.0.0/8",     description = "Internal VPC ranges" },
        { cidr = "172.16.0.0/12",  description = "Peered VPC ranges" },
      ]
    }
    staging_ingress = {
      name           = "staging-allowed-ingress"
      address_family = "IPv4"
      cidr_list = [
        { cidr = "10.10.0.0/16", description = "Staging VPC" },
        { cidr = "10.20.0.0/16", description = "Dev VPC" },
      ]
    }
  }

  tags = {
    Environment = "shared"
    Team        = "network"
  }
}
```

## With RAM Sharing Across Organisation

Prefix list shared with all accounts in the AWS Organisation via Resource Access Manager.

```hcl
module "shared_prefix_lists" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//managed-prefix-list?depth=1&ref=master"

  enabled = true

  prefix_lists = {
    corporate_networks = {
      name           = "corporate-network-cidrs"
      address_family = "IPv4"
      cidr_list = [
        { cidr = "203.0.113.0/24", description = "HQ egress" },
        { cidr = "198.51.100.0/26", description = "VPN exit" },
      ]
    }
  }

  enable_ram_share              = true
  ram_allow_external_principals = false
  # NOTE: ram_principals must be provided explicitly. Unlike the ram module,
  # this module does NOT automatically fall back to the Organization ARN.
  ram_principals = ["arn:aws:organizations::123456789012:organization/o-aa111bbb22"]

  ram_tags = {
    Purpose = "cross-account-network-sharing"
  }

  tags = {
    Environment = "shared"
    Team        = "network"
  }
}
```

## With RAM Sharing to Specific Accounts

Prefix list shared only with selected AWS account IDs or OUs.

```hcl
module "partner_prefix_list" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//managed-prefix-list?depth=1&ref=master"

  enabled = true

  prefix_lists = {
    partner_cidrs = {
      name           = "partner-api-cidrs"
      address_family = "IPv4"
      cidr_list = [
        { cidr = "192.0.2.0/24",  description = "Partner A egress" },
        { cidr = "192.0.3.0/24",  description = "Partner B egress" },
      ]
    }
  }

  enable_ram_share = true
  ram_principals   = ["111122223333", "444455556666"]

  tags = {
    Environment = "production"
    Team        = "integrations"
  }
}
```
