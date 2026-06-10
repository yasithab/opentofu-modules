# VPC Peering

Establishes an AWS VPC peering connection between a requestor and acceptor VPC, with automatic route creation in the requestor VPC route tables and configurable DNS resolution options.

## Features

- **Cross-Account Peering** - Supports VPC peering across different AWS accounts by specifying the acceptor account ID
- **Cross-Region Peering** - Peer VPCs across AWS regions by providing the acceptor region
- **Automatic Route Creation** - Automatically creates routes in the requestor VPC route tables for all specified acceptor CIDR blocks
- **DNS Resolution** - Configures DNS resolution options for both requestor and acceptor sides of the peering connection
- **Route Table Filtering** - Filter which requestor route tables receive peering routes using tag-based selection
- **Connection Acceptance** - Optionally auto-accept same-account/same-region peering (`auto_accept = true`) or create an `aws_vpc_peering_connection_accepter` (`create_accepter = true`); DNS resolution options are only managed once the connection can be accepted

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
| acceptor\_allow\_remote\_vpc\_dns\_resolution | Allow acceptor VPC to resolve public DNS hostnames to private IP addresses when queried from instances in the requestor VPC | `bool` | `true` | no |
| acceptor\_aws\_account\_id | The AWS account id of the acceptor | `string` | `null` | no |
| acceptor\_aws\_region | The AWS region of the acceptor VPC | `string` | `null` | no |
| acceptor\_cidr\_blocks | accepter cidr blocks | `list(string)` | `[]` | no |
| acceptor\_vpc\_id | Acceptor VPC ID | `string` | `null` | no |
| auto\_accept | Accept the peering request on the requestor side (only valid for same-account, same-region peering) | `bool` | `false` | no |
| create\_accepter | Create an aws\_vpc\_peering\_connection\_accepter resource to accept the peering request (requires the provider to have access to the acceptor VPC) | `bool` | `false` | no |
| create\_timeout | VPC peering connection create timeout. For more details, see https://www.terraform.io/docs/configuration/resources.html#operation-timeouts | `string` | `"3m"` | no |
| delete\_timeout | VPC peering connection delete timeout. For more details, see https://www.terraform.io/docs/configuration/resources.html#operation-timeouts | `string` | `"5m"` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| requestor\_allow\_remote\_vpc\_dns\_resolution | Allow requestor VPC to resolve public DNS hostnames to private IP addresses when queried from instances in the acceptor VPC | `bool` | `true` | no |
| requestor\_route\_table\_tags | Only add peer routes to requestor VPC route tables matching these tags | `map(string)` | `{}` | no |
| requestor\_vpc\_id | Requestor VPC ID | `string` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| update\_timeout | VPC peering connection update timeout. For more details, see https://www.terraform.io/docs/configuration/resources.html#operation-timeouts | `string` | `"3m"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| accept\_status | The status of the VPC peering connection request |
| connection\_id | VPC peering connection ID |
<!-- END_TF_DOCS -->

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
