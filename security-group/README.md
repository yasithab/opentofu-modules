# Security Group

Provisions an AWS VPC security group with flexible ingress and egress rule definitions supporting named rules, CIDR blocks, security group references, self-referencing rules, prefix lists, and computed (dynamic) values.

## Features

- **Security Group** - Create a VPC security group with support for both fixed names and name prefixes
- **Named Rules** - Define ingress and egress rules by well-known service name from a built-in rules database
- **CIDR-Based Rules** - Ingress and egress rules using IPv4 and IPv6 CIDR blocks
- **Source Security Group Rules** - Ingress and egress rules referencing other security groups by ID
- **Self-Referencing Rules** - Ingress and egress rules that allow traffic within the same security group
- **Prefix List Rules** - Ingress and egress rules using VPC prefix list IDs for endpoint access
- **Computed Rules** - Support for computed (dynamic) ingress and egress rules across all rule types for values not known until apply time
- **Existing Security Group** - Optionally manage rules on an existing security group by providing its ID
- **Configurable Timeouts** - Custom create and delete timeouts for security group operations

## Usage

```hcl
module "security_group" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//security-group?depth=1&ref=master"

  name        = "my-app-sg"
  description = "Security group for my application"
  vpc_id      = "vpc-0abc123def456789"

  ingress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "10.0.0.0/16"
      description = "HTTPS from VPC"
    }
  ]

  egress_rules = ["all-all"]

  tags = {
    Environment = "production"
  }
}
```


## Examples

## Basic Web Application Security Group

Create a security group that allows HTTP and HTTPS inbound traffic from the internet and all outbound traffic.

```hcl
module "sg_web" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//security-group?depth=1&ref=master"

  enabled = true
  name    = "web-app"
  vpc_id  = "vpc-0abc123456def7890"

  description      = "Security group for web application servers"
  use_name_prefix  = true

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP from internet"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS from internet"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_rules = ["all-all"]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Internal Service Security Group

Create a security group for an internal microservice that accepts traffic only from a specific source security group.

```hcl
module "sg_internal_service" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//security-group?depth=1&ref=master"

  enabled = true
  name    = "search-service"
  vpc_id  = "vpc-0abc123456def7890"

  description = "Security group for internal search service"

  ingress_with_source_security_group_id = [
    {
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "tcp"
      description              = "App traffic from API gateway SG"
      source_security_group_id = "sg-0aaaa111111111111"
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS to AWS services"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = {
    Environment = "production"
    Service     = "search"
    Team        = "backend"
  }
}
```

## RDS Database Security Group

Restrict PostgreSQL access to application-tier subnets only using CIDR ranges.

```hcl
module "sg_rds" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//security-group?depth=1&ref=master"

  enabled = true
  name    = "rds-postgres"
  vpc_id  = "vpc-0abc123456def7890"

  description = "Security group for PostgreSQL RDS instances"

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL from app subnet A"
      cidr_blocks = "10.0.10.0/24"
    },
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL from app subnet B"
      cidr_blocks = "10.0.11.0/24"
    },
  ]

  egress_cidr_blocks = []

  tags = {
    Environment = "production"
    Tier        = "data"
    Team        = "platform"
  }
}
```

## Manage Rules on an Existing Security Group

Attach additional ingress rules to a security group that already exists and is managed outside this module.

```hcl
module "sg_existing" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//security-group?depth=1&ref=master"

  enabled           = true
  security_group_id = "sg-0existing1234567890"
  vpc_id            = "vpc-0abc123456def7890"

  ingress_with_cidr_blocks = [
    {
      from_port   = 9200
      to_port     = 9200
      protocol    = "tcp"
      description = "OpenSearch from monitoring subnet"
      cidr_blocks = "10.0.50.0/24"
    },
  ]

  tags = {
    Environment = "production"
    ManagedBy   = "platform-team"
  }
}
```
