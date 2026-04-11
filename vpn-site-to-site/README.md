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
