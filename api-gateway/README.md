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
- **Usage Plans and API Keys** - Quota and throttle tiers attached to the stage, with API keys associated via usage plan keys
- **Custom Domain** - Regional or edge-optimized custom domain with ACM certificate and automatic base path mapping
- **WAF Integration** - Associate a WAFv2 web ACL with the stage for request filtering

## Prerequisites

Execution logging (`logging_level = "INFO"` or `"ERROR"`) requires a **region-wide** API Gateway account setting (`aws_api_gateway_account`) pointing to an IAM role that API Gateway can use to push logs to CloudWatch. This is a singleton per region/account:

- If it is not yet configured in the target region, set `create_api_gateway_account = true` and this module will create the IAM role (with the `AmazonAPIGatewayPushToCloudWatchLogs` managed policy) and the account setting.
- If it is already managed elsewhere (another module instance or stack), leave `create_api_gateway_account = false` (the default) to avoid fighting over the singleton.

## Notes

- The deployment redeployment trigger hashes the OpenAPI body together with `deployment_variables`, the resource policy (`rest_api_policy` / `rest_api_inline_policy`), and `parameters`, so changes to any of these roll out a new deployment automatically.
- The CloudWatch access log group can be encrypted with a customer-managed key via `log_group_kms_key_id`.
- The custom domain endpoint type follows `endpoint_type`: `EDGE` APIs get an edge-optimized domain (ACM certificate must be in us-east-1), anything else gets a regional domain (certificate in the API's region).
- The WAFv2 web ACL must use `REGIONAL` scope and live in the same region as the API stage.

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

## Usage Plans and API Keys

Creates tiered usage plans attached to the stage and API keys associated with them. Key values are generated by AWS and exposed through the sensitive `api_key_values` output.

```hcl
module "api_gateway" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//api-gateway?depth=1&ref=master"

  name           = "partner-api"
  openapi_config = jsondecode(file("${path.module}/openapi.json"))
  stage_name     = "v1"

  usage_plans = {
    standard = {
      description = "Standard tier"

      quota_settings = {
        limit  = 10000
        period = "MONTH"
      }

      throttle_settings = {
        burst_limit = 100
        rate_limit  = 50
      }
    }

    premium = {
      description = "Premium tier"

      quota_settings = {
        limit  = 1000000
        period = "MONTH"
      }

      # Per-method throttling overrides
      method_throttle = [
        {
          path        = "/orders/POST"
          burst_limit = 500
          rate_limit  = 200
        },
      ]
    }
  }

  api_keys = {
    partner-a = {
      description    = "Partner A integration"
      usage_plan_key = "standard"
    }
    partner-b = {
      description    = "Partner B integration"
      usage_plan_key = "premium"
    }
  }

  tags = {
    Environment = "production"
  }
}
```

## Custom Domain with WAF

Exposes the API on a custom domain (with an automatic base path mapping to the stage) and protects the stage with a WAFv2 web ACL.

```hcl
module "api_gateway" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//api-gateway?depth=1&ref=master"

  name           = "public-api"
  endpoint_type  = "REGIONAL"
  openapi_config = jsondecode(file("${path.module}/openapi.json"))
  stage_name     = "v1"

  # Custom domain - certificate must be in the same region for REGIONAL APIs
  domain_name            = "api.example.com"
  domain_certificate_arn = module.acm.certificate_arn
  domain_base_path       = "v1"

  # WAF - web ACL must use REGIONAL scope
  waf_web_acl_arn = module.waf.web_acl_arn

  tags = {
    Environment = "production"
  }
}

# DNS alias record for the custom domain
resource "aws_route53_record" "api" {
  zone_id = var.zone_id
  name    = "api.example.com"
  type    = "A"

  alias {
    name                   = module.api_gateway.domain_regional_domain_name
    zone_id                = module.api_gateway.domain_regional_zone_id
    evaluate_target_health = false
  }
}
```
