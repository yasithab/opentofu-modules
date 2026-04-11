# AWS Cloud Map

Provisions AWS Cloud Map namespaces and service discovery services, supporting HTTP, private DNS, and public DNS namespace types with optional ECS IAM role creation and Lambda Function URL registration.

## Features

- **Multiple Namespace Types** - Creates HTTP, private DNS (VPC-scoped), or public DNS namespaces, or attaches to an existing namespace via `existing_namespace_id`
- **Service Discovery Services** - Defines multiple services per namespace with configurable DNS records, TTL, routing policies, and per-service health check settings
- **ECS Integration** - Optionally provisions an IAM role with the minimum permissions ECS tasks need to register and deregister service instances
- **Lambda Function URL Registration** - Registers Lambda Function URLs or API Gateway endpoints as discoverable instances in a Cloud Map service
- **Health Checks** - Supports Route 53 health checks for public DNS namespaces and custom health checks for private DNS namespaces, with mutual exclusivity validation
- **Flexible DNS Configuration** - Configurable DNS record types (A, AAAA, CNAME, SRV), TTL values, and routing policies (MULTIVALUE, WEIGHTED) per service

## Usage

```hcl
module "cloudmap" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudmap?depth=1&ref=master"

  create_private_dns_namespace = true
  namespace_name               = "internal.example.local"
  namespace_description        = "Private service discovery namespace"
  vpc_id                       = "vpc-0abc1234def567890"

  services = {
    api = {
      name        = "api"
      description = "Backend API service"
    }
    worker = {
      name        = "worker"
      description = "Background worker service"
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```


## Examples

## Basic Usage - Private DNS Namespace for ECS

Creates a private DNS namespace inside a VPC and registers two ECS services so they can resolve each other by hostname.

```hcl
module "cloudmap_private" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudmap?depth=1&ref=master"

  enabled = true

  create_private_dns_namespace = true
  namespace_name               = "internal.example.local"
  namespace_description        = "Private service discovery namespace for ECS services"
  vpc_id                       = "vpc-0abc1234def567890"

  dns_ttl         = 10
  dns_record_type = "A"
  routing_policy  = "MULTIVALUE"

  services = {
    api = {
      name        = "api"
      description = "Backend API service"
      dns_ttl     = 10
    }
    worker = {
      name        = "worker"
      description = "Background worker service"
      dns_ttl     = 10
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## HTTP Namespace for Lambda or ECS HTTP Service Discovery

Creates an HTTP namespace (no DNS records) for service discovery via the AWS API, ideal for Lambda functions or ECS services using HTTP-based discovery.

```hcl
module "cloudmap_http" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudmap?depth=1&ref=master"

  enabled = true

  create_namespace  = true
  namespace_name    = "http-services.example.com"
  namespace_description = "HTTP namespace for service discovery"

  enable_dns_config    = false
  enable_health_checks = false

  services = {
    pricing_service = {
      name        = "pricing-service"
      description = "Pricing microservice"
      type        = "HTTP"
    }
    inventory_service = {
      name        = "inventory-service"
      description = "Inventory microservice"
      type        = "HTTP"
    }
  }

  tags = {
    Environment = "production"
    Team        = "engineering"
  }
}
```

## Private Namespace with ECS Service Discovery IAM Role

Creates a private DNS namespace together with the IAM role required by ECS tasks to register and deregister service instances.

```hcl
module "cloudmap_ecs_discovery" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudmap?depth=1&ref=master"

  enabled = true

  create_private_dns_namespace      = true
  create_ecs_service_discovery_role = true
  namespace_name                    = "services.production.local"
  namespace_description             = "Production ECS service discovery"
  vpc_id                            = "vpc-0abc1234def567890"

  dns_ttl         = 10
  dns_record_type = "A"
  routing_policy  = "MULTIVALUE"

  services = {
    checkout = {
      name                        = "checkout"
      description                 = "Checkout service"
      health_check_custom_config  = true
      dns_ttl                     = 10
    }
    notifications = {
      name        = "notifications"
      description = "Notification service"
      dns_ttl     = 10
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Lambda Function URL Registration

Registers a Lambda Function URL in an existing HTTP CloudMap namespace so other services can discover the Lambda endpoint through the service registry.

```hcl
module "cloudmap_lambda" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudmap?depth=1&ref=master"

  enabled = true

  existing_namespace_id = "ns-abc123def456ghi7"
  enable_dns_config     = false
  enable_health_checks  = false

  services = {
    image_processor = {
      name        = "image-processor"
      description = "Image processing Lambda function"
      type        = "HTTP"
    }
  }

  enable_lambda_registration = true
  lambda_service_name        = "image_processor"
  lambda_instance_id         = "image-processor-lambda"
  lambda_url                 = "https://abcdefgh.lambda-url.us-east-1.on.aws"

  lambda_attributes = {
    stage   = "production"
    version = "2.1.0"
  }

  tags = {
    Environment = "production"
    Team        = "backend"
  }
}
```
