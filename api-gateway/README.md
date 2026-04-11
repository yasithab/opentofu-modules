# API Gateway (REST)

Deploys an AWS API Gateway REST API with stage management, CloudWatch logging, VPC Private Link integration, and OpenAPI specification support.

## Features

- **OpenAPI-Driven** - Define your API using an OpenAPI specification passed as the request body
- **Stage Management** - Automatic deployment and stage creation with canary deployment support
- **CloudWatch Logging** - Configurable access and execution logging with customizable log format
- **VPC Private Link** - Built-in VPC Link creation for integrating with private resources such as ALBs
- **Resource Policies** - Attach inline or separate IAM resource policies to control API access
- **Caching and Throttling** - Per-stage cache cluster configuration and method-level throttling controls
- **X-Ray Tracing** - Optional AWS X-Ray tracing for request-level observability

## Usage

```hcl
module "api_gateway" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//api-gateway?depth=1&ref=master"

  name           = "my-api"
  description    = "My REST API"
  openapi_config = local.openapi_spec
  endpoint_type  = "REGIONAL"
  stage_name     = "v1"

  tags = {
    Environment = "production"
  }
}
```


## Examples

## Basic Usage

Deploys a REST API Gateway from an OpenAPI spec with INFO-level logging and a default stage. CloudWatch logs are created automatically when `logging_level` is not `OFF`.

```hcl
module "api_gateway" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//api-gateway?depth=1&ref=master"

  enabled = true

  name          = "user-service-api"
  endpoint_type = "REGIONAL"
  stage_name    = "v1"

  openapi_config = {
    openapi = "3.0.1"
    info = {
      title   = "User Service API"
      version = "1.0"
    }
    paths = {
      "/users" = {
        get = {
          x-amazon-apigateway-integration = {
            type            = "HTTP_PROXY"
            httpMethod      = "GET"
            uri             = "https://internal-alb.example.com/users"
            payloadFormatVersion = "1.0"
          }
        }
      }
    }
  }

  logging_level                = "INFO"
  log_group_retention_in_days  = 30

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## With X-Ray Tracing and Metrics

Enables X-Ray distributed tracing and CloudWatch metrics for all routes, useful for production performance monitoring.

```hcl
module "api_gateway_traced" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//api-gateway?depth=1&ref=master"

  enabled = true

  name          = "property-search-api"
  endpoint_type = "REGIONAL"
  stage_name    = "prod"
  description   = "Property search REST API"

  openapi_config = jsondecode(file("${path.module}/openapi.json"))

  logging_level        = "ERROR"
  xray_tracing_enabled = true
  metrics_enabled      = true

  throttling_burst_limit = 500
  throttling_rate_limit  = 1000

  log_group_retention_in_days = 90

  tags = {
    Environment = "production"
    Team        = "search"
  }
}
```

## Private API with Resource Policy

Creates a private API endpoint that is only reachable from within a VPC via VPC endpoints, and attaches a resource policy to restrict access to specific VPC endpoint IDs.

```hcl
module "api_gateway_private" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//api-gateway?depth=1&ref=master"

  enabled = true

  name          = "internal-data-api"
  endpoint_type = "PRIVATE"
  stage_name    = "v1"

  vpc_endpoint_ids = ["vpce-0abc1234def567890"]

  openapi_config = jsondecode(file("${path.module}/openapi-internal.json"))

  rest_api_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "execute-api:Invoke"
        Resource  = "arn:aws:execute-api:us-east-1:123456789012:*"
        Condition = {
          StringEquals = {
            "aws:SourceVpce" = "vpce-0abc1234def567890"
          }
        }
      }
    ]
  })

  logging_level               = "INFO"
  log_group_retention_in_days = 30

  tags = {
    Environment = "production"
    Team        = "platform"
    Visibility  = "internal"
  }
}
```

## With VPC Link for Private Backend Integration

Creates a VPC Link so the API Gateway can route traffic to a private Application Load Balancer inside a VPC.

```hcl
module "api_gateway_vpc_link" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//api-gateway?depth=1&ref=master"

  enabled = true

  name          = "booking-service-api"
  endpoint_type = "REGIONAL"
  stage_name    = "v2"

  # VPC Link target - typically an internal ALB ARN
  private_link_target_arns = [
    "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/net/internal-booking-nlb/abc123def456",
  ]

  openapi_config = jsondecode(file("${path.module}/openapi-booking.json"))

  logging_level        = "INFO"
  xray_tracing_enabled = true

  throttling_burst_limit = 200
  throttling_rate_limit  = 500

  disable_execute_api_endpoint = false

  tags = {
    Environment = "production"
    Team        = "bookings"
  }
}
```
