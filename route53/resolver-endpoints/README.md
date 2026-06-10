# Route 53 Resolver Endpoints

Provisions AWS Route 53 Resolver endpoints for forwarding DNS queries between your VPC and on-premises networks, with optional security group creation and management.

## Features

- **Inbound, Outbound, and Bidirectional** - Supports all three resolver endpoint directions for flexible hybrid DNS architectures
- **Multi-Protocol Support** - Configure DNS over UDP/TCP (Do53), DNS over HTTPS (DoH), and DoH-FIPS protocols
- **Dual-Stack Networking** - Support for IPv4, IPv6, and dual-stack resolver endpoint types
- **Static IP Assignment** - Optionally pin specific IP addresses to endpoint interfaces for deterministic firewall rules
- **Security Group Management** - Automatically create security groups with DNS ingress rules (TCP/UDP port 53) and all-outbound egress, or bring your own security groups
- **Enhanced Metrics** - Enable Resolver Query Logging enhanced metrics and target name server metrics for monitoring

## Usage

```hcl
module "resolver_inbound" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/resolver-endpoints?depth=1&ref=master"

  name      = "corp-inbound"
  direction = "INBOUND"
  vpc_id    = "vpc-0abc123456def7890"

  ip_addresses = [
    { subnet_id = "subnet-aaa" },
    { subnet_id = "subnet-bbb" },
  ]

  security_group_ingress_cidr_blocks = ["10.0.0.0/8"]

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
| create\_security\_group | Whether to create Security Groups for Route53 Resolver Endpoints | `bool` | `true` | no |
| direction | The resolver endpoint flow direction. Valid values are INBOUND, OUTBOUND, or BIDIRECTIONAL. | `string` | `"INBOUND"` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| ip\_addresses | A list of IP address configurations for the resolver endpoint. Each entry requires subnet\_id and optionally ip (IPv4) or ipv6. | <pre>list(object({<br/>    subnet_id = string<br/>    ip        = optional(string)<br/>    ipv6      = optional(string)<br/>  }))</pre> | `[]` | no |
| name | Name to use for resource naming and tagging. | `string` | `null` | no |
| protocols | The resolver endpoint protocols. Valid values are DoH, Do53, DoH-FIPS. | `list(string)` | <pre>[<br/>  "Do53"<br/>]</pre> | no |
| rni\_enhanced\_metrics\_enabled | (Optional) Specifies whether Resolver Query Logging enhanced metrics are enabled for the resolver endpoint. Default is false. | `bool` | `false` | no |
| security\_group\_description | The security group description | `string` | `null` | no |
| security\_group\_ids | A list of security group IDs | `list(string)` | `[]` | no |
| security\_group\_ingress\_cidr\_blocks | A list of CIDR blocks to allow on security group | `list(string)` | `[]` | no |
| security\_group\_name | The name of the security group | `string` | `null` | no |
| security\_group\_name\_prefix | The prefix of the security group | `string` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| target\_name\_server\_metrics\_enabled | (Optional) Specifies whether target name server metrics are enabled for outbound resolver endpoints. Default is false. | `bool` | `false` | no |
| type | The resolver endpoint IP address type. Valid values are IPV4, IPV6, or DUALSTACK. | `string` | `"IPV4"` | no |
| vpc\_id | The VPC ID for all the Route53 Resolver Endpoints | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| resolver\_endpoint\_arn | The ARN of the Resolver Endpoint |
| resolver\_endpoint\_host\_vpc\_id | The VPC ID used by the Resolver Endpoint |
| resolver\_endpoint\_id | The ID of the Resolver Endpoint |
| resolver\_endpoint\_ip\_addresses | Resolver Endpoint IP Addresses |
| resolver\_endpoint\_security\_group\_ids | Security Group IDs mapped to Resolver Endpoint |
<!-- END_TF_DOCS -->

## Examples

## Basic Inbound Endpoint

Create an inbound Route53 Resolver endpoint so that on-premises DNS servers can forward queries to AWS.

```hcl
module "resolver_inbound" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/resolver-endpoints?depth=1&ref=master"

  enabled = true
  name    = "corp-inbound"

  direction = "INBOUND"
  vpc_id    = "vpc-0abc123456def7890"

  ip_addresses = [
    { subnet_id = "subnet-0aaaa111111111111" },
    { subnet_id = "subnet-0bbbb222222222222" },
  ]

  security_group_ingress_cidr_blocks = ["10.0.0.0/8"]

  tags = {
    Environment = "production"
    Team        = "networking"
  }
}
```

## Outbound Endpoint

Create an outbound resolver endpoint that forwards DNS queries from VPC workloads to on-premises name servers.

```hcl
module "resolver_outbound" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/resolver-endpoints?depth=1&ref=master"

  enabled = true
  name    = "corp-outbound"

  direction = "OUTBOUND"
  vpc_id    = "vpc-0abc123456def7890"

  ip_addresses = [
    { subnet_id = "subnet-0aaaa111111111111" },
    { subnet_id = "subnet-0bbbb222222222222" },
  ]

  security_group_ingress_cidr_blocks = ["10.0.0.0/8"]

  tags = {
    Environment = "production"
    Team        = "networking"
  }
}
```

## Bidirectional Endpoint with Static IPs

Create a bidirectional endpoint with pinned IP addresses for deterministic on-premises firewall rules.

```hcl
module "resolver_bidirectional" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/resolver-endpoints?depth=1&ref=master"

  enabled = true
  name    = "hybrid-dns"

  direction = "BIDIRECTIONAL"
  vpc_id    = "vpc-0abc123456def7890"

  ip_addresses = [
    {
      subnet_id = "subnet-0aaaa111111111111"
      ip        = "10.0.1.10"
    },
    {
      subnet_id = "subnet-0bbbb222222222222"
      ip        = "10.0.2.10"
    },
  ]

  security_group_ingress_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12"]

  rni_enhanced_metrics_enabled       = true
  target_name_server_metrics_enabled = true

  tags = {
    Environment = "production"
    Team        = "networking"
  }
}
```

## Using Pre-existing Security Group

Attach an existing security group instead of creating one, useful when the SG lifecycle is managed separately.

```hcl
module "resolver_existing_sg" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/resolver-endpoints?depth=1&ref=master"

  enabled = true
  name    = "corp-inbound-shared"

  direction            = "INBOUND"
  vpc_id               = "vpc-0abc123456def7890"
  create_security_group = false
  security_group_ids   = ["sg-0123456789abcdef0"]

  ip_addresses = [
    { subnet_id = "subnet-0aaaa111111111111" },
    { subnet_id = "subnet-0bbbb222222222222" },
  ]

  tags = {
    Environment = "staging"
    Team        = "networking"
  }
}
```
