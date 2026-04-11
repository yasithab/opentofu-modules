# Transit Gateway Route Table

Manages AWS Transit Gateway route tables including route table associations, route propagations, Transit Gateway routes, and VPC routes that point to the Transit Gateway.

## Features

- **Route Table Management** - Creates a dedicated Transit Gateway route table associated with an existing Transit Gateway
- **Attachment Associations** - Associates Transit Gateway attachments with the route table and optionally enables route propagation
- **TGW Routes** - Defines static routes in the Transit Gateway route table with support for blackhole routes
- **VPC Routes** - Creates routes in VPC route tables that direct traffic to the Transit Gateway, supporting both IPv4 and IPv6 destinations

## Usage

```hcl
module "tgw_route_table" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//transit-gateway/route-table?depth=1&ref=master"

  name               = "shared-services-rt"
  transit_gateway_id = "tgw-0123456789abcdef0"

  associations = {
    vpc-1 = {
      transit_gateway_attachment_id = "tgw-attach-aaa"
      propagate_route_table         = true
    }
  }

  routes = {
    default = {
      destination_cidr_block       = "0.0.0.0/0"
      transit_gateway_attachment_id = "tgw-attach-bbb"
    }
  }

  tags = {
    Environment = "production"
  }
}
```


## Examples

## Basic Usage

Create a named route table for a Transit Gateway with no routes or associations.

```hcl
module "tgw_route_table" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//transit-gateway/route-table?depth=1&ref=master"

  enabled = true
  name    = "spoke-route-table"

  transit_gateway_id = "tgw-0a1b2c3d4e5f67890"

  tags = {
    Team        = "platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## With Associations and Route Propagation

Associate VPC attachments with the route table and enable route propagation for each.

```hcl
module "tgw_spoke_route_table" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//transit-gateway/route-table?depth=1&ref=master"

  enabled = true
  name    = "spoke-rt"

  transit_gateway_id = "tgw-0a1b2c3d4e5f67890"

  associations = {
    app-vpc = {
      transit_gateway_attachment_id = "tgw-attach-0a1b2c3d4e5f67891"
      propagate_route_table         = true
    }
    data-vpc = {
      transit_gateway_attachment_id = "tgw-attach-0b2c3d4e5f6789abc"
      propagate_route_table         = true
    }
  }

  tags = {
    Team        = "platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## With Static Routes and Blackhole

Add static routes including a blackhole entry to block unwanted CIDR ranges.

```hcl
module "tgw_security_route_table" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//transit-gateway/route-table?depth=1&ref=master"

  enabled = true
  name    = "security-rt"

  transit_gateway_id = "tgw-0a1b2c3d4e5f67890"

  associations = {
    inspection-vpc = {
      transit_gateway_attachment_id = "tgw-attach-0c3d4e5f6789abcd"
      propagate_route_table         = false
    }
  }

  routes = {
    default-to-inspection = {
      destination_cidr_block        = "0.0.0.0/0"
      transit_gateway_attachment_id = "tgw-attach-0c3d4e5f6789abcd"
    }
    block-test-range = {
      destination_cidr_block = "192.0.2.0/24"
      blackhole              = true
    }
  }

  tags = {
    Team        = "platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## With VPC Routes Injected into Spoke Route Tables

Push routes into VPC route tables (e.g., after attaching to the TGW).

```hcl
module "tgw_shared_services_rt" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//transit-gateway/route-table?depth=1&ref=master"

  enabled = true
  name    = "shared-services-rt"

  transit_gateway_id = "tgw-0a1b2c3d4e5f67890"

  associations = {
    shared-services = {
      transit_gateway_attachment_id = "tgw-attach-0d4e5f6789abcdef"
      propagate_route_table         = true
    }
  }

  vpc_routes = {
    app-to-shared = {
      route_table_id         = "rtb-0a1b2c3d4e5f67891"
      destination_cidr_block = "10.10.0.0/16"
    }
    data-to-shared = {
      route_table_id         = "rtb-0b2c3d4e5f6789abc"
      destination_cidr_block = "10.10.0.0/16"
    }
  }

  tags = {
    Team        = "platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```
