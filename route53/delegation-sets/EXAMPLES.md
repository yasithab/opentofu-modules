# Route53 Delegation Sets Module - Examples

## Basic Usage

Create a single Route53 reusable delegation set to assign a consistent set of name servers across hosted zones.

```hcl
module "delegation_sets" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/delegation-sets?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/delegation-sets?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/delegation-sets?depth=1&ref=v2.0.0"

  enabled = false

  delegation_sets = {
    main = {
      reference_name = "main"
    }
  }
}
```
