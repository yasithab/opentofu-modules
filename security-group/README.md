# Security Group

Provisions an AWS VPC security group with a minimal, map-based rule interface. Each rule entry fans out internally to one `aws_vpc_security_group_ingress_rule` / `aws_vpc_security_group_egress_rule` per source (per IPv4 CIDR, per IPv6 CIDR, per prefix list ID, referenced security group, or self), giving every rule its own AWS-side rule object with an independent description and lifecycle.

## Features

- **Two core inputs** - `ingress_rules` and `egress_rules`, each a map of rule objects keyed by a user-chosen rule name
- **All source types per rule** - IPv4 CIDRs, IPv6 CIDRs, prefix list IDs, a referenced security group ID, and `self`, freely combinable on a single rule entry
- **Per-source fan-out** - one rule resource per (rule x source) pair with stable composite keys, so adding or removing a single CIDR never churns the others
- **No implicit open egress** - egress is empty by default; open egress must be opted into explicitly
- **Existing security group attach mode** - manage rules on an existing security group by providing `security_group_id`
- **Fixed name or name prefix** - `use_name_prefix` toggles `name_prefix` (create-before-destroy) vs fixed `name`
- **Configurable timeouts** - custom create and delete timeouts for security group operations

## Interface

### Rule object shape

Both `ingress_rules` and `egress_rules` are `map(object({...}))`. All attributes are optional:

| Attribute | Type | Default | Description |
|---|---|---|---|
| `from_port` | `number` | `null` | Start of port range (required unless `ip_protocol = "-1"`) |
| `to_port` | `number` | `null` | End of port range (required unless `ip_protocol = "-1"`) |
| `ip_protocol` | `string` | `"tcp"` | `tcp`, `udp`, `icmp`, `icmpv6`, `-1` (all), or an IANA protocol number |
| `description` | `string` | `null` | Description applied to every rule created from this entry |
| `cidr_ipv4` | `list(string)` | `[]` | IPv4 CIDRs - one rule per CIDR |
| `cidr_ipv6` | `list(string)` | `[]` | IPv6 CIDRs - one rule per CIDR |
| `prefix_list_ids` | `list(string)` | `[]` | Managed prefix list IDs - one rule per ID |
| `referenced_security_group_id` | `string` | `null` | Source/destination security group - one rule |
| `self` | `bool` | `false` | Reference this security group itself - one rule |

Validation enforced by the module:

- Every rule must define **at least one source** (`cidr_ipv4`, `cidr_ipv6`, `prefix_list_ids`, `referenced_security_group_id`, or `self = true`).
- `from_port` and `to_port` are **required** unless `ip_protocol = "-1"`. When `ip_protocol = "-1"`, ports are ignored (AWS does not allow ports on all-traffic rules).

### Resource keys

Each rule entry expands to one rule resource per source with stable composite keys:

| Source | Key |
|---|---|
| IPv4 CIDR | `<rule key>/ipv4/<cidr>` |
| IPv6 CIDR | `<rule key>/ipv6/<cidr>` |
| Prefix list | `<rule key>/pl/<id>` |
| Referenced security group | `<rule key>/sg` |
| Self | `<rule key>/self` |

These keys are also the keys of the `ingress_rule_ids` / `egress_rule_ids` outputs.

### Other variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `enabled` | `bool` | `true` | Whether to create any resources |
| `name` | `string` | `null` | Name used for resource naming and tagging |
| `use_name_prefix` | `bool` | `true` | Use `name_prefix` instead of fixed `name` |
| `description` | `string` | `"Security Group managed by OpenTofu"` | Security group description (changing forces replacement) |
| `vpc_id` | `string` | `null` | VPC to create the security group in |
| `security_group_id` | `string` | `null` | Existing security group to attach rules to (skips creation) |
| `revoke_rules_on_delete` | `bool` | `false` | Revoke all rules before deleting the group (enable for EMR) |
| `create_timeout` / `delete_timeout` | `string` | `"10m"` / `"15m"` | Security group operation timeouts |
| `tags` | `map(string)` | `{}` | Tags merged with `{ ManagedBy = "opentofu" }` onto all resources |

### Outputs

| Output | Description |
|---|---|
| `security_group_id` | ID of the security group |
| `security_group_arn` | ARN of the security group |
| `security_group_name` | Name of the security group |
| `security_group_vpc_id` | VPC ID |
| `security_group_owner_id` | Owner ID |
| `security_group_description` | Description |
| `ingress_rule_ids` | Map of ingress rule IDs keyed by composite key |
| `egress_rule_ids` | Map of egress rule IDs keyed by composite key |
| `ingress_rule_arns` | Map of ingress rule ARNs keyed by composite key |
| `egress_rule_arns` | Map of egress rule ARNs keyed by composite key |

## Usage

```hcl
module "security_group" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//security-group?depth=1&ref=master"

  name        = "my-app"
  description = "Security group for my application"
  vpc_id      = "vpc-0abc123def456789"

  ingress_rules = {
    https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS from VPC"
      cidr_ipv4   = ["10.0.0.0/16"]
    }
  }

  egress_rules = {
    https-anywhere = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS to anywhere"
      cidr_ipv4   = ["0.0.0.0/0"]
    }
  }

  tags = {
    Environment = "production"
  }
}
```

## Examples

### Multi-CIDR fan-out

A single rule entry with multiple CIDRs creates one AWS rule per CIDR. Adding or removing a CIDR only touches that CIDR's rule.

```hcl
module "sg_web" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//security-group?depth=1&ref=master"

  name   = "web-app"
  vpc_id = "vpc-0abc123456def7890"

  ingress_rules = {
    https = {
      from_port   = 443
      to_port     = 443
      description = "HTTPS from office and VPN"
      cidr_ipv4   = ["203.0.113.0/24", "198.51.100.0/24"]
      cidr_ipv6   = ["2001:db8::/48"]
    }
  }
}
```

Creates `https/ipv4/203.0.113.0/24`, `https/ipv4/198.51.100.0/24`, and `https/ipv6/2001:db8::/48`.

### Security-group-referenced rules

```hcl
module "sg_app" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//security-group?depth=1&ref=master"

  name   = "app"
  vpc_id = module.vpc.vpc_id

  ingress_rules = {
    from-alb = {
      from_port                    = 8080
      to_port                      = 8080
      description                  = "App traffic from ALB"
      referenced_security_group_id = module.sg_alb.security_group_id
    }
  }

  egress_rules = {
    to-db = {
      from_port                    = 5432
      to_port                      = 5432
      description                  = "PostgreSQL to database"
      referenced_security_group_id = module.sg_db.security_group_id
    }
  }
}
```

### Prefix lists and self-referencing rules

```hcl
module "sg_cluster" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//security-group?depth=1&ref=master"

  name   = "cluster"
  vpc_id = module.vpc.vpc_id

  ingress_rules = {
    # All traffic between cluster members - protocol "-1" needs no ports
    intra-cluster = {
      ip_protocol = "-1"
      description = "All traffic within the cluster"
      self        = true
    }
  }

  egress_rules = {
    s3 = {
      from_port       = 443
      to_port         = 443
      description     = "HTTPS to S3 gateway endpoint"
      prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
    }
  }
}
```

### Open egress (explicit opt-in)

The module never opens egress implicitly. To allow all outbound traffic:

```hcl
module "sg_worker" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//security-group?depth=1&ref=master"

  name   = "worker"
  vpc_id = module.vpc.vpc_id

  egress_rules = {
    all = {
      ip_protocol = "-1"
      description = "Allow all outbound traffic"
      cidr_ipv4   = ["0.0.0.0/0"]
      cidr_ipv6   = ["::/0"]
    }
  }
}
```

### Manage rules on an existing security group

```hcl
module "sg_rules_only" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//security-group?depth=1&ref=master"

  security_group_id = "sg-0abc123456def7890"

  ingress_rules = {
    ssh-bastion = {
      from_port   = 22
      to_port     = 22
      description = "SSH from bastion subnet"
      cidr_ipv4   = ["10.0.250.0/28"]
    }
  }
}
```
