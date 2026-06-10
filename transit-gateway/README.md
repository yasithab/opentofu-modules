# Transit Gateway

Provisions an AWS EC2 Transit Gateway with support for VPC attachments, peering attachments, Resource Access Manager (RAM) sharing, and flow logs.

## Features

- **Transit Gateway Creation** - Creates an EC2 Transit Gateway with configurable ASN, DNS support, encryption, multicast, ECMP, and CIDR blocks
- **VPC Attachments** - Attach multiple VPCs to the Transit Gateway with per-attachment configuration for DNS, IPv6, appliance mode, and security group referencing
- **TGW Peering** - Establish cross-region and cross-account Transit Gateway peering connections with optional dynamic routing and automatic acceptance
- **RAM Sharing** - Share the Transit Gateway across AWS accounts and organizations using Resource Access Manager
- **Flow Logs** - Create flow logs for the Transit Gateway or individual attachments with configurable destinations and formats

## Submodules

| Submodule | Description |
|-----------|-------------|
| [route-table](route-table/) | Manages Transit Gateway route tables, associations, propagations, and routes |
| [vpc-attachments](vpc-attachments/) | Standalone module for attaching VPCs to an existing Transit Gateway |

## Usage

```hcl
module "transit_gateway" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//transit-gateway?depth=1&ref=master"

  name        = "my-tgw"
  description = "Main Transit Gateway"

  amazon_side_asn                 = "64512"
  auto_accept_shared_attachments  = true
  default_route_table_association = false
  default_route_table_propagation = false

  vpc_attachments = {
    vpc-1 = {
      vpc_id     = "vpc-0123456789abcdef0"
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

Create a Transit Gateway with sensible defaults and no VPC attachments.

```hcl
module "transit_gateway" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//transit-gateway?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//transit-gateway?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//transit-gateway?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//transit-gateway?depth=1&ref=master"

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

## Notes

- `name` is required (validated as non-null).
- `auto_accept_shared_attachments` now defaults to `false` (security hardening); set it to `true` explicitly if you rely on automatic acceptance.
- `flow_logs.max_aggregation_interval` defaults to `60` and must be `60` or `600` (AWS-supported values).
- `vpc_attachments` and `peering_attachments` outputs are marked sensitive.

## Reference

<details>
<summary>Requirements, providers, inputs and outputs (generated by terraform-docs)</summary>

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
| amazon\_side\_asn | The Autonomous System Number (ASN) for the Amazon side of the gateway. By default the TGW is created with the current default Amazon ASN | `string` | `null` | no |
| auto\_accept\_shared\_attachments | Whether resource attachment requests are automatically accepted | `bool` | `false` | no |
| create\_flow\_log | Whether to create flow log resource(s) | `bool` | `true` | no |
| default\_route\_table\_association | Whether resource attachments are automatically associated with the default association route table | `bool` | `false` | no |
| default\_route\_table\_propagation | Whether resource attachments automatically propagate routes to the default propagation route table | `bool` | `false` | no |
| description | Description of the EC2 Transit Gateway | `string` | `null` | no |
| dns\_support | Should be true to enable DNS support in the TGW | `bool` | `true` | no |
| enable\_ram\_share | Whether to share your transit gateway with other accounts | `bool` | `false` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| encryption\_support | Whether VPC Encryption Control support is enabled. Valid values: enable, disable | `bool` | `false` | no |
| flow\_logs | Flow Logs to create for Transit Gateway or attachments | <pre>map(object({<br/>    deliver_cross_account_role = optional(string)<br/>    destination_options = optional(object({<br/>      file_format                = optional(string, "parquet")<br/>      hive_compatible_partitions = optional(bool, false)<br/>      per_hour_partition         = optional(bool, true)<br/>    }))<br/>    eni_id                   = optional(string)<br/>    iam_role_arn             = optional(string)<br/>    log_destination          = optional(string)<br/>    log_destination_type     = optional(string)<br/>    log_format               = optional(string)<br/>    max_aggregation_interval = optional(number, 60)<br/>    regional_nat_gateway_id  = optional(string)<br/>    subnet_id                = optional(string)<br/>    traffic_type             = optional(string, "ALL")<br/>    tags                     = optional(map(string), {})<br/><br/>    enable_transit_gateway = optional(bool, true)<br/>    # The following can be provided when `enable_transit_gateway` is `false`<br/>    vpc_attachment_key     = optional(string)<br/>    peering_attachment_key = optional(string)<br/>  }))</pre> | `{}` | no |
| multicast\_support | Whether multicast support is enabled | `bool` | `false` | no |
| name | Name to use for resource naming and tagging. | `string` | `null` | no |
| peering\_attachments | Map of Transit Gateway peering attachments to create | <pre>map(object({<br/>    peer_account_id         = string<br/>    peer_region             = string<br/>    peer_transit_gateway_id = string<br/>    dynamic_routing         = optional(string) # "enable" or "disable"<br/>    tags                    = optional(map(string), {})<br/><br/>    accept_peering_attachment = optional(bool, false)<br/>  }))</pre> | `{}` | no |
| ram\_allow\_external\_principals | Indicates whether principals outside your organization can be associated with a resource share | `bool` | `false` | no |
| ram\_name | The name of the resource share of TGW | `string` | `null` | no |
| ram\_principals | A list of principals to share TGW with. Possible values are an AWS account ID, an AWS Organizations Organization ARN, or an AWS Organizations Organization Unit ARN | `set(string)` | `[]` | no |
| ram\_tags | Additional tags for the RAM | `map(string)` | `{}` | no |
| security\_group\_referencing\_support | Whether security group referencing is enabled | `bool` | `false` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| tgw\_tags | Additional tags for the TGW | `map(string)` | `{}` | no |
| timeouts | Create, update, and delete timeout configurations for the transit gateway | `map(string)` | `{}` | no |
| transit\_gateway\_cidr\_blocks | One or more IPv4 or IPv6 CIDR blocks for the transit gateway. Must be a size /24 CIDR block or larger for IPv4, or a size /64 CIDR block or larger for IPv6 | `list(string)` | `[]` | no |
| vpc\_attachments | Map of VPC route table attachments to create | <pre>map(object({<br/>    appliance_mode_support                          = optional(bool, false)<br/>    dns_support                                     = optional(bool, true)<br/>    ipv6_support                                    = optional(bool, false)<br/>    security_group_referencing_support              = optional(bool, false)<br/>    subnet_ids                                      = list(string)<br/>    tags                                            = optional(map(string), {})<br/>    transit_gateway_default_route_table_association = optional(bool, false)<br/>    transit_gateway_default_route_table_propagation = optional(bool, false)<br/>    vpc_id                                          = string<br/><br/>    accept_peering_attachment = optional(bool, false)<br/>  }))</pre> | `{}` | no |
| vpn\_ecmp\_support | Whether VPN Equal Cost Multipath Protocol support is enabled | `bool` | `true` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| arn | EC2 Transit Gateway Amazon Resource Name (ARN) |
| association\_default\_route\_table\_id | Identifier of the default association route table |
| id | EC2 Transit Gateway identifier |
| owner\_id | Identifier of the AWS account that owns the EC2 Transit Gateway |
| peering\_attachments | Map of TGW peering attachments created |
| propagation\_default\_route\_table\_id | Identifier of the default propagation route table |
| ram\_resource\_share\_id | The Amazon Resource Name (ARN) of the resource share |
| vpc\_attachments | Map of VPC attachments created |
<!-- END_TF_DOCS -->

</details>
