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
      transit_gateway_id     = "tgw-0123456789abcdef0"
      vpc_id     = "vpc-aaa"
      subnet_ids = ["subnet-aaa", "subnet-bbb"]
    }
  }

  tags = {
    Environment = "production"
  }
}
```


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
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| name | Name to use for resource naming and tagging. | `string` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| vpc\_attachments | Map of VPC attachment configurations. Each entry requires transit\_gateway\_id, vpc\_id, and subnet\_ids. | <pre>map(object({<br/>    transit_gateway_id                              = string<br/>    vpc_id                                          = string<br/>    subnet_ids                                      = list(string)<br/>    dns_support                                     = optional(bool, true)<br/>    ipv6_support                                    = optional(bool, false)<br/>    appliance_mode_support                          = optional(bool, false)<br/>    security_group_referencing_support              = optional(bool, false)<br/>    transit_gateway_default_route_table_association = optional(bool, true)<br/>    transit_gateway_default_route_table_propagation = optional(bool, true)<br/>    tags                                            = optional(map(string), {})<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| ec2\_transit\_gateway\_vpc\_attachment | Map of EC2 Transit Gateway VPC Attachment attributes |
| ec2\_transit\_gateway\_vpc\_attachment\_ids | List of EC2 Transit Gateway VPC Attachment identifiers |
<!-- END_TF_DOCS -->

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
      transit_gateway_id     = "tgw-0a1b2c3d4e5f67890"
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
      transit_gateway_id     = "tgw-0a1b2c3d4e5f67890"
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
      transit_gateway_id     = "tgw-0a1b2c3d4e5f67890"
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
      transit_gateway_id                = "tgw-0a1b2c3d4e5f67890"
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

## Notes

- **Breaking:** the per-attachment attribute `tgw_id` was renamed to `transit_gateway_id`. Update existing module calls accordingly.
