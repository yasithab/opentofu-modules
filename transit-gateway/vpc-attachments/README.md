# Transit Gateway VPC Attachments

Attaches one or more VPCs to an existing AWS Transit Gateway. Use this standalone submodule when the Transit Gateway is managed separately or in another account.

## Features

- **Multiple VPC Attachments** - Attach multiple VPCs to a Transit Gateway using a single map-based configuration
- **Per-Attachment Settings** - Configure DNS support, IPv6 support, appliance mode, and security group referencing independently for each attachment
- **Default Route Table Control** - Toggle automatic association and propagation with the Transit Gateway default route table per attachment

## Usage

```hcl
module "tgw_vpc_attachments" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//transit-gateway/vpc-attachments?depth=1&ref=master"

  name = "my-tgw"

  vpc_attachments = {
    vpc-shared = {
      tgw_id     = "tgw-0123456789abcdef0"
      vpc_id     = "vpc-aaa"
      subnet_ids = ["subnet-aaa", "subnet-bbb"]
    }
  }

  tags = {
    Environment = "production"
  }
}
```


## Examples

## Basic Usage

Attach a single VPC to an existing Transit Gateway.

```hcl
module "tgw_vpc_attachments" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//transit-gateway/vpc-attachments?depth=1&ref=master"

  enabled = true
  name    = "app-tgw-attachments"

  vpc_attachments = {
    app-vpc = {
      tgw_id     = "tgw-0a1b2c3d4e5f67890"
      vpc_id     = "vpc-0a1b2c3d4e5f67891"
      subnet_ids = ["subnet-0a1b2c3d4e5f67892", "subnet-0a1b2c3d4e5f67893"]
    }
  }

  tags = {
    Team        = "platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Multiple VPC Attachments with Custom Options

Attach multiple VPCs with DNS support and custom route table association settings.

```hcl
module "tgw_vpc_attachments" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//transit-gateway/vpc-attachments?depth=1&ref=master"

  enabled = true
  name    = "platform-tgw-attachments"

  vpc_attachments = {
    shared-services = {
      tgw_id     = "tgw-0a1b2c3d4e5f67890"
      vpc_id     = "vpc-0b2c3d4e5f6789abc"
      subnet_ids = [
        "subnet-0b2c3d4e5f6789abd",
        "subnet-0b2c3d4e5f6789abe",
        "subnet-0b2c3d4e5f6789abf",
      ]
      dns_support                                     = true
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
      tags = { Purpose = "shared-services" }
    }
    data-vpc = {
      tgw_id     = "tgw-0a1b2c3d4e5f67890"
      vpc_id     = "vpc-0c3d4e5f6789abcd"
      subnet_ids = [
        "subnet-0c3d4e5f6789abce",
        "subnet-0c3d4e5f6789abcf",
      ]
      dns_support                                     = true
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
      tags = { Purpose = "data" }
    }
  }

  tags = {
    Team        = "platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## With Appliance Mode for Network Inspection

Enable appliance mode for a VPC hosting a network inspection appliance (e.g., a firewall).

```hcl
module "tgw_inspection_attachment" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//transit-gateway/vpc-attachments?depth=1&ref=master"

  enabled = true
  name    = "inspection-tgw-attachments"

  vpc_attachments = {
    inspection-vpc = {
      tgw_id                = "tgw-0a1b2c3d4e5f67890"
      vpc_id                = "vpc-0d4e5f6789abcdef0"
      subnet_ids            = ["subnet-0d4e5f6789abcdef1", "subnet-0d4e5f6789abcdef2"]
      appliance_mode_support = true
      dns_support           = true
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
      tags = { Purpose = "network-inspection" }
    }
  }

  tags = {
    Team        = "security"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```
