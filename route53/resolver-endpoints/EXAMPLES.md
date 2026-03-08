# Route53 Resolver Endpoints Module - Examples

## Basic Inbound Endpoint

Create an inbound Route53 Resolver endpoint so that on-premises DNS servers can forward queries to AWS.

```hcl
module "resolver_inbound" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/resolver-endpoints?depth=1&ref=v2.0.0"

  enabled = true
  name    = "corp-inbound"

  direction = "INBOUND"
  vpc_id    = "vpc-0abc123456def7890"

  ip_addresses = [
    { subnet_id = "subnet-0aaaa111111111111" },
    { subnet_id = "subnet-0bbbb222222222222" },
  ]

  security_group_ingress_cidr_blocks = ["10.0.0.0/8"]

  tags = {
    Environment = "production"
    Team        = "networking"
  }
}
```

## Outbound Endpoint

Create an outbound resolver endpoint that forwards DNS queries from VPC workloads to on-premises name servers.

```hcl
module "resolver_outbound" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/resolver-endpoints?depth=1&ref=v2.0.0"

  enabled = true
  name    = "corp-outbound"

  direction = "OUTBOUND"
  vpc_id    = "vpc-0abc123456def7890"

  ip_addresses = [
    { subnet_id = "subnet-0aaaa111111111111" },
    { subnet_id = "subnet-0bbbb222222222222" },
  ]

  security_group_ingress_cidr_blocks = ["10.0.0.0/8"]

  tags = {
    Environment = "production"
    Team        = "networking"
  }
}
```

## Bidirectional Endpoint with Static IPs

Create a bidirectional endpoint with pinned IP addresses for deterministic on-premises firewall rules.

```hcl
module "resolver_bidirectional" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/resolver-endpoints?depth=1&ref=v2.0.0"

  enabled = true
  name    = "hybrid-dns"

  direction = "BIDIRECTIONAL"
  vpc_id    = "vpc-0abc123456def7890"

  ip_addresses = [
    {
      subnet_id = "subnet-0aaaa111111111111"
      ip        = "10.0.1.10"
    },
    {
      subnet_id = "subnet-0bbbb222222222222"
      ip        = "10.0.2.10"
    },
  ]

  security_group_ingress_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12"]

  rni_enhanced_metrics_enabled       = true
  target_name_server_metrics_enabled = true

  tags = {
    Environment = "production"
    Team        = "networking"
  }
}
```

## Using Pre-existing Security Group

Attach an existing security group instead of creating one, useful when the SG lifecycle is managed separately.

```hcl
module "resolver_existing_sg" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/resolver-endpoints?depth=1&ref=v2.0.0"

  enabled = true
  name    = "corp-inbound-shared"

  direction            = "INBOUND"
  vpc_id               = "vpc-0abc123456def7890"
  create_security_group = false
  security_group_ids   = ["sg-0123456789abcdef0"]

  ip_addresses = [
    { subnet_id = "subnet-0aaaa111111111111" },
    { subnet_id = "subnet-0bbbb222222222222" },
  ]

  tags = {
    Environment = "staging"
    Team        = "networking"
  }
}
```
