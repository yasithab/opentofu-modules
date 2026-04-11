# Route 53 Delegation Sets

Creates reusable AWS Route 53 delegation sets that provide a consistent set of name servers across multiple hosted zones.

## Features

- **Reusable Delegation Sets** - Create named delegation sets that can be shared across multiple hosted zones for consistent NS records
- **Bulk Creation** - Define multiple delegation sets in a single module call using a map input
- **Reference Names** - Assign human-readable reference names to delegation sets for identification

## Usage

```hcl
module "delegation_sets" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/delegation-sets?depth=1&ref=master"

  delegation_sets = {
    main = {
      reference_name = "main"
    }
  }
}
```


## Examples

## Basic Usage

Create a single Route53 reusable delegation set to assign a consistent set of name servers across hosted zones.

```hcl
module "delegation_sets" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/delegation-sets?depth=1&ref=master"

  enabled = true

  delegation_sets = {
    main = {
      reference_name = "main"
    }
  }
}
```

## Multiple Delegation Sets

Create separate delegation sets for production and staging environments so that each environment has its own fixed set of name servers.

```hcl
module "delegation_sets" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/delegation-sets?depth=1&ref=master"

  enabled = true

  delegation_sets = {
    production = {
      reference_name = "production"
    }
    staging = {
      reference_name = "staging"
    }
  }
}
```

## Disabled (No Resources Created)

Use `enabled = false` to suppress all resource creation, useful in environments where delegation sets are managed elsewhere.

```hcl
module "delegation_sets" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/delegation-sets?depth=1&ref=master"

  enabled = false

  delegation_sets = {
    main = {
      reference_name = "main"
    }
  }
}
```
