# VPC Peering

Establishes an AWS VPC peering connection between a requestor and acceptor VPC, with automatic route creation in the requestor VPC route tables and configurable DNS resolution options.

## Features

- **Cross-Account Peering** - Supports VPC peering across different AWS accounts by specifying the acceptor account ID
- **Cross-Region Peering** - Peer VPCs across AWS regions by providing the acceptor region
- **Automatic Route Creation** - Automatically creates routes in the requestor VPC route tables for all specified acceptor CIDR blocks
- **DNS Resolution** - Configures DNS resolution options for both requestor and acceptor sides of the peering connection
- **Route Table Filtering** - Filter which requestor route tables receive peering routes using tag-based selection

## Usage

```hcl
module "vpc_peering" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpc/vpc-peering?depth=1&ref=master"

  requestor_vpc_id      = "vpc-aaa"
  acceptor_vpc_id       = "vpc-bbb"
  acceptor_aws_account_id = "123456789012"
  acceptor_aws_region     = "us-west-2"
  acceptor_cidr_blocks    = ["10.1.0.0/16"]

  tags = {
    Environment = "production"
  }
}
```


## Examples

## Basic Usage

Create a same-account, same-region VPC peering connection.

```hcl
module "vpc_peering" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpc/vpc-peering?depth=1&ref=master"

  enabled = true

  requestor_vpc_id = "vpc-0a1b2c3d4e5f67890"
  acceptor_vpc_id  = "vpc-0b2c3d4e5f6789abc"

  acceptor_aws_account_id = "123456789012"
  acceptor_aws_region     = "ap-southeast-1"

  acceptor_cidr_blocks = ["10.20.0.0/16"]

  tags = {
    Team        = "platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Cross-Account Peering with DNS Resolution

Peer a production VPC with a shared-services VPC in a different account and enable DNS resolution.

```hcl
module "vpc_peering_shared_services" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpc/vpc-peering?depth=1&ref=master"

  enabled = true

  requestor_vpc_id = "vpc-0a1b2c3d4e5f67890"
  acceptor_vpc_id  = "vpc-0c3d4e5f6789abcd0"

  acceptor_aws_account_id = "987654321098"
  acceptor_aws_region     = "ap-southeast-1"

  acceptor_cidr_blocks = ["10.50.0.0/16"]

  requestor_allow_remote_vpc_dns_resolution = true
  acceptor_allow_remote_vpc_dns_resolution  = true

  requestor_route_table_tags = {
    Tier = "private"
  }

  tags = {
    Team        = "platform"
    Environment = "production"
    Purpose     = "shared-services-peering"
    ManagedBy   = "terraform"
  }
}
```

## Cross-Region Peering with Custom Timeouts

Peer VPCs across regions (e.g., ap-southeast-1 to eu-west-1) with extended timeouts.

```hcl
module "vpc_peering_cross_region" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpc/vpc-peering?depth=1&ref=master"

  enabled = true

  requestor_vpc_id = "vpc-0a1b2c3d4e5f67890"
  acceptor_vpc_id  = "vpc-0d4e5f6789abcdef0"

  acceptor_aws_account_id = "123456789012"
  acceptor_aws_region     = "eu-west-1"

  acceptor_cidr_blocks = ["10.30.0.0/16", "10.31.0.0/16"]

  requestor_allow_remote_vpc_dns_resolution = true
  acceptor_allow_remote_vpc_dns_resolution  = true

  create_timeout = "5m"
  update_timeout = "5m"
  delete_timeout = "10m"

  tags = {
    Team        = "platform"
    Environment = "production"
    Purpose     = "dr-replication"
    ManagedBy   = "terraform"
  }
}
```
