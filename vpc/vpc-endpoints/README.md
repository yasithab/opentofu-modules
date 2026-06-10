# VPC Endpoints

Creates AWS VPC Interface and Gateway endpoints with support for custom security groups, DNS options, subnet configurations, and endpoint policies.

## Features

- **Interface and Gateway Endpoints** - Supports both Interface and Gateway VPC endpoint types, as well as Resource and ServiceNetwork types
- **Security Group Management** - Optionally creates a dedicated security group with configurable ingress and egress rules for Interface endpoints
- **Private DNS** - Configure private DNS settings including DNS record IP type and inbound resolver endpoint preferences
- **Flexible Endpoint Map** - Define multiple endpoints in a single map with per-endpoint overrides for subnets, security groups, and policies
- **Subnet Configuration** - Assign specific IPv4/IPv6 addresses to endpoint network interfaces via subnet configuration blocks

## Usage

```hcl
module "vpc_endpoints" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpc/vpc-endpoints?depth=1&ref=master"

  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-aaa", "subnet-bbb"]

  endpoints = {
    s3 = {
      service      = "s3"
      service_type = "Gateway"
      route_table_ids = ["rtb-aaa"]
    }
    ssm = {
      service             = "ssm"
      private_dns_enabled = true
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
| create\_security\_group | Determines if a security group is created | `bool` | `false` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| endpoints | A map of interface and/or gateway endpoints containing their properties and configurations | <pre>map(object({<br/>    create                     = optional(bool, true)<br/>    service                    = optional(string)<br/>    service_name               = optional(string)<br/>    service_endpoint           = optional(string)<br/>    service_region             = optional(string)<br/>    service_type               = optional(string, "Interface")<br/>    auto_accept                = optional(bool)<br/>    resource_configuration_arn = optional(string)<br/>    service_network_arn        = optional(string)<br/>    security_group_ids         = optional(list(string), [])<br/>    subnet_ids                 = optional(list(string), [])<br/>    route_table_ids            = optional(list(string))<br/>    policy                     = optional(string)<br/>    private_dns_enabled        = optional(bool)<br/>    ip_address_type            = optional(string)<br/>    dns_options = optional(object({<br/>      dns_record_ip_type                             = optional(string)<br/>      private_dns_only_for_inbound_resolver_endpoint = optional(bool)<br/>      private_dns_preference                         = optional(string)<br/>      private_dns_specified_domains                  = optional(list(string))<br/>    }))<br/>    subnet_configuration = optional(list(object({<br/>      ipv4      = optional(string)<br/>      ipv6      = optional(string)<br/>      subnet_id = string<br/>    })), [])<br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| security\_group\_description | Description of the security group created | `string` | `null` | no |
| security\_group\_ids | Default security group IDs to associate with the VPC endpoints | `list(string)` | `[]` | no |
| security\_group\_name | Name to use on security group created. Conflicts with `security_group_name_prefix` | `string` | `null` | no |
| security\_group\_name\_prefix | Name prefix to use on security group created. Conflicts with `security_group_name` | `string` | `null` | no |
| security\_group\_rules | Security group rules to add to the security group created | <pre>map(object({<br/>    type                         = optional(string, "ingress")<br/>    ip_protocol                  = optional(string, "tcp")<br/>    from_port                    = optional(number)<br/>    to_port                      = optional(number)<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    description                  = optional(string)<br/>    prefix_list_id               = optional(string)<br/>    referenced_security_group_id = optional(string)<br/>    tags                         = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| security\_group\_tags | A map of additional tags to add to the security group created | `map(string)` | `{}` | no |
| subnet\_ids | Default subnets IDs to associate with the VPC endpoints | `list(string)` | `[]` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| timeouts | Define maximum timeout for creating, updating, and deleting VPC endpoint resources | `map(string)` | `{}` | no |
| vpc\_id | The ID of the VPC in which the endpoint will be used | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| endpoints | Array containing the full resource object and attributes for all endpoints created |
| security\_group\_arn | Amazon Resource Name (ARN) of the security group |
| security\_group\_id | ID of the security group |
<!-- END_TF_DOCS -->

## Examples

## Basic Usage

Create gateway endpoints for S3 and DynamoDB.

```hcl
module "vpc_endpoints" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpc/vpc-endpoints?depth=1&ref=master"

  enabled = true

  vpc_id = "vpc-0a1b2c3d4e5f67890"

  endpoints = {
    s3 = {
      service      = "s3"
      service_type = "Gateway"
      route_table_ids = [
        "rtb-0a1b2c3d4e5f67891",
        "rtb-0a1b2c3d4e5f67892",
      ]
    }
    dynamodb = {
      service      = "dynamodb"
      service_type = "Gateway"
      route_table_ids = [
        "rtb-0a1b2c3d4e5f67891",
        "rtb-0a1b2c3d4e5f67892",
      ]
    }
  }

  tags = {
    Team        = "platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Interface Endpoints with Shared Security Group

Create interface endpoints for ECR, Secrets Manager, and SSM with a shared security group.

```hcl
module "vpc_endpoints" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpc/vpc-endpoints?depth=1&ref=master"

  enabled = true

  vpc_id     = "vpc-0a1b2c3d4e5f67890"
  subnet_ids = ["subnet-0a1b2c3d4e5f67891", "subnet-0a1b2c3d4e5f67892", "subnet-0a1b2c3d4e5f67893"]

  create_security_group              = true
  security_group_name_prefix         = "vpc-endpoints"
  security_group_description         = "Security group for VPC interface endpoints"
  security_group_rules = {
    https-from-vpc = {
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "10.10.0.0/16"
      description = "Allow HTTPS from VPC CIDR"
    }
  }

  endpoints = {
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
    }
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
    }
    secretsmanager = {
      service             = "secretsmanager"
      private_dns_enabled = true
    }
    ssm = {
      service             = "ssm"
      private_dns_enabled = true
    }
    ssmmessages = {
      service             = "ssmmessages"
      private_dns_enabled = true
    }
  }

  tags = {
    Team        = "platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Mixed Gateway and Interface Endpoints

Combine gateway endpoints with interface endpoints for a comprehensive private connectivity setup.

```hcl
module "vpc_endpoints" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpc/vpc-endpoints?depth=1&ref=master"

  enabled = true

  vpc_id     = "vpc-0b2c3d4e5f6789abc"
  subnet_ids = ["subnet-0b2c3d4e5f6789abd", "subnet-0b2c3d4e5f6789abe"]

  security_group_ids = ["sg-0a1b2c3d4e5f67890"]

  endpoints = {
    s3 = {
      service      = "s3"
      service_type = "Gateway"
      route_table_ids = ["rtb-0b2c3d4e5f6789abf"]
    }
    dynamodb = {
      service      = "dynamodb"
      service_type = "Gateway"
      route_table_ids = ["rtb-0b2c3d4e5f6789abf"]
    }
    kms = {
      service             = "kms"
      private_dns_enabled = true
    }
    logs = {
      service             = "logs"
      private_dns_enabled = true
    }
    monitoring = {
      service             = "monitoring"
      private_dns_enabled = true
    }
    sts = {
      service             = "sts"
      private_dns_enabled = true
    }
  }

  tags = {
    Team        = "platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```
