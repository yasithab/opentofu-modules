# Route 53 Resolver Rule Associations

Creates AWS Route 53 Resolver rules and associates them with VPCs to forward DNS queries for specific domains to target IP addresses.

## Features

- **Forward Rules** - Create FORWARD rules that route DNS queries for specific domains to target IP addresses via an outbound resolver endpoint
- **System Rules** - Create SYSTEM rules to override forwarding behavior and resolve domains locally within AWS
- **Rule Associations** - Associate resolver rules with one or more VPCs, supporting both rules created by this module and pre-existing shared rules
- **Multi-Target IPs** - Specify multiple target DNS servers per rule with configurable ports and protocols (Do53, DoH, DoH-FIPS)
- **Cross-Team Sharing** - Reference externally managed resolver rules by ID for association in your VPCs

## Usage

```hcl
module "resolver_rules" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/resolver-rule-associations?depth=1&ref=master"

  vpc_id = "vpc-0abc123456def7890"

  resolver_rules = {
    corp_internal = {
      domain_name          = "corp.internal"
      rule_type            = "FORWARD"
      name                 = "corp-internal"
      resolver_endpoint_id = "rslvr-out-0123456789abcdef0"
      target_ips = [
        { ip = "10.100.0.2", port = 53 },
        { ip = "10.100.0.3", port = 53 },
      ]
    }
  }

  resolver_rule_associations = {
    corp_internal = {}
  }

  tags = {
    Environment = "production"
  }
}
```


## Examples

## Basic Forward Rule

Create a FORWARD resolver rule that routes queries for an on-premises domain to a specific DNS server, and associate it with a VPC.

```hcl
module "resolver_rules" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/resolver-rule-associations?depth=1&ref=master"

  enabled = true
  vpc_id  = "vpc-0abc123456def7890"

  resolver_rules = {
    corp_internal = {
      domain_name          = "corp.internal"
      rule_type            = "FORWARD"
      name                 = "corp-internal"
      resolver_endpoint_id = "rslvr-out-0123456789abcdef0"
      target_ips = [
        { ip = "10.100.0.2", port = 53 },
        { ip = "10.100.0.3", port = 53 },
      ]
    }
  }

  resolver_rule_associations = {
    corp_internal = {}
  }

  tags = {
    Environment = "production"
    Team        = "networking"
  }
}
```

## System Rule - Prevent DNS Leak for Private Domain

Use a SYSTEM rule to ensure a domain resolves locally within AWS rather than being forwarded externally.

```hcl
module "resolver_system_rule" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/resolver-rule-associations?depth=1&ref=master"

  enabled = true
  vpc_id  = "vpc-0abc123456def7890"

  resolver_rules = {
    internal_override = {
      domain_name = "aws.internal"
      rule_type   = "SYSTEM"
      name        = "aws-internal-override"
    }
  }

  resolver_rule_associations = {
    internal_override = {}
  }

  tags = {
    Environment = "production"
  }
}
```

## Associating an Existing Resolver Rule with Multiple VPCs

Associate a pre-existing shared resolver rule (managed by another team) with multiple VPCs across environments.

```hcl
module "resolver_associations_only" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/resolver-rule-associations?depth=1&ref=master"

  enabled = true

  resolver_rule_associations = {
    shared_rule_prod = {
      name             = "shared-corp-prod"
      vpc_id           = "vpc-0abc123456def7890"
      resolver_rule_id = "rslvr-rr-0123456789abcdef0"
    }
    shared_rule_staging = {
      name             = "shared-corp-staging"
      vpc_id           = "vpc-0def987654321fedcb"
      resolver_rule_id = "rslvr-rr-0123456789abcdef0"
    }
  }

  tags = {
    Environment = "multi"
    Team        = "networking"
  }
}
```
