# VPC

Provisions a fully-featured AWS VPC with public, private, database, elasticache, redshift, intra, and outpost subnets, along with NAT gateways, internet gateways, route tables, network ACLs, VPN gateways, customer gateways, flow logs, and DHCP options.

## Features

- **Multi-Tier Subnets** - Creates public, private, database, elasticache, redshift, intra, and outpost subnet tiers across multiple availability zones
- **NAT Gateways** - Supports single, per-AZ, and regional NAT gateway configurations with optional reuse of existing Elastic IPs
- **IPv6 Support** - Full IPv6 support including Amazon-provided and IPAM-allocated CIDR blocks with egress-only internet gateway
- **Network ACLs** - Configurable dedicated network ACLs for each subnet tier with custom inbound and outbound rules
- **VPN and Customer Gateways** - Optionally provisions VPN gateways and customer gateways for hybrid connectivity
- **Flow Logs** - VPC flow logs with support for CloudWatch Logs, S3, and cross-account delivery destinations
- **Block Public Access** - VPC-level block public access options and per-subnet exclusions
- **Subnet Groups** - Automatically creates RDS, ElastiCache, and Redshift subnet groups for database subnet tiers

## Submodules

| Submodule | Description |
|-----------|-------------|
| [vpc-endpoints](vpc-endpoints/) | Creates VPC Interface and Gateway endpoints with optional security groups |
| [vpc-peering](vpc-peering/) | Establishes VPC peering connections with automatic route creation |

## Usage

```hcl
module "vpc" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpc?depth=1&ref=master"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
  azs  = ["us-east-1a", "us-east-1b", "us-east-1c"]

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = "production"
  }
}
```


## Examples

## Basic Usage

Create a simple VPC with public and private subnets across three AZs.

```hcl
module "vpc" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpc?depth=1&ref=master"

  enabled = true
  name    = "app-vpc"

  cidr = "10.10.0.0/16"
  azs  = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]

  public_subnets  = ["10.10.0.0/24", "10.10.1.0/24", "10.10.2.0/24"]
  private_subnets = ["10.10.10.0/24", "10.10.11.0/24", "10.10.12.0/24"]

  enable_nat_gateway = true
  nat_gateway_type   = "single"

  tags = {
    Team        = "platform"
    Environment = "production"
    ManagedBy   = "opentofu"
  }
}
```

## With NAT Gateways Per AZ and Database Subnets

Production-grade VPC with one NAT Gateway per AZ for high availability, plus isolated database subnets.

```hcl
module "vpc" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpc?depth=1&ref=master"

  enabled = true
  name    = "production-vpc"

  cidr = "10.20.0.0/16"
  azs  = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  public_subnets   = ["10.20.0.0/24", "10.20.1.0/24", "10.20.2.0/24"]
  private_subnets  = ["10.20.10.0/24", "10.20.11.0/24", "10.20.12.0/24"]
  database_subnets = ["10.20.20.0/24", "10.20.21.0/24", "10.20.22.0/24"]

  enable_nat_gateway = true
  nat_gateway_type   = "multi_az"

  create_database_subnet_group       = true
  create_database_subnet_route_table = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Team        = "platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## With VPN Gateway and Custom DHCP Options

Attach a Virtual Private Gateway for VPN connectivity and set custom DHCP options for a corporate domain.

```hcl
module "vpc" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpc?depth=1&ref=master"

  enabled = true
  name    = "hybrid-vpc"

  cidr = "172.16.0.0/16"
  azs  = ["us-east-1a", "us-east-1b", "us-east-1c"]

  public_subnets  = ["172.16.0.0/24", "172.16.1.0/24", "172.16.2.0/24"]
  private_subnets = ["172.16.10.0/24", "172.16.11.0/24", "172.16.12.0/24"]

  enable_nat_gateway = true
  nat_gateway_type   = "single"

  enable_vpn_gateway = true

  enable_dhcp_options              = true
  dhcp_options_domain_name         = "corp.example.com"
  dhcp_options_domain_name_servers = ["10.0.0.2", "AmazonProvidedDNS"]

  tags = {
    Team        = "platform"
    Environment = "staging"
    ManagedBy   = "terraform"
  }
}
```

## With Regional NAT Gateway

Managed regional NAT gateway with automatic cross-AZ high availability. No EIP or public subnet required - AWS handles failover transparently. Creates a single private route table.

```hcl
module "vpc" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpc?depth=1&ref=master"

  enabled = true
  name    = "regional-nat-vpc"

  cidr = "10.40.0.0/16"
  azs  = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]

  public_subnets   = ["10.40.0.0/24", "10.40.1.0/24", "10.40.2.0/24"]
  private_subnets  = ["10.40.10.0/24", "10.40.11.0/24", "10.40.12.0/24"]
  database_subnets = ["10.40.20.0/24", "10.40.21.0/24", "10.40.22.0/24"]

  enable_nat_gateway = true
  nat_gateway_type   = "regional"

  create_database_subnet_group       = true
  create_database_subnet_route_table = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Team        = "platform"
    Environment = "production"
    ManagedBy   = "opentofu"
  }
}
```

## With Secondary CIDR, Intra Subnets, and Flow Logs

Advanced multi-tier network with a secondary CIDR block, intra (routable but no-internet) subnets, and VPC flow logs.

```hcl
module "vpc" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpc?depth=1&ref=master"

  enabled = true
  name    = "advanced-vpc"

  cidr                   = "10.30.0.0/16"
  secondary_cidr_blocks  = ["10.31.0.0/16"]
  azs                    = ["us-west-2a", "us-west-2b", "us-west-2c"]

  public_subnets   = ["10.30.0.0/24", "10.30.1.0/24", "10.30.2.0/24"]
  private_subnets  = ["10.30.10.0/24", "10.30.11.0/24", "10.30.12.0/24"]
  intra_subnets    = ["10.30.20.0/24", "10.30.21.0/24", "10.30.22.0/24"]
  database_subnets = ["10.31.0.0/24", "10.31.1.0/24", "10.31.2.0/24"]

  enable_nat_gateway = true
  nat_gateway_type   = "multi_az"

  create_database_subnet_group = true

  enable_flow_log                      = true
  flow_log_destination_type            = "cloud-watch-logs"
  flow_log_cloudwatch_log_group_name_prefix = "/aws/vpc/advanced-vpc/"
  flow_log_cloudwatch_iam_role_arn     = "arn:aws:iam::123456789012:role/vpc-flow-logs-role"
  flow_log_max_aggregation_interval    = 60

  tags = {
    Team        = "platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```
