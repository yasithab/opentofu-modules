# VPN Site-to-Site

OpenTofu module to create a complete AWS Site-to-Site VPN connection including customer gateway, virtual private gateway, VPN connection with dual tunnels, CloudWatch logging, and static route management.

## Features

- **Customer Gateway** - Creates a customer gateway with configurable BGP ASN (standard or extended), IP address, device name, and optional ACM certificate authentication
- **Virtual Private Gateway** - Creates a VPN gateway attached to a VPC with optional Amazon-side ASN and availability zone configuration
- **Transit Gateway Support** - Optionally connect through an EC2 Transit Gateway instead of a virtual private gateway, with support for acceleration and IPv6
- **Dual Tunnel Configuration** - Full control over both VPN tunnels including IKE versions, phase 1/2 encryption algorithms, integrity algorithms, DH group numbers, lifetime seconds, preshared keys, DPD timeout behavior, rekey settings, and replay window sizes
- **CloudWatch Logging** - Integrated CloudWatch log group for VPN tunnel activity logs with configurable retention, KMS encryption, log class, and deletion protection
- **BGP Logging** - Optional BGP-specific log delivery to CloudWatch for each tunnel with independent log group and output format settings
- **Static Routes** - Manage VPN connection static routes for destination CIDR blocks when not using BGP
- **Route Propagation** - Automatically propagate VPN gateway routes to specified VPC route tables
- **Tunnel Lifecycle Control** - Optional tunnel endpoint lifecycle control for each tunnel
- **Preshared Key Storage** - Choose between standard storage or AWS Secrets Manager for tunnel preshared keys
- **Tunnel Bandwidth** - Configurable tunnel bandwidth (standard or large)
- **Private VPN** - Support for private Site-to-Site VPN over AWS Direct Connect using PrivateIpv4 addressing
- **Lifecycle Management** - Toggle resource creation on or off with the `enabled` variable

## Usage

```hcl
module "vpn" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpn-site-to-site?depth=1&ref=master"

  customer_gateway_bgp_asn    = 65000
  customer_gateway_ip_address = "203.0.113.1"

  virtual_private_gateway_vpc_id = "vpc-0abc123def456789"

  vpn_connection_static_routes_only          = true
  vpn_connection_route_destination_cidr_block = ["10.0.0.0/16"]

  vpn_connection_cloudwatch_log_group_name = "/aws/vpn/my-connection"
  vpn_connection_tunnel1_log_enabled       = true
  vpn_connection_tunnel2_log_enabled       = true

  route_propagation_route_table_ids = ["rtb-0abc123def456789"]

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
| customer\_gateway\_bgp\_asn | (Optional) The ASN of your customer gateway device. Valid values are in the range 1-2,147,483,647. Conflicts with bgp\_asn\_extended. | `number` | `null` | no |
| customer\_gateway\_bgp\_asn\_extended | (Optional, Forces new resource) The gateway's Border Gateway Protocol (BGP) Autonomous System Number (ASN). Valid values are from 2147483648 to 4294967295. Conflicts with bgp\_asn. | `number` | `null` | no |
| customer\_gateway\_certificate\_arn | (Optional) The ARN of a private certificate provisioned in AWS Certificate Manager (ACM). | `string` | `null` | no |
| customer\_gateway\_device\_name | (Optional) Enter a name for the customer gateway device. | `string` | `null` | no |
| customer\_gateway\_ip\_address | Specify the internet-routable IP address for your gateway's external interface; the address must be static and may be behind a device performing network address translation (NAT). | `string` | `null` | no |
| customer\_gateway\_type | (Required) The type of customer gateway. The only type AWS supports at this time is "ipsec.1". | `string` | `"ipsec.1"` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| name | Name to use for resource naming and tagging. | `string` | `null` | no |
| route\_propagation\_route\_table\_ids | (Optional)The IDs of the route tables for which routes from the Virtual Private Gateway will be propagated | `list(string)` | `[]` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| virtual\_private\_gateway\_amazon\_side\_asn | (Optional) The Autonomous System Number (ASN) for the Amazon side of the gateway. If you don't specify an ASN, the virtual private gateway is created with the default ASN. | `number` | `null` | no |
| virtual\_private\_gateway\_availability\_zone | (Optional) The Availability Zone for the virtual private gateway. | `string` | `null` | no |
| virtual\_private\_gateway\_vpc\_id | (Optional) The VPC to attach to the virtual private gateway. Required when not using a Transit Gateway. | `string` | `null` | no |
| vpn\_connection\_cloudwatch\_log\_group\_class | (Optional) Specifies the log class of the log group. Possible values are: STANDARD or INFREQUENT\_ACCESS. | `string` | `"STANDARD"` | no |
| vpn\_connection\_cloudwatch\_log\_group\_deletion\_protection\_enabled | (Optional) Whether to enable deletion protection for the CloudWatch log group. | `bool` | `true` | no |
| vpn\_connection\_cloudwatch\_log\_group\_kms\_key\_id | (Optional) The ARN of the KMS Key to use when encrypting log data. Please note, after the AWS KMS CMK is disassociated from the log group, AWS CloudWatch Logs stops encrypting newly ingested data for the log group. All previously ingested data remains encrypted, and AWS CloudWatch Logs requires permissions for the CMK whenever the encrypted data is requested. | `string` | `null` | no |
| vpn\_connection\_cloudwatch\_log\_group\_name | (Optional, Forces new resource) The name of the log group. If omitted, Terraform will assign a random, unique name. | `string` | `null` | no |
| vpn\_connection\_cloudwatch\_log\_group\_name\_prefix | (Optional, Forces new resource) Creates a unique name beginning with the specified prefix. Conflicts with name. | `string` | `null` | no |
| vpn\_connection\_cloudwatch\_log\_group\_skip\_destroy | (Optional) Set to true if you do not wish the log group (and any logs it may contain) to be deleted at destroy time, and instead just remove the log group from the Terraform state. | `bool` | `true` | no |
| vpn\_connection\_cloudwatch\_log\_retention\_in\_days | (Optional) Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653, and 0. If you select 0, the events in the log group are always retained and never expire. | `number` | `30` | no |
| vpn\_connection\_enable\_acceleration | (Optional, Default false) Indicate whether to enable acceleration for the VPN connection. Supports only EC2 Transit Gateway. | `bool` | `false` | no |
| vpn\_connection\_local\_ipv4\_network\_cidr | (Optional, Default 0.0.0.0/0) The IPv4 CIDR on the customer gateway (on-premises) side of the VPN connection. | `string` | `null` | no |
| vpn\_connection\_local\_ipv6\_network\_cidr | (Optional, Default ::/0) The IPv6 CIDR on the customer gateway (on-premises) side of the VPN connection. | `string` | `null` | no |
| vpn\_connection\_outside\_ip\_address\_type | (Optional, Default PublicIpv4) Indicates if a Public S2S VPN or Private S2S VPN over AWS Direct Connect. Valid values are PublicIpv4 \| PrivateIpv4 | `string` | `"PublicIpv4"` | no |
| vpn\_connection\_preshared\_key\_storage | (Optional) Storage location for VPN tunnel pre-shared keys. Valid values are Standard or SecretsManager. | `string` | `"SecretsManager"` | no |
| vpn\_connection\_remote\_ipv4\_network\_cidr | (Optional, Default 0.0.0.0/0) The IPv4 CIDR on the AWS side of the VPN connection. | `string` | `null` | no |
| vpn\_connection\_remote\_ipv6\_network\_cidr | (Optional, Default ::/0) The IPv6 CIDR on the customer gateway (on-premises) side of the VPN connection. | `string` | `null` | no |
| vpn\_connection\_route\_destination\_cidr\_block | (Required) The CIDR block associated with the local subnet of the customer network. | `list(string)` | `[]` | no |
| vpn\_connection\_static\_routes\_only | (Optional, Default false) Whether the VPN connection uses static routes exclusively. Static routes must be used for devices that don't support BGP. | `bool` | `false` | no |
| vpn\_connection\_transit\_gateway\_id | (Optional) The ID of the EC2 Transit Gateway. | `string` | `null` | no |
| vpn\_connection\_transport\_transit\_gateway\_attachment\_id | (Required when outside\_ip\_address\_type is set to PrivateIpv4). The attachment ID of the Transit Gateway attachment to Direct Connect Gateway. The ID is obtained through a data source only. | `string` | `null` | no |
| vpn\_connection\_tunnel1\_dpd\_timeout\_action | (Optional, Default clear) The action to take after DPD timeout occurs for the first VPN tunnel. Specify restart to restart the IKE initiation. Specify clear to end the IKE session. Valid values are clear \| none \| restart. | `string` | `"restart"` | no |
| vpn\_connection\_tunnel1\_dpd\_timeout\_seconds | (Optional, Default 30) The number of seconds after which a DPD timeout occurs for the second VPN tunnel. Valid value is equal or higher than 30. | `number` | `30` | no |
| vpn\_connection\_tunnel1\_enable\_tunnel\_lifecycle\_control | (Optional) Turn on or off tunnel endpoint lifecycle control feature for the first VPN tunnel. | `bool` | `false` | no |
| vpn\_connection\_tunnel1\_ike\_versions | (Optional) The IKE versions that are permitted for the first VPN tunnel. Valid values are ikev1 \| ikev2. | `set(string)` | <pre>[<br/>  "ikev2"<br/>]</pre> | no |
| vpn\_connection\_tunnel1\_inside\_cidr | (Optional) The CIDR block of the inside IP addresses for the first VPN tunnel. Valid value is a size /30 CIDR block from the 169.254.0.0/16 range. | `string` | `null` | no |
| vpn\_connection\_tunnel1\_inside\_ipv6\_cidr | (Optional) The range of inside IPv6 addresses for the first VPN tunnel. Supports only EC2 Transit Gateway. Valid value is a size /126 CIDR block from the local fd00::/8 range. | `string` | `null` | no |
| vpn\_connection\_tunnel1\_log\_bgp\_enabled | Enable BGP log delivery to CloudWatch for tunnel 1 | `bool` | `null` | no |
| vpn\_connection\_tunnel1\_log\_bgp\_group\_arn | ARN of the CloudWatch log group for BGP logs for tunnel 1 | `string` | `null` | no |
| vpn\_connection\_tunnel1\_log\_bgp\_output\_format | The output format for BGP logs for tunnel 1. Valid values are json or text. | `string` | `null` | no |
| vpn\_connection\_tunnel1\_log\_enabled | (Optional) Enable logs for VPN tunnel activity. | `bool` | `false` | no |
| vpn\_connection\_tunnel1\_log\_output\_format | (Optional) Enable logs for VPN tunnel activity. | `string` | `"json"` | no |
| vpn\_connection\_tunnel1\_phase1\_dh\_group\_numbers | (Optional) List of one or more Diffie-Hellman group numbers that are permitted for the first VPN tunnel for phase 1 IKE negotiations. Valid values are 2 \| 14 \| 15 \| 16 \| 17 \| 18 \| 19 \| 20 \| 21 \| 22 \| 23 \| 24. | `set(number)` | <pre>[<br/>  14,<br/>  15,<br/>  16,<br/>  17,<br/>  18,<br/>  19,<br/>  20,<br/>  21,<br/>  22,<br/>  23,<br/>  24<br/>]</pre> | no |
| vpn\_connection\_tunnel1\_phase1\_encryption\_algorithms | (Optional) List of one or more encryption algorithms that are permitted for the first VPN tunnel for phase 1 IKE negotiations. Valid values are AES128 \| AES256 \| AES128-GCM-16 \| AES256-GCM-16. | `set(string)` | <pre>[<br/>  "AES256",<br/>  "AES256-GCM-16"<br/>]</pre> | no |
| vpn\_connection\_tunnel1\_phase1\_integrity\_algorithms | (Optional) One or more integrity algorithms that are permitted for the first VPN tunnel for phase 1 IKE negotiations. Valid values are SHA1 \| SHA2-256 \| SHA2-384 \| SHA2-512. | `set(string)` | <pre>[<br/>  "SHA2-256",<br/>  "SHA2-384",<br/>  "SHA2-512"<br/>]</pre> | no |
| vpn\_connection\_tunnel1\_phase1\_lifetime\_seconds | (Optional, Default 28800) The lifetime for phase 1 of the IKE negotiation for the first VPN tunnel, in seconds. Valid value is between 900 and 28800. | `number` | `28800` | no |
| vpn\_connection\_tunnel1\_phase2\_dh\_group\_numbers | (Optional) List of one or more Diffie-Hellman group numbers that are permitted for the first VPN tunnel for phase 2 IKE negotiations. Valid values are 2 \| 5 \| 14 \| 15 \| 16 \| 17 \| 18 \| 19 \| 20 \| 21 \| 22 \| 23 \| 24. | `set(number)` | <pre>[<br/>  14,<br/>  15,<br/>  16,<br/>  17,<br/>  18,<br/>  19,<br/>  20,<br/>  21,<br/>  22,<br/>  23,<br/>  24<br/>]</pre> | no |
| vpn\_connection\_tunnel1\_phase2\_encryption\_algorithms | (Optional) List of one or more encryption algorithms that are permitted for the first VPN tunnel for phase 2 IKE negotiations. Valid values are AES128 \| AES256 \| AES128-GCM-16 \| AES256-GCM-16. | `list(string)` | <pre>[<br/>  "AES256",<br/>  "AES256-GCM-16"<br/>]</pre> | no |
| vpn\_connection\_tunnel1\_phase2\_integrity\_algorithms | (Optional) List of one or more integrity algorithms that are permitted for the first VPN tunnel for phase 2 IKE negotiations. Valid values are SHA1 \| SHA2-256 \| SHA2-384 \| SHA2-512. | `list(string)` | <pre>[<br/>  "SHA2-256",<br/>  "SHA2-384",<br/>  "SHA2-512"<br/>]</pre> | no |
| vpn\_connection\_tunnel1\_phase2\_lifetime\_seconds | (Optional, Default 3600) The lifetime for phase 2 of the IKE negotiation for the first VPN tunnel, in seconds. Valid value is between 900 and 3600. | `number` | `3600` | no |
| vpn\_connection\_tunnel1\_preshared\_key | (Optional) The preshared key of the first VPN tunnel. The preshared key must be between 8 and 64 characters in length and cannot start with zero(0). Allowed characters are alphanumeric characters, periods(.) and underscores(\_). | `string` | `null` | no |
| vpn\_connection\_tunnel1\_rekey\_fuzz\_percentage | (Optional, Default 100) The percentage of the rekey window for the first VPN tunnel (determined by tunnel1\_rekey\_margin\_time\_seconds) during which the rekey time is randomly selected. Valid value is between 0 and 100. | `number` | `100` | no |
| vpn\_connection\_tunnel1\_rekey\_margin\_time\_seconds | (Optional, Default 540) The margin time, in seconds, before the phase 2 lifetime expires, during which the AWS side of the first VPN connection performs an IKE rekey. The exact time of the rekey is randomly selected based on the value for tunnel1\_rekey\_fuzz\_percentage. Valid value is between 60 and half of tunnel1\_phase2\_lifetime\_seconds. | `number` | `540` | no |
| vpn\_connection\_tunnel1\_replay\_window\_size | (Optional, Default 1024) The number of packets in an IKE replay window for the first VPN tunnel. Valid value is between 64 and 2048. | `number` | `1024` | no |
| vpn\_connection\_tunnel1\_startup\_action | (Optional, Default add) The action to take when the establishing the tunnel for the first VPN connection. By default, your customer gateway device must initiate the IKE negotiation and bring up the tunnel. Specify start for AWS to initiate the IKE negotiation. Valid values are add \| start. | `string` | `"add"` | no |
| vpn\_connection\_tunnel2\_dpd\_timeout\_action | (Optional, Default clear) The action to take after DPD timeout occurs for the second VPN tunnel. Specify restart to restart the IKE initiation. Specify clear to end the IKE session. Valid values are clear \| none \| restart. | `string` | `"restart"` | no |
| vpn\_connection\_tunnel2\_dpd\_timeout\_seconds | (Optional, Default 30) The number of seconds after which a DPD timeout occurs for the second VPN tunnel. Valid value is equal or higher than 30. | `number` | `30` | no |
| vpn\_connection\_tunnel2\_enable\_tunnel\_lifecycle\_control | (Optional) Turn on or off tunnel endpoint lifecycle control feature for the second VPN tunnel. | `bool` | `false` | no |
| vpn\_connection\_tunnel2\_ike\_versions | (Optional) The IKE versions that are permitted for the second VPN tunnel. Valid values are ikev1 \| ikev2. | `set(string)` | <pre>[<br/>  "ikev2"<br/>]</pre> | no |
| vpn\_connection\_tunnel2\_inside\_cidr | (Optional) The CIDR block of the inside IP addresses for the second VPN tunnel. Valid value is a size /30 CIDR block from the 169.254.0.0/16 range. | `string` | `null` | no |
| vpn\_connection\_tunnel2\_inside\_ipv6\_cidr | (Optional) The range of inside IPv6 addresses for the second VPN tunnel. Supports only EC2 Transit Gateway. Valid value is a size /126 CIDR block from the local fd00::/8 range. | `string` | `null` | no |
| vpn\_connection\_tunnel2\_log\_bgp\_enabled | Enable BGP log delivery to CloudWatch for tunnel 2 | `bool` | `null` | no |
| vpn\_connection\_tunnel2\_log\_bgp\_group\_arn | ARN of the CloudWatch log group for BGP logs for tunnel 2 | `string` | `null` | no |
| vpn\_connection\_tunnel2\_log\_bgp\_output\_format | The output format for BGP logs for tunnel 2. Valid values are json or text. | `string` | `null` | no |
| vpn\_connection\_tunnel2\_log\_enabled | (Optional) Enable logs for VPN tunnel activity. | `bool` | `false` | no |
| vpn\_connection\_tunnel2\_log\_output\_format | (Optional) Enable logs for VPN tunnel activity. | `string` | `"json"` | no |
| vpn\_connection\_tunnel2\_phase1\_dh\_group\_numbers | (Optional) List of one or more Diffie-Hellman group numbers that are permitted for the second VPN tunnel for phase 1 IKE negotiations. Valid values are 2 \| 14 \| 15 \| 16 \| 17 \| 18 \| 19 \| 20 \| 21 \| 22 \| 23 \| 24. | `set(number)` | <pre>[<br/>  14,<br/>  15,<br/>  16,<br/>  17,<br/>  18,<br/>  19,<br/>  20,<br/>  21,<br/>  22,<br/>  23,<br/>  24<br/>]</pre> | no |
| vpn\_connection\_tunnel2\_phase1\_encryption\_algorithms | (Optional) List of one or more encryption algorithms that are permitted for the second VPN tunnel for phase 1 IKE negotiations. Valid values are AES128 \| AES256 \| AES128-GCM-16 \| AES256-GCM-16. | `set(string)` | <pre>[<br/>  "AES256",<br/>  "AES256-GCM-16"<br/>]</pre> | no |
| vpn\_connection\_tunnel2\_phase1\_integrity\_algorithms | (Optional) One or more integrity algorithms that are permitted for the second VPN tunnel for phase 1 IKE negotiations. Valid values are SHA1 \| SHA2-256 \| SHA2-384 \| SHA2-512. | `set(string)` | <pre>[<br/>  "SHA2-256",<br/>  "SHA2-384",<br/>  "SHA2-512"<br/>]</pre> | no |
| vpn\_connection\_tunnel2\_phase1\_lifetime\_seconds | (Optional, Default 28800) The lifetime for phase 1 of the IKE negotiation for the second VPN tunnel, in seconds. Valid value is between 900 and 28800. | `number` | `28800` | no |
| vpn\_connection\_tunnel2\_phase2\_dh\_group\_numbers | (Optional) List of one or more Diffie-Hellman group numbers that are permitted for the second VPN tunnel for phase 2 IKE negotiations. Valid values are 2 \| 5 \| 14 \| 15 \| 16 \| 17 \| 18 \| 19 \| 20 \| 21 \| 22 \| 23 \| 24. | `set(number)` | <pre>[<br/>  14,<br/>  15,<br/>  16,<br/>  17,<br/>  18,<br/>  19,<br/>  20,<br/>  21,<br/>  22,<br/>  23,<br/>  24<br/>]</pre> | no |
| vpn\_connection\_tunnel2\_phase2\_encryption\_algorithms | (Optional) List of one or more encryption algorithms that are permitted for the second VPN tunnel for phase 2 IKE negotiations. Valid values are AES128 \| AES256 \| AES128-GCM-16 \| AES256-GCM-16. | `list(string)` | <pre>[<br/>  "AES256",<br/>  "AES256-GCM-16"<br/>]</pre> | no |
| vpn\_connection\_tunnel2\_phase2\_integrity\_algorithms | (Optional) List of one or more integrity algorithms that are permitted for the second VPN tunnel for phase 2 IKE negotiations. Valid values are SHA1 \| SHA2-256 \| SHA2-384 \| SHA2-512. | `list(string)` | <pre>[<br/>  "SHA2-256",<br/>  "SHA2-384",<br/>  "SHA2-512"<br/>]</pre> | no |
| vpn\_connection\_tunnel2\_phase2\_lifetime\_seconds | (Optional, Default 3600) The lifetime for phase 2 of the IKE negotiation for the second VPN tunnel, in seconds. Valid value is between 900 and 3600. | `number` | `3600` | no |
| vpn\_connection\_tunnel2\_preshared\_key | (Optional) The preshared key of the second VPN tunnel. The preshared key must be between 8 and 64 characters in length and cannot start with zero(0). Allowed characters are alphanumeric characters, periods(.) and underscores(\_). | `string` | `null` | no |
| vpn\_connection\_tunnel2\_rekey\_fuzz\_percentage | (Optional, Default 100) The percentage of the rekey window for the second VPN tunnel (determined by tunnel2\_rekey\_margin\_time\_seconds) during which the rekey time is randomly selected. Valid value is between 0 and 100. | `number` | `100` | no |
| vpn\_connection\_tunnel2\_rekey\_margin\_time\_seconds | (Optional, Default 540) The margin time, in seconds, before the phase 2 lifetime expires, during which the AWS side of the second VPN connection performs an IKE rekey. The exact time of the rekey is randomly selected based on the value for tunnel2\_rekey\_fuzz\_percentage. Valid value is between 60 and half of tunnel2\_phase2\_lifetime\_seconds. | `number` | `540` | no |
| vpn\_connection\_tunnel2\_replay\_window\_size | (Optional, Default 1024) The number of packets in an IKE replay window for the second VPN tunnel. Valid value is between 64 and 2048. | `number` | `1024` | no |
| vpn\_connection\_tunnel2\_startup\_action | (Optional, Default add) The action to take when the establishing the tunnel for the second VPN connection. By default, your customer gateway device must initiate the IKE negotiation and bring up the tunnel. Specify start for AWS to initiate the IKE negotiation. Valid values are add \| start. | `string` | `"add"` | no |
| vpn\_connection\_tunnel\_bandwidth | (Optional) The bandwidth of the VPN tunnels. Valid values are standard or large. | `string` | `null` | no |
| vpn\_connection\_tunnel\_inside\_ip\_version | (Optional, Default ipv4) Indicate whether the VPN tunnels process IPv4 or IPv6 traffic. Valid values are ipv4 \| ipv6. ipv6 Supports only EC2 Transit Gateway. | `string` | `"ipv4"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| cloudwatch\_log\_group\_arn | The ARN of the CloudWatch Log Group for VPN connection logs |
| cloudwatch\_log\_group\_name | The name of the CloudWatch Log Group for VPN connection logs |
| customer\_gateway\_arn | The ARN of the Customer Gateway |
| customer\_gateway\_id | The ID of the Customer Gateway |
| vpn\_connection\_arn | Amazon Resource Name (ARN) value of the connection |
| vpn\_connection\_customer\_gateway\_configuration | The configuration information for the VPN connection's customer gateway (in the native XML format) |
| vpn\_connection\_id | The ID of the VPN Connection |
| vpn\_connection\_tunnel1\_address | The public IP address of the first VPN tunnel |
| vpn\_connection\_tunnel1\_cgw\_inside\_address | The RFC 6890 link-local address of the first VPN tunnel (Customer Gateway Side) |
| vpn\_connection\_tunnel1\_vgw\_inside\_address | The RFC 6890 link-local address of the first VPN tunnel (VPN Gateway Side) |
| vpn\_connection\_tunnel2\_address | The public IP address of the second VPN tunnel |
| vpn\_connection\_tunnel2\_cgw\_inside\_address | The RFC 6890 link-local address of the second VPN tunnel (Customer Gateway Side) |
| vpn\_connection\_tunnel2\_vgw\_inside\_address | The RFC 6890 link-local address of the second VPN tunnel (VPN Gateway Side) |
| vpn\_gateway\_id | The ID of the VPN Gateway |
<!-- END_TF_DOCS -->

## Examples

## Basic Usage

Create a VPN connection to an on-premises customer gateway via a Virtual Private Gateway.

```hcl
module "vpn" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpn-site-to-site?depth=1&ref=master"

  enabled = true

  customer_gateway_ip_address = "203.0.113.10"
  customer_gateway_bgp_asn    = 65000
  customer_gateway_type       = "ipsec.1"

  virtual_private_gateway_vpc_id = "vpc-0a1b2c3d4e5f67890"

  tags = {
    Team        = "platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Via Transit Gateway with Static Routes

Connect to a Transit Gateway using static routes only (for devices that don't support BGP).

```hcl
module "vpn_tgw" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpn-site-to-site?depth=1&ref=master"

  enabled = true

  customer_gateway_ip_address  = "203.0.113.25"
  customer_gateway_bgp_asn     = 65100
  customer_gateway_device_name = "datacenter-firewall"

  vpn_connection_transit_gateway_id  = "tgw-0a1b2c3d4e5f67890"
  vpn_connection_static_routes_only  = true
  vpn_connection_route_destination_cidr_block = [
    "192.168.0.0/24",
    "192.168.1.0/24",
  ]

  vpn_connection_cloudwatch_log_group_name       = "/aws/vpn/datacenter-firewall"
  vpn_connection_cloudwatch_log_retention_in_days = 30

  tags = {
    Team        = "platform"
    Environment = "production"
    Purpose     = "datacenter-connectivity"
    ManagedBy   = "terraform"
  }
}
```

## With Tunnel Logging and Custom IKE Parameters

Configure a high-security VPN tunnel with IKEv2 only, strong cipher suites, and tunnel logging.

```hcl
module "vpn_secure" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpn-site-to-site?depth=1&ref=master"

  enabled = true

  customer_gateway_ip_address  = "203.0.113.50"
  customer_gateway_bgp_asn     = 65200
  customer_gateway_device_name = "hq-vpn-gateway"

  virtual_private_gateway_vpc_id    = "vpc-0b2c3d4e5f6789abc"
  virtual_private_gateway_amazon_side_asn = 64512

  route_propagation_route_table_ids = [
    "rtb-0a1b2c3d4e5f67891",
    "rtb-0a1b2c3d4e5f67892",
  ]

  vpn_connection_tunnel1_ike_versions = ["ikev2"]
  vpn_connection_tunnel2_ike_versions = ["ikev2"]

  vpn_connection_tunnel1_phase1_encryption_algorithms = ["AES256-GCM-16"]
  vpn_connection_tunnel2_phase1_encryption_algorithms = ["AES256-GCM-16"]
  vpn_connection_tunnel1_phase2_encryption_algorithms = ["AES256-GCM-16"]
  vpn_connection_tunnel2_phase2_encryption_algorithms = ["AES256-GCM-16"]

  vpn_connection_tunnel1_phase1_integrity_algorithms = ["SHA2-512"]
  vpn_connection_tunnel2_phase1_integrity_algorithms = ["SHA2-512"]
  vpn_connection_tunnel1_phase2_integrity_algorithms = ["SHA2-512"]
  vpn_connection_tunnel2_phase2_integrity_algorithms = ["SHA2-512"]

  vpn_connection_tunnel1_phase1_dh_group_numbers = [20, 21]
  vpn_connection_tunnel2_phase1_dh_group_numbers = [20, 21]
  vpn_connection_tunnel1_phase2_dh_group_numbers = [20, 21]
  vpn_connection_tunnel2_phase2_dh_group_numbers = [20, 21]

  vpn_connection_tunnel1_startup_action = "start"
  vpn_connection_tunnel2_startup_action = "start"

  vpn_connection_tunnel1_dpd_timeout_action = "restart"
  vpn_connection_tunnel2_dpd_timeout_action = "restart"

  vpn_connection_tunnel1_log_enabled       = true
  vpn_connection_tunnel1_log_output_format = "json"
  vpn_connection_tunnel2_log_enabled       = true
  vpn_connection_tunnel2_log_output_format = "json"

  vpn_connection_cloudwatch_log_group_name       = "/aws/vpn/hq-vpn-gateway"
  vpn_connection_cloudwatch_log_retention_in_days = 90
  vpn_connection_cloudwatch_log_group_class      = "STANDARD"

  tags = {
    Team        = "security"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## With Pre-Shared Keys Stored in Secrets Manager and Accelerated VPN

Store tunnel pre-shared keys in Secrets Manager and enable accelerated VPN via Global Accelerator.

```hcl
module "vpn_accelerated" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpn-site-to-site?depth=1&ref=master"

  enabled = true

  customer_gateway_ip_address = "203.0.113.75"
  customer_gateway_bgp_asn    = 65300

  vpn_connection_transit_gateway_id   = "tgw-0a1b2c3d4e5f67890"
  vpn_connection_enable_acceleration  = true
  vpn_connection_preshared_key_storage = "SecretsManager"
  vpn_connection_tunnel_bandwidth     = "large"

  vpn_connection_tunnel1_inside_cidr = "169.254.10.0/30"
  vpn_connection_tunnel2_inside_cidr = "169.254.11.0/30"

  vpn_connection_tunnel1_startup_action = "start"
  vpn_connection_tunnel2_startup_action = "start"

  vpn_connection_tunnel1_enable_tunnel_lifecycle_control = true
  vpn_connection_tunnel2_enable_tunnel_lifecycle_control = true

  vpn_connection_cloudwatch_log_group_name       = "/aws/vpn/accelerated-vpn"
  vpn_connection_cloudwatch_log_retention_in_days = 30

  tags = {
    Team        = "platform"
    Environment = "production"
    Purpose     = "accelerated-hybrid-connectivity"
    ManagedBy   = "terraform"
  }
}
```

## Notes

- `name` is optional; when set it is merged into all resource tags as `Name`.
- `customer_gateway_ip_address` and one of `customer_gateway_bgp_asn` / `customer_gateway_bgp_asn_extended` are required when the module is enabled (validated at plan time).
- **Breaking (security hardening):** tunnel phase 1/2 defaults now allow only DH groups >= 14, SHA-2 integrity algorithms, and AES256 / AES256-GCM-16 encryption; `ike_versions` defaults to `["ikev2"]`. Set the corresponding variables explicitly if your device needs legacy parameters.
- **Breaking:** `vpn_connection_preshared_key_storage` now defaults to `"SecretsManager"`.
- The CloudWatch log group is only created when tunnel logging is enabled, and its deletion protection defaults to `true`.
- A virtual private gateway is only created when `vpn_connection_transit_gateway_id` is not set (TGW mode skips it).
