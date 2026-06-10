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

## Notes

- `name` is required (validated as non-null) since it is used for resource naming and `Name` tags.
- `flow_log_cloudwatch_log_group_retention_in_days` defaults to `30` days.
- `nat_gateway_type = "multi_az"` requires at least as many public subnets as availability zones; the plan fails with a clear error otherwise.
- `customer_gateways` and `vpc_block_public_access_exclusions` use typed object schemas with optional attributes.

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
| amazon\_side\_asn | The Autonomous System Number (ASN) for the Amazon side of the gateway. By default the virtual private gateway is created with the current default Amazon ASN | `string` | `"64512"` | no |
| azs | A list of availability zones names or ids in the region | `list(string)` | `[]` | no |
| cidr | (Optional) The IPv4 CIDR block for the VPC. CIDR can be explicitly set or it can be derived from IPAM using `ipv4_netmask_length` & `ipv4_ipam_pool_id` | `string` | `"10.0.0.0/16"` | no |
| create\_database\_internet\_gateway\_route | Controls if an internet gateway route for public database access should be created | `bool` | `false` | no |
| create\_database\_nat\_gateway\_route | Controls if a nat gateway route should be created to give internet access to the database subnets | `bool` | `false` | no |
| create\_database\_subnet\_group | Controls if database subnet group should be created (n.b. database\_subnets must also be set) | `bool` | `true` | no |
| create\_database\_subnet\_route\_table | Controls if separate route table for database should be created | `bool` | `false` | no |
| create\_egress\_only\_igw | Controls if an Egress Only Internet Gateway is created and its related routes | `bool` | `true` | no |
| create\_elasticache\_subnet\_group | Controls if elasticache subnet group should be created | `bool` | `true` | no |
| create\_elasticache\_subnet\_route\_table | Controls if separate route table for elasticache should be created | `bool` | `false` | no |
| create\_flow\_log\_cloudwatch\_iam\_role | Whether to create IAM role for VPC Flow Logs | `bool` | `false` | no |
| create\_flow\_log\_cloudwatch\_log\_group | Whether to create CloudWatch log group for VPC Flow Logs | `bool` | `false` | no |
| create\_igw | Controls if an Internet Gateway is created for public subnets and the related routes that connect them | `bool` | `true` | no |
| create\_multiple\_database\_route\_tables | Indicates whether to create a separate route table for each database subnet. Default: `true` | `bool` | `true` | no |
| create\_multiple\_intra\_route\_tables | Indicates whether to create a separate route table for each intra subnet. Default: `false` | `bool` | `false` | no |
| create\_multiple\_private\_route\_tables | Indicates whether to create a separate route table for each private subnet. Default: `true` | `bool` | `true` | no |
| create\_multiple\_public\_route\_tables | Indicates whether to create a separate route table for each public subnet. Default: `false` | `bool` | `false` | no |
| create\_private\_nat\_gateway\_route | Controls if a nat gateway route should be created to give internet access to the private subnets | `bool` | `true` | no |
| create\_redshift\_subnet\_group | Controls if redshift subnet group should be created | `bool` | `true` | no |
| create\_redshift\_subnet\_route\_table | Controls if separate route table for redshift should be created | `bool` | `false` | no |
| customer\_gateway\_tags | Additional tags for the Customer Gateway | `map(string)` | `{}` | no |
| customer\_gateways | Maps of Customer Gateway's attributes (BGP ASN and Gateway's Internet-routable external IP address) | <pre>map(object({<br/>    bgp_asn     = number<br/>    ip_address  = string<br/>    device_name = optional(string)<br/>  }))</pre> | `{}` | no |
| customer\_owned\_ipv4\_pool | The customer owned IPv4 address pool. Typically used with the `map_customer_owned_ip_on_launch` argument. The `outpost_arn` argument must be specified when configured | `string` | `null` | no |
| database\_acl\_tags | Additional tags for the database subnets network ACL | `map(string)` | `{}` | no |
| database\_dedicated\_network\_acl | Whether to use dedicated network ACL (not default) and custom rules for database subnets | `bool` | `false` | no |
| database\_inbound\_acl\_rules | Database subnets inbound network ACL rules | `list(map(string))` | <pre>[<br/>  {<br/>    "cidr_block": "0.0.0.0/0",<br/>    "from_port": 0,<br/>    "protocol": "-1",<br/>    "rule_action": "allow",<br/>    "rule_number": 100,<br/>    "to_port": 0<br/>  }<br/>]</pre> | no |
| database\_outbound\_acl\_rules | Database subnets outbound network ACL rules | `list(map(string))` | <pre>[<br/>  {<br/>    "cidr_block": "0.0.0.0/0",<br/>    "from_port": 0,<br/>    "protocol": "-1",<br/>    "rule_action": "allow",<br/>    "rule_number": 100,<br/>    "to_port": 0<br/>  }<br/>]</pre> | no |
| database\_route\_table\_tags | Additional tags for the database route tables | `map(string)` | `{}` | no |
| database\_subnet\_assign\_ipv6\_address\_on\_creation | Specify true to indicate that network interfaces created in the specified subnet should be assigned an IPv6 address. Default is `false` | `bool` | `false` | no |
| database\_subnet\_enable\_dns64 | Indicates whether DNS queries made to the Amazon-provided DNS Resolver in this subnet should return synthetic IPv6 addresses for IPv4-only destinations. Default: `true` | `bool` | `true` | no |
| database\_subnet\_enable\_resource\_name\_dns\_a\_record\_on\_launch | Indicates whether to respond to DNS queries for instance hostnames with DNS A records. Default: `false` | `bool` | `false` | no |
| database\_subnet\_enable\_resource\_name\_dns\_aaaa\_record\_on\_launch | Indicates whether to respond to DNS queries for instance hostnames with DNS AAAA records. Default: `true` | `bool` | `true` | no |
| database\_subnet\_group\_name | Name of database subnet group | `string` | `null` | no |
| database\_subnet\_group\_tags | Additional tags for the database subnet group | `map(string)` | `{}` | no |
| database\_subnet\_ipv6\_native | Indicates whether to create an IPv6-only subnet. Default: `false` | `bool` | `false` | no |
| database\_subnet\_ipv6\_prefixes | Assigns IPv6 database subnet id based on the Amazon provided /56 prefix base 10 integer (0-256). Must be of equal length to the corresponding IPv4 subnet list | `list(string)` | `[]` | no |
| database\_subnet\_names | Explicit values to use in the Name tag on database subnets. If empty, Name tags are generated | `list(string)` | `[]` | no |
| database\_subnet\_private\_dns\_hostname\_type\_on\_launch | The type of hostnames to assign to instances in the subnet at launch. For IPv6-only subnets, an instance DNS name must be based on the instance ID. For dual-stack and IPv4-only subnets, you can specify whether DNS names use the instance IPv4 address or the instance ID. Valid values: `ip-name`, `resource-name` | `string` | `null` | no |
| database\_subnet\_suffix | Suffix to append to database subnets name | `string` | `"database"` | no |
| database\_subnet\_tags | Additional tags for the database subnets | `map(string)` | `{}` | no |
| database\_subnets | A list of database subnets inside the VPC | `list(string)` | `[]` | no |
| default\_network\_acl\_egress | List of maps of egress rules to set on the Default Network ACL | `list(map(string))` | <pre>[<br/>  {<br/>    "action": "allow",<br/>    "cidr_block": "0.0.0.0/0",<br/>    "from_port": 0,<br/>    "protocol": "-1",<br/>    "rule_no": 100,<br/>    "to_port": 0<br/>  },<br/>  {<br/>    "action": "allow",<br/>    "from_port": 0,<br/>    "ipv6_cidr_block": "::/0",<br/>    "protocol": "-1",<br/>    "rule_no": 101,<br/>    "to_port": 0<br/>  }<br/>]</pre> | no |
| default\_network\_acl\_ingress | List of maps of ingress rules to set on the Default Network ACL | `list(map(string))` | <pre>[<br/>  {<br/>    "action": "allow",<br/>    "cidr_block": "0.0.0.0/0",<br/>    "from_port": 0,<br/>    "protocol": "-1",<br/>    "rule_no": 100,<br/>    "to_port": 0<br/>  },<br/>  {<br/>    "action": "allow",<br/>    "from_port": 0,<br/>    "ipv6_cidr_block": "::/0",<br/>    "protocol": "-1",<br/>    "rule_no": 101,<br/>    "to_port": 0<br/>  }<br/>]</pre> | no |
| default\_network\_acl\_name | Name to be used on the Default Network ACL | `string` | `null` | no |
| default\_network\_acl\_tags | Additional tags for the Default Network ACL | `map(string)` | `{}` | no |
| default\_route\_table\_name | Name to be used on the default route table | `string` | `null` | no |
| default\_route\_table\_propagating\_vgws | List of virtual gateways for propagation | `list(string)` | `[]` | no |
| default\_route\_table\_routes | Configuration block of routes. See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_route_table#route | `list(map(string))` | `[]` | no |
| default\_route\_table\_tags | Additional tags for the default route table | `map(string)` | `{}` | no |
| default\_security\_group\_egress | List of maps of egress rules to set on the default security group | `list(map(string))` | `[]` | no |
| default\_security\_group\_ingress | List of maps of ingress rules to set on the default security group | `list(map(string))` | `[]` | no |
| default\_security\_group\_name | Name to be used on the default security group | `string` | `null` | no |
| default\_security\_group\_tags | Additional tags for the default security group | `map(string)` | `{}` | no |
| default\_vpc\_enable\_dns\_hostnames | Should be true to enable DNS hostnames in the Default VPC | `bool` | `true` | no |
| default\_vpc\_enable\_dns\_support | Should be true to enable DNS support in the Default VPC | `bool` | `true` | no |
| default\_vpc\_name | Name to be used on the Default VPC | `string` | `null` | no |
| default\_vpc\_tags | Additional tags for the Default VPC | `map(string)` | `{}` | no |
| dhcp\_options\_domain\_name | Specifies DNS name for DHCP options set (requires enable\_dhcp\_options set to true) | `string` | `null` | no |
| dhcp\_options\_domain\_name\_servers | Specify a list of DNS server addresses for DHCP options set, default to AWS provided (requires enable\_dhcp\_options set to true) | `list(string)` | <pre>[<br/>  "AmazonProvidedDNS"<br/>]</pre> | no |
| dhcp\_options\_ipv6\_address\_preferred\_lease\_time | How frequently, in seconds, a running instance with an IPv6 assigned to it goes through DHCPv6 lease renewal (requires enable\_dhcp\_options set to true) | `number` | `null` | no |
| dhcp\_options\_netbios\_name\_servers | Specify a list of netbios servers for DHCP options set (requires enable\_dhcp\_options set to true) | `list(string)` | `[]` | no |
| dhcp\_options\_netbios\_node\_type | Specify netbios node\_type for DHCP options set (requires enable\_dhcp\_options set to true) | `string` | `null` | no |
| dhcp\_options\_ntp\_servers | Specify a list of NTP servers for DHCP options set (requires enable\_dhcp\_options set to true) | `list(string)` | `[]` | no |
| dhcp\_options\_tags | Additional tags for the DHCP option set (requires enable\_dhcp\_options set to true) | `map(string)` | `{}` | no |
| elasticache\_acl\_tags | Additional tags for the elasticache subnets network ACL | `map(string)` | `{}` | no |
| elasticache\_dedicated\_network\_acl | Whether to use dedicated network ACL (not default) and custom rules for elasticache subnets | `bool` | `false` | no |
| elasticache\_inbound\_acl\_rules | Elasticache subnets inbound network ACL rules | `list(map(string))` | <pre>[<br/>  {<br/>    "cidr_block": "0.0.0.0/0",<br/>    "from_port": 0,<br/>    "protocol": "-1",<br/>    "rule_action": "allow",<br/>    "rule_number": 100,<br/>    "to_port": 0<br/>  }<br/>]</pre> | no |
| elasticache\_outbound\_acl\_rules | Elasticache subnets outbound network ACL rules | `list(map(string))` | <pre>[<br/>  {<br/>    "cidr_block": "0.0.0.0/0",<br/>    "from_port": 0,<br/>    "protocol": "-1",<br/>    "rule_action": "allow",<br/>    "rule_number": 100,<br/>    "to_port": 0<br/>  }<br/>]</pre> | no |
| elasticache\_route\_table\_tags | Additional tags for the elasticache route tables | `map(string)` | `{}` | no |
| elasticache\_subnet\_assign\_ipv6\_address\_on\_creation | Specify true to indicate that network interfaces created in the specified subnet should be assigned an IPv6 address. Default is `false` | `bool` | `false` | no |
| elasticache\_subnet\_enable\_dns64 | Indicates whether DNS queries made to the Amazon-provided DNS Resolver in this subnet should return synthetic IPv6 addresses for IPv4-only destinations. Default: `true` | `bool` | `true` | no |
| elasticache\_subnet\_enable\_resource\_name\_dns\_a\_record\_on\_launch | Indicates whether to respond to DNS queries for instance hostnames with DNS A records. Default: `false` | `bool` | `false` | no |
| elasticache\_subnet\_enable\_resource\_name\_dns\_aaaa\_record\_on\_launch | Indicates whether to respond to DNS queries for instance hostnames with DNS AAAA records. Default: `true` | `bool` | `true` | no |
| elasticache\_subnet\_group\_name | Name of elasticache subnet group | `string` | `null` | no |
| elasticache\_subnet\_group\_tags | Additional tags for the elasticache subnet group | `map(string)` | `{}` | no |
| elasticache\_subnet\_ipv6\_native | Indicates whether to create an IPv6-only subnet. Default: `false` | `bool` | `false` | no |
| elasticache\_subnet\_ipv6\_prefixes | Assigns IPv6 elasticache subnet id based on the Amazon provided /56 prefix base 10 integer (0-256). Must be of equal length to the corresponding IPv4 subnet list | `list(string)` | `[]` | no |
| elasticache\_subnet\_names | Explicit values to use in the Name tag on elasticache subnets. If empty, Name tags are generated | `list(string)` | `[]` | no |
| elasticache\_subnet\_private\_dns\_hostname\_type\_on\_launch | The type of hostnames to assign to instances in the subnet at launch. For IPv6-only subnets, an instance DNS name must be based on the instance ID. For dual-stack and IPv4-only subnets, you can specify whether DNS names use the instance IPv4 address or the instance ID. Valid values: `ip-name`, `resource-name` | `string` | `null` | no |
| elasticache\_subnet\_suffix | Suffix to append to elasticache subnets name | `string` | `"elasticache"` | no |
| elasticache\_subnet\_tags | Additional tags for the elasticache subnets | `map(string)` | `{}` | no |
| elasticache\_subnets | A list of elasticache subnets inside the VPC | `list(string)` | `[]` | no |
| enable\_dhcp\_options | Should be true if you want to specify a DHCP options set with a custom domain name, DNS servers, NTP servers, netbios servers, and/or netbios server type | `bool` | `false` | no |
| enable\_dns\_hostnames | Should be true to enable DNS hostnames in the VPC | `bool` | `true` | no |
| enable\_dns\_support | Should be true to enable DNS support in the VPC | `bool` | `true` | no |
| enable\_flow\_log | Whether or not to enable VPC Flow Logs | `bool` | `false` | no |
| enable\_ipv6 | Requests an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC. You cannot specify the range of IP addresses, or the size of the CIDR block | `bool` | `false` | no |
| enable\_nat\_gateway | Should be true if you want to provision NAT Gateways for each of your private networks | `bool` | `false` | no |
| enable\_network\_address\_usage\_metrics | Determines whether network address usage metrics are enabled for the VPC | `bool` | `null` | no |
| enable\_public\_redshift | Controls if redshift should have public routing table | `bool` | `false` | no |
| enable\_vpn\_gateway | Should be true if you want to create a new VPN Gateway resource and attach it to the VPC | `bool` | `false` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| external\_nat\_ip\_ids | List of EIP IDs to be assigned to the NAT Gateways (used in combination with reuse\_nat\_ips) | `list(string)` | `[]` | no |
| external\_nat\_ips | List of EIPs to be used for `nat_public_ips` output (used in combination with reuse\_nat\_ips and external\_nat\_ip\_ids) | `list(string)` | `[]` | no |
| flow\_log\_cloudwatch\_iam\_role\_arn | The ARN for the IAM role that's used to post flow logs to a CloudWatch Logs log group. When flow\_log\_destination\_arn is set to ARN of Cloudwatch Logs, this argument needs to be provided | `string` | `null` | no |
| flow\_log\_cloudwatch\_iam\_role\_conditions | Additional conditions of the CloudWatch role assumption policy | <pre>list(object({<br/>    test     = string<br/>    variable = string<br/>    values   = list(string)<br/>  }))</pre> | `[]` | no |
| flow\_log\_cloudwatch\_log\_group\_class | Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT\_ACCESS | `string` | `null` | no |
| flow\_log\_cloudwatch\_log\_group\_kms\_key\_id | The ARN of the KMS Key to use when encrypting log data for VPC flow logs | `string` | `null` | no |
| flow\_log\_cloudwatch\_log\_group\_name\_prefix | Specifies the name prefix of CloudWatch Log Group for VPC flow logs | `string` | `"/aws/vpc-flow-log/"` | no |
| flow\_log\_cloudwatch\_log\_group\_name\_suffix | Specifies the name suffix of CloudWatch Log Group for VPC flow logs | `string` | `null` | no |
| flow\_log\_cloudwatch\_log\_group\_retention\_in\_days | Specifies the number of days you want to retain log events in the specified log group for VPC flow logs | `number` | `30` | no |
| flow\_log\_cloudwatch\_log\_group\_skip\_destroy | Set to true if you do not wish the log group (and any logs it may contain) to be deleted at destroy time, and instead just remove the log group from the Terraform state | `bool` | `false` | no |
| flow\_log\_deliver\_cross\_account\_role | (Optional) ARN of the IAM role that allows Amazon EC2 to publish flow logs across accounts. | `string` | `null` | no |
| flow\_log\_destination\_arn | The ARN of the CloudWatch log group or S3 bucket where VPC Flow Logs will be pushed. If this ARN is a S3 bucket the appropriate permissions need to be set on that bucket's policy. When create\_flow\_log\_cloudwatch\_log\_group is set to false this argument must be provided | `string` | `null` | no |
| flow\_log\_destination\_type | Type of flow log destination. Can be s3, kinesis-data-firehose or cloud-watch-logs | `string` | `"cloud-watch-logs"` | no |
| flow\_log\_file\_format | (Optional) The format for the flow log. Valid values: `plain-text`, `parquet` | `string` | `null` | no |
| flow\_log\_hive\_compatible\_partitions | (Optional) Indicates whether to use Hive-compatible prefixes for flow logs stored in Amazon S3 | `bool` | `false` | no |
| flow\_log\_log\_format | The fields to include in the flow log record, in the order in which they should appear | `string` | `null` | no |
| flow\_log\_max\_aggregation\_interval | The maximum interval of time during which a flow of packets is captured and aggregated into a flow log record. Valid Values: `60` seconds or `600` seconds | `number` | `600` | no |
| flow\_log\_per\_hour\_partition | (Optional) Indicates whether to partition the flow log per hour. This reduces the cost and response time for queries | `bool` | `false` | no |
| flow\_log\_traffic\_type | The type of traffic to capture. Valid values: ACCEPT, REJECT, ALL | `string` | `"ALL"` | no |
| igw\_tags | Additional tags for the internet gateway | `map(string)` | `{}` | no |
| instance\_tenancy | A tenancy option for instances launched into the VPC | `string` | `"default"` | no |
| intra\_acl\_tags | Additional tags for the intra subnets network ACL | `map(string)` | `{}` | no |
| intra\_dedicated\_network\_acl | Whether to use dedicated network ACL (not default) and custom rules for intra subnets | `bool` | `false` | no |
| intra\_inbound\_acl\_rules | Intra subnets inbound network ACLs | `list(map(string))` | <pre>[<br/>  {<br/>    "cidr_block": "0.0.0.0/0",<br/>    "from_port": 0,<br/>    "protocol": "-1",<br/>    "rule_action": "allow",<br/>    "rule_number": 100,<br/>    "to_port": 0<br/>  }<br/>]</pre> | no |
| intra\_outbound\_acl\_rules | Intra subnets outbound network ACLs | `list(map(string))` | <pre>[<br/>  {<br/>    "cidr_block": "0.0.0.0/0",<br/>    "from_port": 0,<br/>    "protocol": "-1",<br/>    "rule_action": "allow",<br/>    "rule_number": 100,<br/>    "to_port": 0<br/>  }<br/>]</pre> | no |
| intra\_route\_table\_tags | Additional tags for the intra route tables | `map(string)` | `{}` | no |
| intra\_subnet\_assign\_ipv6\_address\_on\_creation | Specify true to indicate that network interfaces created in the specified subnet should be assigned an IPv6 address. Default is `false` | `bool` | `false` | no |
| intra\_subnet\_enable\_dns64 | Indicates whether DNS queries made to the Amazon-provided DNS Resolver in this subnet should return synthetic IPv6 addresses for IPv4-only destinations. Default: `true` | `bool` | `true` | no |
| intra\_subnet\_enable\_resource\_name\_dns\_a\_record\_on\_launch | Indicates whether to respond to DNS queries for instance hostnames with DNS A records. Default: `false` | `bool` | `false` | no |
| intra\_subnet\_enable\_resource\_name\_dns\_aaaa\_record\_on\_launch | Indicates whether to respond to DNS queries for instance hostnames with DNS AAAA records. Default: `true` | `bool` | `true` | no |
| intra\_subnet\_ipv6\_native | Indicates whether to create an IPv6-only subnet. Default: `false` | `bool` | `false` | no |
| intra\_subnet\_ipv6\_prefixes | Assigns IPv6 intra subnet id based on the Amazon provided /56 prefix base 10 integer (0-256). Must be of equal length to the corresponding IPv4 subnet list | `list(string)` | `[]` | no |
| intra\_subnet\_names | Explicit values to use in the Name tag on intra subnets. If empty, Name tags are generated | `list(string)` | `[]` | no |
| intra\_subnet\_private\_dns\_hostname\_type\_on\_launch | The type of hostnames to assign to instances in the subnet at launch. For IPv6-only subnets, an instance DNS name must be based on the instance ID. For dual-stack and IPv4-only subnets, you can specify whether DNS names use the instance IPv4 address or the instance ID. Valid values: `ip-name`, `resource-name` | `string` | `null` | no |
| intra\_subnet\_suffix | Suffix to append to intra subnets name | `string` | `"intra"` | no |
| intra\_subnet\_tags | Additional tags for the intra subnets | `map(string)` | `{}` | no |
| intra\_subnets | A list of intra subnets inside the VPC | `list(string)` | `[]` | no |
| ipv4\_ipam\_pool\_id | (Optional) The ID of an IPv4 IPAM pool you want to use for allocating this VPC's CIDR | `string` | `null` | no |
| ipv4\_netmask\_length | (Optional) The netmask length of the IPv4 CIDR you want to allocate to this VPC. Requires specifying a ipv4\_ipam\_pool\_id | `number` | `null` | no |
| ipv6\_cidr | (Optional) IPv6 CIDR block to request from an IPAM Pool. Can be set explicitly or derived from IPAM using `ipv6_netmask_length` | `string` | `null` | no |
| ipv6\_cidr\_block\_network\_border\_group | By default when an IPv6 CIDR is assigned to a VPC a default ipv6\_cidr\_block\_network\_border\_group will be set to the region of the VPC. This can be changed to restrict advertisement of public addresses to specific Network Border Groups such as LocalZones | `string` | `null` | no |
| ipv6\_ipam\_pool\_id | (Optional) IPAM Pool ID for a IPv6 pool. Conflicts with `assign_generated_ipv6_cidr_block` | `string` | `null` | no |
| ipv6\_netmask\_length | (Optional) Netmask length to request from IPAM Pool. Conflicts with `ipv6_cidr_block`. This can be omitted if IPAM pool as a `allocation_default_netmask_length` set. Valid values: `56` | `number` | `null` | no |
| manage\_default\_network\_acl | Should be true to adopt and manage Default Network ACL | `bool` | `true` | no |
| manage\_default\_route\_table | Should be true to manage default route table | `bool` | `true` | no |
| manage\_default\_security\_group | Should be true to adopt and manage default security group | `bool` | `true` | no |
| manage\_default\_vpc | Should be true to adopt and manage Default VPC | `bool` | `false` | no |
| map\_customer\_owned\_ip\_on\_launch | Specify true to indicate that network interfaces created in the subnet should be assigned a customer owned IP address. The `customer_owned_ipv4_pool` and `outpost_arn` arguments must be specified when set to `true`. Default is `false` | `bool` | `false` | no |
| map\_public\_ip\_on\_launch | Specify true to indicate that instances launched into the subnet should be assigned a public IP address. Default is `false` | `bool` | `false` | no |
| name | Name to use for resource naming and tagging. | `string` | `null` | no |
| nat\_eip\_tags | Additional tags for the NAT EIP | `map(string)` | `{}` | no |
| nat\_gateway\_connectivity\_type | Connectivity type for the NAT Gateway. Valid values: `public`, `private`. Defaults to `public` | `string` | `"public"` | no |
| nat\_gateway\_destination\_cidr\_block | Used to pass a custom destination route for private NAT Gateway. If not specified, the default 0.0.0.0/0 is used as a destination route | `string` | `"0.0.0.0/0"` | no |
| nat\_gateway\_secondary\_allocation\_ids | List of secondary allocation EIP IDs for the NAT Gateway (zonal NAT gateways only) | `list(string)` | `[]` | no |
| nat\_gateway\_secondary\_private\_ip\_address\_count | The number of secondary private IPv4 addresses to assign to the NAT Gateway (zonal and private NAT gateways only) | `number` | `null` | no |
| nat\_gateway\_secondary\_private\_ip\_addresses | List of secondary private IPv4 addresses to assign to the NAT Gateway (zonal NAT gateways only) | `list(string)` | `[]` | no |
| nat\_gateway\_tags | Additional tags for the NAT gateways | `map(string)` | `{}` | no |
| nat\_gateway\_type | Type of NAT Gateway to create when enable\_nat\_gateway is true. Valid values: 'single' (one shared NAT GW), 'multi\_az' (one NAT GW per AZ - requires var.azs and enough public subnets), 'regional' (single regional NAT GW with automatic HA, no EIP/public subnet needed). | `string` | `"single"` | no |
| outpost\_acl\_tags | Additional tags for the outpost subnets network ACL | `map(string)` | `{}` | no |
| outpost\_arn | ARN of Outpost you want to create a subnet in | `string` | `null` | no |
| outpost\_az | AZ where Outpost is anchored | `string` | `null` | no |
| outpost\_dedicated\_network\_acl | Whether to use dedicated network ACL (not default) and custom rules for outpost subnets | `bool` | `false` | no |
| outpost\_inbound\_acl\_rules | Outpost subnets inbound network ACLs | `list(map(string))` | <pre>[<br/>  {<br/>    "cidr_block": "0.0.0.0/0",<br/>    "from_port": 0,<br/>    "protocol": "-1",<br/>    "rule_action": "allow",<br/>    "rule_number": 100,<br/>    "to_port": 0<br/>  }<br/>]</pre> | no |
| outpost\_outbound\_acl\_rules | Outpost subnets outbound network ACLs | `list(map(string))` | <pre>[<br/>  {<br/>    "cidr_block": "0.0.0.0/0",<br/>    "from_port": 0,<br/>    "protocol": "-1",<br/>    "rule_action": "allow",<br/>    "rule_number": 100,<br/>    "to_port": 0<br/>  }<br/>]</pre> | no |
| outpost\_subnet\_assign\_ipv6\_address\_on\_creation | Specify true to indicate that network interfaces created in the specified subnet should be assigned an IPv6 address. Default is `false` | `bool` | `false` | no |
| outpost\_subnet\_enable\_dns64 | Indicates whether DNS queries made to the Amazon-provided DNS Resolver in this subnet should return synthetic IPv6 addresses for IPv4-only destinations. Default: `true` | `bool` | `true` | no |
| outpost\_subnet\_enable\_resource\_name\_dns\_a\_record\_on\_launch | Indicates whether to respond to DNS queries for instance hostnames with DNS A records. Default: `false` | `bool` | `false` | no |
| outpost\_subnet\_enable\_resource\_name\_dns\_aaaa\_record\_on\_launch | Indicates whether to respond to DNS queries for instance hostnames with DNS AAAA records. Default: `true` | `bool` | `true` | no |
| outpost\_subnet\_ipv6\_native | Indicates whether to create an IPv6-only subnet. Default: `false` | `bool` | `false` | no |
| outpost\_subnet\_ipv6\_prefixes | Assigns IPv6 outpost subnet id based on the Amazon provided /56 prefix base 10 integer (0-256). Must be of equal length to the corresponding IPv4 subnet list | `list(string)` | `[]` | no |
| outpost\_subnet\_names | Explicit values to use in the Name tag on outpost subnets. If empty, Name tags are generated | `list(string)` | `[]` | no |
| outpost\_subnet\_private\_dns\_hostname\_type\_on\_launch | The type of hostnames to assign to instances in the subnet at launch. For IPv6-only subnets, an instance DNS name must be based on the instance ID. For dual-stack and IPv4-only subnets, you can specify whether DNS names use the instance IPv4 address or the instance ID. Valid values: `ip-name`, `resource-name` | `string` | `null` | no |
| outpost\_subnet\_suffix | Suffix to append to outpost subnets name | `string` | `"outpost"` | no |
| outpost\_subnet\_tags | Additional tags for the outpost subnets | `map(string)` | `{}` | no |
| outpost\_subnets | A list of outpost subnets inside the VPC | `list(string)` | `[]` | no |
| private\_acl\_tags | Additional tags for the private subnets network ACL | `map(string)` | `{}` | no |
| private\_dedicated\_network\_acl | Whether to use dedicated network ACL (not default) and custom rules for private subnets | `bool` | `false` | no |
| private\_inbound\_acl\_rules | Private subnets inbound network ACLs | `list(map(string))` | <pre>[<br/>  {<br/>    "cidr_block": "0.0.0.0/0",<br/>    "from_port": 0,<br/>    "protocol": "-1",<br/>    "rule_action": "allow",<br/>    "rule_number": 100,<br/>    "to_port": 0<br/>  }<br/>]</pre> | no |
| private\_outbound\_acl\_rules | Private subnets outbound network ACLs | `list(map(string))` | <pre>[<br/>  {<br/>    "cidr_block": "0.0.0.0/0",<br/>    "from_port": 0,<br/>    "protocol": "-1",<br/>    "rule_action": "allow",<br/>    "rule_number": 100,<br/>    "to_port": 0<br/>  }<br/>]</pre> | no |
| private\_route\_table\_tags | Additional tags for the private route tables | `map(string)` | `{}` | no |
| private\_subnet\_assign\_ipv6\_address\_on\_creation | Specify true to indicate that network interfaces created in the specified subnet should be assigned an IPv6 address. Default is `false` | `bool` | `false` | no |
| private\_subnet\_enable\_dns64 | Indicates whether DNS queries made to the Amazon-provided DNS Resolver in this subnet should return synthetic IPv6 addresses for IPv4-only destinations. Default: `true` | `bool` | `true` | no |
| private\_subnet\_enable\_resource\_name\_dns\_a\_record\_on\_launch | Indicates whether to respond to DNS queries for instance hostnames with DNS A records. Default: `false` | `bool` | `false` | no |
| private\_subnet\_enable\_resource\_name\_dns\_aaaa\_record\_on\_launch | Indicates whether to respond to DNS queries for instance hostnames with DNS AAAA records. Default: `true` | `bool` | `true` | no |
| private\_subnet\_ipv6\_native | Indicates whether to create an IPv6-only subnet. Default: `false` | `bool` | `false` | no |
| private\_subnet\_ipv6\_prefixes | Assigns IPv6 private subnet id based on the Amazon provided /56 prefix base 10 integer (0-256). Must be of equal length to the corresponding IPv4 subnet list | `list(string)` | `[]` | no |
| private\_subnet\_names | Explicit values to use in the Name tag on private subnets. If empty, Name tags are generated | `list(string)` | `[]` | no |
| private\_subnet\_private\_dns\_hostname\_type\_on\_launch | The type of hostnames to assign to instances in the subnet at launch. For IPv6-only subnets, an instance DNS name must be based on the instance ID. For dual-stack and IPv4-only subnets, you can specify whether DNS names use the instance IPv4 address or the instance ID. Valid values: `ip-name`, `resource-name` | `string` | `null` | no |
| private\_subnet\_suffix | Suffix to append to private subnets name | `string` | `"private"` | no |
| private\_subnet\_tags | Additional tags for the private subnets | `map(string)` | `{}` | no |
| private\_subnet\_tags\_per\_az | Additional tags for the private subnets where the primary key is the AZ | `map(map(string))` | `{}` | no |
| private\_subnets | A list of private subnets inside the VPC | `list(string)` | `[]` | no |
| propagate\_intra\_route\_tables\_vgw | Should be true if you want route table propagation | `bool` | `false` | no |
| propagate\_private\_route\_tables\_vgw | Should be true if you want route table propagation | `bool` | `false` | no |
| propagate\_public\_route\_tables\_vgw | Should be true if you want route table propagation | `bool` | `false` | no |
| public\_acl\_tags | Additional tags for the public subnets network ACL | `map(string)` | `{}` | no |
| public\_dedicated\_network\_acl | Whether to use dedicated network ACL (not default) and custom rules for public subnets | `bool` | `false` | no |
| public\_inbound\_acl\_rules | Public subnets inbound network ACLs | `list(map(string))` | <pre>[<br/>  {<br/>    "cidr_block": "0.0.0.0/0",<br/>    "from_port": 0,<br/>    "protocol": "-1",<br/>    "rule_action": "allow",<br/>    "rule_number": 100,<br/>    "to_port": 0<br/>  }<br/>]</pre> | no |
| public\_outbound\_acl\_rules | Public subnets outbound network ACLs | `list(map(string))` | <pre>[<br/>  {<br/>    "cidr_block": "0.0.0.0/0",<br/>    "from_port": 0,<br/>    "protocol": "-1",<br/>    "rule_action": "allow",<br/>    "rule_number": 100,<br/>    "to_port": 0<br/>  }<br/>]</pre> | no |
| public\_route\_table\_tags | Additional tags for the public route tables | `map(string)` | `{}` | no |
| public\_subnet\_assign\_ipv6\_address\_on\_creation | Specify true to indicate that network interfaces created in the specified subnet should be assigned an IPv6 address. Default is `false` | `bool` | `false` | no |
| public\_subnet\_enable\_dns64 | Indicates whether DNS queries made to the Amazon-provided DNS Resolver in this subnet should return synthetic IPv6 addresses for IPv4-only destinations. Default: `true` | `bool` | `true` | no |
| public\_subnet\_enable\_resource\_name\_dns\_a\_record\_on\_launch | Indicates whether to respond to DNS queries for instance hostnames with DNS A records. Default: `false` | `bool` | `false` | no |
| public\_subnet\_enable\_resource\_name\_dns\_aaaa\_record\_on\_launch | Indicates whether to respond to DNS queries for instance hostnames with DNS AAAA records. Default: `true` | `bool` | `true` | no |
| public\_subnet\_ipv6\_native | Indicates whether to create an IPv6-only subnet. Default: `false` | `bool` | `false` | no |
| public\_subnet\_ipv6\_prefixes | Assigns IPv6 public subnet id based on the Amazon provided /56 prefix base 10 integer (0-256). Must be of equal length to the corresponding IPv4 subnet list | `list(string)` | `[]` | no |
| public\_subnet\_names | Explicit values to use in the Name tag on public subnets. If empty, Name tags are generated | `list(string)` | `[]` | no |
| public\_subnet\_private\_dns\_hostname\_type\_on\_launch | The type of hostnames to assign to instances in the subnet at launch. For IPv6-only subnets, an instance DNS name must be based on the instance ID. For dual-stack and IPv4-only subnets, you can specify whether DNS names use the instance IPv4 address or the instance ID. Valid values: `ip-name`, `resource-name` | `string` | `null` | no |
| public\_subnet\_suffix | Suffix to append to public subnets name | `string` | `"public"` | no |
| public\_subnet\_tags | Additional tags for the public subnets | `map(string)` | `{}` | no |
| public\_subnet\_tags\_per\_az | Additional tags for the public subnets where the primary key is the AZ | `map(map(string))` | `{}` | no |
| public\_subnets | A list of public subnets inside the VPC | `list(string)` | `[]` | no |
| redshift\_acl\_tags | Additional tags for the redshift subnets network ACL | `map(string)` | `{}` | no |
| redshift\_dedicated\_network\_acl | Whether to use dedicated network ACL (not default) and custom rules for redshift subnets | `bool` | `false` | no |
| redshift\_inbound\_acl\_rules | Redshift subnets inbound network ACL rules | `list(map(string))` | <pre>[<br/>  {<br/>    "cidr_block": "0.0.0.0/0",<br/>    "from_port": 0,<br/>    "protocol": "-1",<br/>    "rule_action": "allow",<br/>    "rule_number": 100,<br/>    "to_port": 0<br/>  }<br/>]</pre> | no |
| redshift\_outbound\_acl\_rules | Redshift subnets outbound network ACL rules | `list(map(string))` | <pre>[<br/>  {<br/>    "cidr_block": "0.0.0.0/0",<br/>    "from_port": 0,<br/>    "protocol": "-1",<br/>    "rule_action": "allow",<br/>    "rule_number": 100,<br/>    "to_port": 0<br/>  }<br/>]</pre> | no |
| redshift\_route\_table\_tags | Additional tags for the redshift route tables | `map(string)` | `{}` | no |
| redshift\_subnet\_assign\_ipv6\_address\_on\_creation | Specify true to indicate that network interfaces created in the specified subnet should be assigned an IPv6 address. Default is `false` | `bool` | `false` | no |
| redshift\_subnet\_enable\_dns64 | Indicates whether DNS queries made to the Amazon-provided DNS Resolver in this subnet should return synthetic IPv6 addresses for IPv4-only destinations. Default: `true` | `bool` | `true` | no |
| redshift\_subnet\_enable\_resource\_name\_dns\_a\_record\_on\_launch | Indicates whether to respond to DNS queries for instance hostnames with DNS A records. Default: `false` | `bool` | `false` | no |
| redshift\_subnet\_enable\_resource\_name\_dns\_aaaa\_record\_on\_launch | Indicates whether to respond to DNS queries for instance hostnames with DNS AAAA records. Default: `true` | `bool` | `true` | no |
| redshift\_subnet\_group\_name | Name of redshift subnet group | `string` | `null` | no |
| redshift\_subnet\_group\_tags | Additional tags for the redshift subnet group | `map(string)` | `{}` | no |
| redshift\_subnet\_ipv6\_native | Indicates whether to create an IPv6-only subnet. Default: `false` | `bool` | `false` | no |
| redshift\_subnet\_ipv6\_prefixes | Assigns IPv6 redshift subnet id based on the Amazon provided /56 prefix base 10 integer (0-256). Must be of equal length to the corresponding IPv4 subnet list | `list(string)` | `[]` | no |
| redshift\_subnet\_names | Explicit values to use in the Name tag on redshift subnets. If empty, Name tags are generated | `list(string)` | `[]` | no |
| redshift\_subnet\_private\_dns\_hostname\_type\_on\_launch | The type of hostnames to assign to instances in the subnet at launch. For IPv6-only subnets, an instance DNS name must be based on the instance ID. For dual-stack and IPv4-only subnets, you can specify whether DNS names use the instance IPv4 address or the instance ID. Valid values: `ip-name`, `resource-name` | `string` | `null` | no |
| redshift\_subnet\_suffix | Suffix to append to redshift subnets name | `string` | `"redshift"` | no |
| redshift\_subnet\_tags | Additional tags for the redshift subnets | `map(string)` | `{}` | no |
| redshift\_subnets | A list of redshift subnets inside the VPC | `list(string)` | `[]` | no |
| reuse\_nat\_ips | Should be true if you don't want EIPs to be created for your NAT Gateways and will instead pass them in via the 'external\_nat\_ip\_ids' variable | `bool` | `false` | no |
| secondary\_cidr\_blocks | List of secondary CIDR blocks to associate with the VPC to extend the IP Address pool | `list(string)` | `[]` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| use\_ipam\_pool | Determines whether IPAM pool is used for CIDR allocation | `bool` | `false` | no |
| vpc\_block\_public\_access\_exclusions | A map of VPC block public access exclusions | <pre>map(object({<br/>    exclude_vpc                     = optional(bool, false)<br/>    exclude_subnet                  = optional(bool, false)<br/>    subnet_type                     = optional(string)<br/>    subnet_index                    = optional(number)<br/>    internet_gateway_exclusion_mode = string<br/>  }))</pre> | `{}` | no |
| vpc\_block\_public\_access\_options | A map of VPC block public access options | `map(string)` | `{}` | no |
| vpc\_flow\_log\_iam\_policy\_name | Name of the IAM policy | `string` | `"vpc-flow-log-to-cloudwatch"` | no |
| vpc\_flow\_log\_iam\_policy\_use\_name\_prefix | Determines whether the name of the IAM policy (`vpc_flow_log_iam_policy_name`) is used as a prefix | `bool` | `true` | no |
| vpc\_flow\_log\_iam\_role\_name | Name to use on the VPC Flow Log IAM role created | `string` | `"vpc-flow-log-role"` | no |
| vpc\_flow\_log\_iam\_role\_use\_name\_prefix | Determines whether the IAM role name (`vpc_flow_log_iam_role_name_name`) is used as a prefix | `bool` | `true` | no |
| vpc\_flow\_log\_permissions\_boundary | The ARN of the Permissions Boundary for the VPC Flow Log IAM Role | `string` | `null` | no |
| vpc\_flow\_log\_tags | Additional tags for the VPC Flow Logs | `map(string)` | `{}` | no |
| vpc\_tags | Additional tags for the VPC | `map(string)` | `{}` | no |
| vpn\_gateway\_az | The Availability Zone for the VPN Gateway | `string` | `null` | no |
| vpn\_gateway\_id | ID of VPN Gateway to attach to the VPC | `string` | `null` | no |
| vpn\_gateway\_tags | Additional tags for the VPN gateway | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| azs | A list of availability zones specified as argument to this module |
| cgw\_arns | List of ARNs of Customer Gateway |
| cgw\_ids | List of IDs of Customer Gateway |
| database\_internet\_gateway\_route\_id | ID of the database internet gateway route |
| database\_ipv6\_egress\_route\_id | ID of the database IPv6 egress route |
| database\_nat\_gateway\_route\_ids | List of IDs of the database nat gateway route |
| database\_network\_acl\_arn | ARN of the database network ACL |
| database\_network\_acl\_id | ID of the database network ACL |
| database\_route\_table\_association\_ids | List of IDs of the database route table association |
| database\_route\_table\_ids | List of IDs of database route tables |
| database\_subnet\_arns | List of ARNs of database subnets |
| database\_subnet\_group | ID of database subnet group |
| database\_subnet\_group\_name | Name of database subnet group |
| database\_subnet\_objects | A list of all database subnets, containing the full objects. |
| database\_subnets | List of IDs of database subnets |
| database\_subnets\_cidr\_blocks | List of cidr\_blocks of database subnets |
| database\_subnets\_ipv6\_cidr\_blocks | List of IPv6 cidr\_blocks of database subnets in an IPv6 enabled VPC |
| default\_network\_acl\_id | The ID of the default network ACL |
| default\_route\_table\_id | The ID of the default route table |
| default\_security\_group\_id | The ID of the security group created by default on VPC creation |
| default\_vpc\_arn | The ARN of the Default VPC |
| default\_vpc\_cidr\_block | The CIDR block of the Default VPC |
| default\_vpc\_default\_network\_acl\_id | The ID of the default network ACL of the Default VPC |
| default\_vpc\_default\_route\_table\_id | The ID of the default route table of the Default VPC |
| default\_vpc\_default\_security\_group\_id | The ID of the security group created by default on Default VPC creation |
| default\_vpc\_enable\_dns\_hostnames | Whether or not the Default VPC has DNS hostname support |
| default\_vpc\_enable\_dns\_support | Whether or not the Default VPC has DNS support |
| default\_vpc\_id | The ID of the Default VPC |
| default\_vpc\_instance\_tenancy | Tenancy of instances spin up within Default VPC |
| default\_vpc\_main\_route\_table\_id | The ID of the main route table associated with the Default VPC |
| dhcp\_options\_id | The ID of the DHCP options |
| egress\_only\_internet\_gateway\_id | The ID of the egress only Internet Gateway |
| elasticache\_network\_acl\_arn | ARN of the elasticache network ACL |
| elasticache\_network\_acl\_id | ID of the elasticache network ACL |
| elasticache\_route\_table\_association\_ids | List of IDs of the elasticache route table association |
| elasticache\_route\_table\_ids | List of IDs of elasticache route tables |
| elasticache\_subnet\_arns | List of ARNs of elasticache subnets |
| elasticache\_subnet\_group | ID of elasticache subnet group |
| elasticache\_subnet\_group\_name | Name of elasticache subnet group |
| elasticache\_subnet\_objects | A list of all elasticache subnets, containing the full objects. |
| elasticache\_subnets | List of IDs of elasticache subnets |
| elasticache\_subnets\_cidr\_blocks | List of cidr\_blocks of elasticache subnets |
| elasticache\_subnets\_ipv6\_cidr\_blocks | List of IPv6 cidr\_blocks of elasticache subnets in an IPv6 enabled VPC |
| igw\_arn | The ARN of the Internet Gateway |
| igw\_id | The ID of the Internet Gateway |
| intra\_network\_acl\_arn | ARN of the intra network ACL |
| intra\_network\_acl\_id | ID of the intra network ACL |
| intra\_route\_table\_association\_ids | List of IDs of the intra route table association |
| intra\_route\_table\_ids | List of IDs of intra route tables |
| intra\_subnet\_arns | List of ARNs of intra subnets |
| intra\_subnet\_objects | A list of all intra subnets, containing the full objects. |
| intra\_subnets | List of IDs of intra subnets |
| intra\_subnets\_cidr\_blocks | List of cidr\_blocks of intra subnets |
| intra\_subnets\_ipv6\_cidr\_blocks | List of IPv6 cidr\_blocks of intra subnets in an IPv6 enabled VPC |
| name | The name of the VPC specified as argument to this module |
| nat\_ids | List of allocation ID of Elastic IPs created for AWS NAT Gateway |
| nat\_public\_ips | List of public Elastic IPs created for AWS NAT Gateway |
| natgw\_ids | List of NAT Gateway IDs |
| natgw\_interface\_ids | List of Network Interface IDs assigned to NAT Gateways |
| outpost\_network\_acl\_arn | ARN of the outpost network ACL |
| outpost\_network\_acl\_id | ID of the outpost network ACL |
| outpost\_subnet\_arns | List of ARNs of outpost subnets |
| outpost\_subnet\_objects | A list of all outpost subnets, containing the full objects. |
| outpost\_subnets | List of IDs of outpost subnets |
| outpost\_subnets\_cidr\_blocks | List of cidr\_blocks of outpost subnets |
| outpost\_subnets\_ipv6\_cidr\_blocks | List of IPv6 cidr\_blocks of outpost subnets in an IPv6 enabled VPC |
| private\_ipv6\_egress\_route\_ids | List of IDs of the ipv6 egress route |
| private\_nat\_gateway\_route\_ids | List of IDs of the private nat gateway route |
| private\_network\_acl\_arn | ARN of the private network ACL |
| private\_network\_acl\_id | ID of the private network ACL |
| private\_route\_table\_association\_ids | List of IDs of the private route table association |
| private\_route\_table\_ids | List of IDs of private route tables |
| private\_subnet\_arns | List of ARNs of private subnets |
| private\_subnet\_objects | A list of all private subnets, containing the full objects. |
| private\_subnets | List of IDs of private subnets |
| private\_subnets\_cidr\_blocks | List of cidr\_blocks of private subnets |
| private\_subnets\_ipv6\_cidr\_blocks | List of IPv6 cidr\_blocks of private subnets in an IPv6 enabled VPC |
| public\_internet\_gateway\_ipv6\_route\_id | ID of the IPv6 internet gateway route |
| public\_internet\_gateway\_route\_id | ID of the internet gateway route |
| public\_network\_acl\_arn | ARN of the public network ACL |
| public\_network\_acl\_id | ID of the public network ACL |
| public\_route\_table\_association\_ids | List of IDs of the public route table association |
| public\_route\_table\_ids | List of IDs of public route tables |
| public\_subnet\_arns | List of ARNs of public subnets |
| public\_subnet\_objects | A list of all public subnets, containing the full objects. |
| public\_subnets | List of IDs of public subnets |
| public\_subnets\_cidr\_blocks | List of cidr\_blocks of public subnets |
| public\_subnets\_ipv6\_cidr\_blocks | List of IPv6 cidr\_blocks of public subnets in an IPv6 enabled VPC |
| redshift\_network\_acl\_arn | ARN of the redshift network ACL |
| redshift\_network\_acl\_id | ID of the redshift network ACL |
| redshift\_public\_route\_table\_association\_ids | List of IDs of the public redshift route table association |
| redshift\_route\_table\_association\_ids | List of IDs of the redshift route table association |
| redshift\_route\_table\_ids | List of IDs of redshift route tables |
| redshift\_subnet\_arns | List of ARNs of redshift subnets |
| redshift\_subnet\_group | ID of redshift subnet group |
| redshift\_subnet\_objects | A list of all redshift subnets, containing the full objects. |
| redshift\_subnets | List of IDs of redshift subnets |
| redshift\_subnets\_cidr\_blocks | List of cidr\_blocks of redshift subnets |
| redshift\_subnets\_ipv6\_cidr\_blocks | List of IPv6 cidr\_blocks of redshift subnets in an IPv6 enabled VPC |
| this\_customer\_gateway | Map of Customer Gateway attributes |
| vgw\_arn | The ARN of the VPN Gateway |
| vgw\_id | The ID of the VPN Gateway |
| vpc\_arn | The ARN of the VPC |
| vpc\_block\_public\_access\_exclusions | A map of VPC block public access exclusions |
| vpc\_cidr\_block | The CIDR block of the VPC |
| vpc\_enable\_dns\_hostnames | Whether or not the VPC has DNS hostname support |
| vpc\_enable\_dns\_support | Whether or not the VPC has DNS support |
| vpc\_flow\_log\_cloudwatch\_iam\_role\_arn | The ARN of the IAM role used when pushing logs to Cloudwatch log group |
| vpc\_flow\_log\_deliver\_cross\_account\_role | The ARN of the IAM role used when pushing logs cross account |
| vpc\_flow\_log\_destination\_arn | The ARN of the destination for VPC Flow Logs |
| vpc\_flow\_log\_destination\_type | The type of the destination for VPC Flow Logs |
| vpc\_flow\_log\_id | The ID of the Flow Log resource |
| vpc\_id | The ID of the VPC |
| vpc\_instance\_tenancy | Tenancy of instances spin up within VPC |
| vpc\_ipv6\_association\_id | The association ID for the IPv6 CIDR block |
| vpc\_ipv6\_cidr\_block | The IPv6 CIDR block |
| vpc\_main\_route\_table\_id | The ID of the main route table associated with this VPC |
| vpc\_owner\_id | The ID of the AWS account that owns the VPC |
| vpc\_secondary\_cidr\_blocks | List of secondary CIDR blocks of the VPC |
<!-- END_TF_DOCS -->

</details>
