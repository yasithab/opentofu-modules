# Headscale Subnet Router

Standalone Tailscale subnet router that connects to a Headscale coordination server and advertises local VPC routes to the tailnet.

Deploy this in any VPC/account to give all tailnet clients access to that VPC's resources - without VPC peering, Transit Gateway, or VPN.

## Features

- **Self-healing** - ASG (min=1, max=1) automatically replaces failed instances
- **Stateless** - no persistent data, re-registers with Headscale on every boot
- **Spot instances** - optional, ~70% cheaper (safe because stateless)
- **Private subnet** - no public IP needed, connects outbound to Headscale via NAT
- **Exit node** - optionally route ALL client traffic through this instance
- **CloudWatch alarm** - alerts when instance is unhealthy
- **CloudWatch Logs** - setup logs exported automatically
- **SSM access** - no SSH keys needed

## Usage

```hcl
module "subnet_router" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//headscale/subnet-router?depth=1&ref=master"

  name      = "staging-subnet-router"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.private_subnets[0]

  headscale_server_url = "https://headscale.example.com"
  advertise_routes     = ["10.20.0.0/16"]
  secrets_manager_arn  = aws_secretsmanager_secret.headscale.arn
  use_spot_instances   = true

  tags = { Environment = "staging" }
}
```

After deployment, approve the routes on the Headscale server:

```bash
headscale routes list
headscale routes enable --route <id>
```


## Examples

## Basic  - route a VPC to the tailnet

```hcl
module "subnet_router" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//headscale/subnet-router?depth=1&ref=master"

  name      = "staging-subnet-router"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.private_subnets[0]

  headscale_server_url = "https://headscale.example.com"
  headscale_auth_key   = var.headscale_auth_key
  advertise_routes     = ["10.20.0.0/16"]

  tags = { Environment = "staging" }
}
```

## Multiple CIDRs

```hcl
module "subnet_router" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//headscale/subnet-router?depth=1&ref=master"

  name      = "prod-subnet-router"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.private_subnets[0]

  headscale_server_url = "https://headscale.example.com"
  headscale_auth_key   = var.headscale_auth_key
  advertise_routes     = ["10.30.0.0/16", "172.16.0.0/12"]
  hostname             = "prod-vpc-router"

  tags = { Environment = "production" }
}
```

## Cross-account deployment

```hcl
# Deploy in a different AWS account using a provider alias
module "dr_subnet_router" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//headscale/subnet-router?depth=1&ref=master"
  providers = { aws = aws.dr_account }

  name      = "dr-subnet-router"
  vpc_id    = module.dr_vpc.vpc_id
  subnet_id = module.dr_vpc.private_subnets[0]

  headscale_server_url = "https://headscale.example.com"
  headscale_auth_key   = var.dr_headscale_auth_key
  advertise_routes     = ["10.254.0.0/16"]
  hostname             = "dr-vpc-router"

  tags = { Environment = "dr" }
}
```

## After deployment

Routes must be approved on the Headscale server:

```bash
# List pending routes
headscale routes list

# Enable a route
headscale routes enable --route <id>

# Verify from a client
tailscale status
tailscale ping <subnet-router-hostname>
```
