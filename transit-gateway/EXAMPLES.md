# Transit Gateway Module - Examples

## Basic Usage

Create a Transit Gateway with sensible defaults and no VPC attachments.

```hcl
module "transit_gateway" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//transit-gateway?depth=1&ref=v2.0.0"

  enabled = true
  name    = "main-tgw"

  description = "Central Transit Gateway for the platform"

  tags = {
    Team        = "platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## With VPC Attachments

Attach two VPCs (e.g., a shared-services VPC and an application VPC) to the Transit Gateway.

```hcl
module "transit_gateway" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//transit-gateway?depth=1&ref=v2.0.0"

  enabled = true
  name    = "platform-tgw"

  description                      = "Platform Transit Gateway"
  amazon_side_asn                  = "64512"
  dns_support                      = true
  vpn_ecmp_support                 = true
  default_route_table_association  = false
  default_route_table_propagation  = false

  vpc_attachments = {
    shared-services = {
      vpc_id     = "vpc-0a1b2c3d4e5f67890"
      subnet_ids = ["subnet-0a1b2c3d4e5f67891", "subnet-0a1b2c3d4e5f67892"]
      dns_support = true
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
      tags = { Purpose = "shared-services" }
    }
    app-vpc = {
      vpc_id     = "vpc-0b2c3d4e5f6789abc"
      subnet_ids = ["subnet-0b2c3d4e5f6789abd", "subnet-0b2c3d4e5f6789abe"]
      dns_support = true
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
      tags = { Purpose = "application" }
    }
  }

  tags = {
    Team        = "platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## With RAM Sharing to Another AWS Account

Share the Transit Gateway with a spoke account via AWS Resource Access Manager.

```hcl
module "transit_gateway" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//transit-gateway?depth=1&ref=v2.0.0"

  enabled = true
  name    = "hub-tgw"

  description                     = "Hub Transit Gateway shared via RAM"
  amazon_side_asn                 = "64512"
  default_route_table_association = false
  default_route_table_propagation = false

  enable_ram_share             = true
  ram_name                     = "hub-tgw-share"
  ram_allow_external_principals = false
  ram_principals = [
    "arn:aws:organizations::123456789012:organization/o-abcdef123456",
  ]

  tags = {
    Team        = "platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## With Flow Logs and Cross-Region Peering

Enable flow logs to S3 and configure a peering attachment to a TGW in another region.

```hcl
module "transit_gateway" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//transit-gateway?depth=1&ref=v2.0.0"

  enabled = true
  name    = "eu-west-1-tgw"

  description     = "EU Transit Gateway with flow logs and peering"
  amazon_side_asn = "64512"

  create_flow_log = true
  flow_logs = {
    tgw-s3 = {
      log_destination      = "arn:aws:s3:::my-vpc-flow-logs-bucket/tgw/"
      log_destination_type = "s3"
      traffic_type         = "ALL"
      destination_options = {
        file_format                = "parquet"
        hive_compatible_partitions = true
        per_hour_partition         = true
      }
      enable_transit_gateway = true
    }
  }

  peering_attachments = {
    us-east-1-peer = {
      peer_account_id         = "123456789012"
      peer_region             = "us-east-1"
      peer_transit_gateway_id = "tgw-0a1b2c3d4e5f67890"
      dynamic_routing         = "disable"
      tags = { Purpose = "cross-region-peering" }
    }
  }

  tags = {
    Team        = "platform"
    Environment = "production"
    Region      = "eu-west-1"
    ManagedBy   = "terraform"
  }
}
```
