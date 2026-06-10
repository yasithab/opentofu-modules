# AWS Cloud Map

Provisions AWS Cloud Map namespaces and service discovery services, supporting HTTP, private DNS, and public DNS namespace types with optional ECS IAM role creation and Lambda Function URL registration.

## Features

- **Multiple Namespace Types** - Creates HTTP, private DNS (VPC-scoped), or public DNS namespaces, or attaches to an existing namespace via `existing_namespace_id` (set `namespace_type` to `dns_private`/`dns_public`/`http` in that case so DNS config and health checks are emitted correctly)
- **Service Discovery Services** - Defines multiple services per namespace with configurable DNS records, TTL, routing policies, and per-service health check settings
- **ECS Integration** - Optionally provisions an IAM role with the minimum permissions ECS tasks need to register and deregister service instances
- **Lambda Function URL Registration** - Registers Lambda Function URLs or API Gateway endpoints as discoverable instances in a Cloud Map service
- **Health Checks** - Supports Route 53 health checks for public DNS namespaces and custom health checks for private DNS namespaces, with mutual exclusivity validation
- **Flexible DNS Configuration** - Configurable DNS record types (A, AAAA, CNAME, SRV), TTL values, and routing policies (MULTIVALUE, WEIGHTED) per service

> [!NOTE]
> - The Lambda instance registration no longer registers a placeholder `127.0.0.1` A record: `AWS_INSTANCE_IPV4` is only set when `lambda_ip_address` is provided.
> - The ECS service discovery IAM role requires `name` (or the new `ecs_service_discovery_role_name` override) to be set.

## Usage

```hcl
module "cloudmap" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudmap?depth=1&ref=master"

  create_private_dns_namespace = true
  name                         = "internal.example.local"
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
| create\_ecs\_service\_discovery\_role | Whether to create IAM role for ECS service discovery | `bool` | `false` | no |
| create\_namespace | Whether to create an HTTP namespace | `bool` | `false` | no |
| create\_private\_dns\_namespace | Whether to create a private DNS namespace | `bool` | `false` | no |
| create\_public\_dns\_namespace | Whether to create a public DNS namespace | `bool` | `false` | no |
| dns\_record\_type | Type of DNS record | `string` | `"A"` | no |
| dns\_ttl | TTL for DNS records | `number` | `10` | no |
| ecs\_service\_discovery\_role\_name | Override name for the ECS service discovery IAM role. Defaults to '<name>-service-discovery-role' | `string` | `null` | no |
| enable\_dns\_config | Enable DNS configuration for the service. Set to false for HTTP namespaces or when using existing HTTP namespaces. | `bool` | `true` | no |
| enable\_health\_checks | Enable health checks for the service. Set to false when using private IPs or unsupported instance types. | `bool` | `true` | no |
| enable\_lambda\_registration | Enable registration of Lambda Function URL in CloudMap service discovery | `bool` | `false` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| existing\_namespace\_id | ID of an existing namespace to use | `string` | `null` | no |
| lambda\_attributes | Additional attributes for the Lambda instance in CloudMap | `map(string)` | `{}` | no |
| lambda\_instance\_id | Unique identifier for the Lambda instance in CloudMap | `string` | `"lambda-function"` | no |
| lambda\_ip\_address | IP address to use for the Lambda A record in CloudMap. If not provided, no AWS\_INSTANCE\_IPV4 attribute is registered (no placeholder IP is used). | `string` | `null` | no |
| lambda\_service\_name | Name of the CloudMap service for Lambda registration. If not specified, uses the first service name from var.services | `string` | `null` | no |
| lambda\_url | Lambda Function URL or API Gateway endpoint to register in CloudMap | `string` | `null` | no |
| name | Name of the CloudMap namespace | `string` | `null` | no |
| namespace\_description | Description of the CloudMap namespace | `string` | `null` | no |
| namespace\_type | Type of the namespace the services attach to: 'dns\_private', 'dns\_public', or 'http'. Set this when using existing\_namespace\_id so DNS config and health checks are emitted correctly; otherwise it is inferred from the create\_* flags | `string` | `null` | no |
| routing\_policy | Routing policy for the service | `string` | `"MULTIVALUE"` | no |
| services | Map of CloudMap services to create | <pre>map(object({<br/>    name            = string<br/>    description     = optional(string)<br/>    type            = optional(string)<br/>    force_destroy   = optional(bool, true)<br/>    dns_ttl         = optional(number, 10)<br/>    dns_record_type = optional(string, "A")<br/>    routing_policy  = optional(string, "MULTIVALUE")<br/>    health_check_config = optional(object({<br/>      resource_path     = string<br/>      type              = string<br/>      failure_threshold = optional(number, 3)<br/>    }))<br/>    health_check_custom_config            = optional(bool, false)<br/>    custom_health_check_failure_threshold = optional(number, 1)<br/>    tags                                  = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| vpc\_id | VPC ID for private DNS namespace | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| ecs\_service\_discovery\_role\_arn | ARN of the ECS service discovery IAM role |
| ecs\_service\_discovery\_role\_name | Name of the ECS service discovery IAM role |
| lambda\_discovery\_url | CloudMap discovery URL for the Lambda function |
| lambda\_instance\_id | ID of the registered Lambda instance in CloudMap |
| lambda\_service\_id | ID of the CloudMap service where Lambda is registered |
| namespace\_arn | ARN of the created namespace |
| namespace\_id | ID of the namespace in use (created or existing) |
| namespace\_name | Name of the created namespace |
| service\_arns | Map of service names to their ARNs for ECS integration |
| services | Map of created services with their details |
<!-- END_TF_DOCS -->

## Examples

## Basic Usage - Private DNS Namespace for ECS

Creates a private DNS namespace inside a VPC and registers two ECS services so they can resolve each other by hostname.

```hcl
module "cloudmap_private" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudmap?depth=1&ref=master"

  enabled = true

  create_private_dns_namespace = true
  name                         = "internal.example.local"
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
  name              = "http-services.example.com"
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
  name                              = "services.production.local"
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
