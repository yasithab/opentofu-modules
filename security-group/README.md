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
| create\_timeout | Time to wait for a security group to be created | `string` | `"10m"` | no |
| delete\_timeout | Time to wait for a security group to be deleted | `string` | `"15m"` | no |
| description | Description of security group. Note: changing the description of an existing security group forces replacement | `string` | `"Security Group managed by OpenTofu"` | no |
| egress\_rules | Map of egress rules keyed by a user-chosen rule name. Each rule fans out to one<br/>aws\_vpc\_security\_group\_egress\_rule per source (per IPv4 CIDR, per IPv6 CIDR, per prefix<br/>list ID, one for the referenced security group, and one for self). Every rule must define<br/>at least one source. When ip\_protocol is "-1" ports are ignored; otherwise from\_port and<br/>to\_port are required. No egress is opened implicitly - open egress must be opted into<br/>explicitly. | <pre>map(object({<br/>    from_port                    = optional(number)<br/>    to_port                      = optional(number)<br/>    ip_protocol                  = optional(string, "tcp")<br/>    description                  = optional(string)<br/>    cidr_ipv4                    = optional(list(string), [])<br/>    cidr_ipv6                    = optional(list(string), [])<br/>    prefix_list_ids              = optional(list(string), [])<br/>    referenced_security_group_id = optional(string)<br/>    self                         = optional(bool, false)<br/>  }))</pre> | `{}` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| ingress\_rules | Map of ingress rules keyed by a user-chosen rule name. Each rule fans out to one<br/>aws\_vpc\_security\_group\_ingress\_rule per source (per IPv4 CIDR, per IPv6 CIDR, per prefix<br/>list ID, one for the referenced security group, and one for self). Every rule must define<br/>at least one source. When ip\_protocol is "-1" ports are ignored; otherwise from\_port and<br/>to\_port are required. | <pre>map(object({<br/>    from_port                    = optional(number)<br/>    to_port                      = optional(number)<br/>    ip_protocol                  = optional(string, "tcp")<br/>    description                  = optional(string)<br/>    cidr_ipv4                    = optional(list(string), [])<br/>    cidr_ipv6                    = optional(list(string), [])<br/>    prefix_list_ids              = optional(list(string), [])<br/>    referenced_security_group_id = optional(string)<br/>    self                         = optional(bool, false)<br/>  }))</pre> | `{}` | no |
| name | Name to use for resource naming and tagging. | `string` | `null` | no |
| revoke\_rules\_on\_delete | Instruct OpenTofu to revoke all of the security group's attached ingress and egress rules before deleting the group itself. Enable for EMR. | `bool` | `false` | no |
| security\_group\_id | ID of an existing security group whose rules this module will manage. When set, no security group is created | `string` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| use\_name\_prefix | Whether to use name\_prefix or fixed name. Should be true to be able to update the security group name after initial creation | `bool` | `true` | no |
| vpc\_id | ID of the VPC where to create security group | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| egress\_rule\_arns | Map of created egress rule ARNs, keyed by composite rule key |
| egress\_rule\_ids | Map of created egress rule IDs, keyed by composite rule key (e.g. "all/ipv4/0.0.0.0/0", "endpoints/pl/pl-12345678") |
| ingress\_rule\_arns | Map of created ingress rule ARNs, keyed by composite rule key |
| ingress\_rule\_ids | Map of created ingress rule IDs, keyed by composite rule key (e.g. "https/ipv4/10.0.0.0/16", "app/sg", "intra/self") |
| security\_group\_arn | The ARN of the security group |
| security\_group\_description | The description of the security group |
| security\_group\_id | The ID of the security group |
| security\_group\_name | The name of the security group |
| security\_group\_owner\_id | The owner ID |
| security\_group\_vpc\_id | The VPC ID |
<!-- END_TF_DOCS -->

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
