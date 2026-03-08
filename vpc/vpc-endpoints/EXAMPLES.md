# VPC Endpoints Module - Examples

## Basic Usage

Create gateway endpoints for S3 and DynamoDB.

```hcl
module "vpc_endpoints" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpc/vpc-endpoints?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpc/vpc-endpoints?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpc/vpc-endpoints?depth=1&ref=v2.0.0"

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
