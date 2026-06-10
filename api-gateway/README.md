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

## Reference

<details>
<summary>Requirements, providers, inputs and outputs (generated by terraform-docs)</summary>

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
| access\_log\_format | The format of the access log file. | `string` | `"  {\n\t\"requestTime\": \"$context.requestTime\",\n\t\"requestId\": \"$context.requestId\",\n\t\"httpMethod\": \"$context.httpMethod\",\n\t\"path\": \"$context.path\",\n\t\"resourcePath\": \"$context.resourcePath\",\n\t\"status\": $context.status,\n\t\"responseLatency\": $context.responseLatency,\n  \"xrayTraceId\": \"$context.xrayTraceId\",\n  \"integrationRequestId\": \"$context.integration.requestId\",\n\t\"functionResponseStatus\": \"$context.integration.status\",\n  \"integrationLatency\": \"$context.integration.latency\",\n\t\"integrationServiceStatus\": \"$context.integration.integrationStatus\",\n  \"authorizeResultStatus\": \"$context.authorize.status\",\n\t\"authorizerServiceStatus\": \"$context.authorizer.status\",\n\t\"authorizerLatency\": \"$context.authorizer.latency\",\n\t\"authorizerRequestId\": \"$context.authorizer.requestId\",\n  \"ip\": \"$context.identity.sourceIp\",\n\t\"userAgent\": \"$context.identity.userAgent\",\n\t\"principalId\": \"$context.authorizer.principalId\",\n\t\"cognitoUser\": \"$context.identity.cognitoIdentityId\",\n  \"user\": \"$context.identity.user\"\n}\n"` | no |
| api\_key\_source | Source of the API key for requests. Valid values are HEADER (default) and AUTHORIZER. | `string` | `null` | no |
| api\_keys | Map of API keys to create. Each key is named <name>-<key>. Set usage\_plan\_key to the key of an entry in usage\_plans to associate the API key with that plan. Key values are generated by AWS and exposed via the api\_key\_values output (sensitive). | <pre>map(object({<br/>    description    = optional(string)<br/>    enabled        = optional(bool, true)<br/>    usage_plan_key = optional(string)<br/>  }))</pre> | `{}` | no |
| api\_resources | Map of API Gateway resource definitions to create. Each entry supports path\_part (required) and parent\_id (optional, defaults to the root resource id). | `map(map(string))` | `{}` | no |
| binary\_media\_types | List of binary media types supported by the REST API. By default, the REST API supports only UTF-8-encoded text payloads. | `list(string)` | `null` | no |
| cache\_cluster\_enabled | Whether a cache cluster is enabled for the stage. | `bool` | `null` | no |
| cache\_cluster\_size | Size of the cache cluster for the stage, if enabled. Allowed values include 0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118 and 237. | `string` | `null` | no |
| cache\_data\_encrypted | Whether the cached responses are encrypted. | `bool` | `null` | no |
| cache\_ttl\_in\_seconds | Time to live (TTL), in seconds, for cached responses. | `number` | `null` | no |
| caching\_enabled | Whether responses should be cached and returned for requests. | `bool` | `null` | no |
| canary\_settings | Configuration settings of a canary deployment. Supports deployment\_id, percent\_traffic, stage\_variable\_overrides, and use\_stage\_cache. | `any` | `null` | no |
| client\_certificate\_id | Identifier of a client certificate for the stage. | `string` | `null` | no |
| cloudwatch\_log\_group\_class | Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT\_ACCESS. | `string` | `null` | no |
| cloudwatch\_log\_group\_skip\_destroy | Set to true to prevent the log group from being deleted on module destroy. Preserves audit logs. | `bool` | `false` | no |
| create\_api\_gateway\_account | Whether to manage the region-wide aws\_api\_gateway\_account setting and its CloudWatch IAM role. Required once per region/account for execution logging - leave false if it is already managed elsewhere. | `bool` | `false` | no |
| create\_rest\_api\_gateway\_resource | flag to control the rest api gateway resources creation | `bool` | `true` | no |
| data\_trace\_enabled | Whether data trace logging is enabled for this method, which effects the log entries pushed to Amazon CloudWatch Logs. | `bool` | `false` | no |
| deployment\_description | Description of the deployment. | `string` | `null` | no |
| deployment\_variables | Map of key/value pairs that define the stage variables passed in the deployment. These are merged with stage variables at apply time. | `map(string)` | `null` | no |
| description | Description of the REST API. | `string` | `null` | no |
| disable\_execute\_api\_endpoint | Specifies whether clients can invoke your API by using the default execute-api endpoint. Defaults to false. | `bool` | `false` | no |
| documentation\_version | Version of the associated API documentation. | `string` | `null` | no |
| domain\_base\_path | Base path to mount the API under on the custom domain (e.g. v1). Leave null to expose the API at the domain root. | `string` | `null` | no |
| domain\_certificate\_arn | ARN of the ACM certificate for the custom domain. For EDGE endpoints the certificate must be in us-east-1; for REGIONAL endpoints it must be in the same region as the API. | `string` | `null` | no |
| domain\_name | Custom domain name for the API (e.g. api.example.com). Requires domain\_certificate\_arn. A base path mapping to the stage is created automatically. Leave null to skip. | `string` | `null` | no |
| domain\_security\_policy | TLS security policy for the custom domain. Valid values: TLS\_1\_0, TLS\_1\_2. | `string` | `"TLS_1_2"` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| endpoint\_ip\_address\_type | IP address types that can invoke the API. Valid values are ipv4 and dualstack. | `string` | `null` | no |
| endpoint\_type | The type of the endpoint. One of - EDGE, REGIONAL, PRIVATE | `string` | `"REGIONAL"` | no |
| fail\_on\_warnings | Whether warnings while API Gateway is creating or updating the resource should return an error or not. | `bool` | `null` | no |
| log\_group\_kms\_key\_id | ARN of the KMS key to use for encrypting the CloudWatch log group. | `string` | `null` | no |
| log\_group\_retention\_in\_days | The number of days to retain log events in the CloudWatch log group | `number` | `30` | no |
| logging\_level | The logging level of the API. One of - OFF, INFO, ERROR | `string` | `"INFO"` | no |
| metrics\_enabled | A flag to indicate whether to enable metrics collection. | `bool` | `false` | no |
| minimum\_compression\_size | Minimum response size to compress for the REST API. String containing an integer value between -1 and 10485760 (10MB). Setting to -1 disables compression, setting to 0 allows compression for responses of any size. | `string` | `null` | no |
| name | Name to use for resource naming and tagging. | `string` | n/a | yes |
| openapi\_config | The OpenAPI specification for the API | `any` | `{}` | no |
| parameters | Map of customizations for importing the specification in the body argument. | `map(string)` | `null` | no |
| private\_link\_target\_arns | A list of target ARNs for VPC Private Link | `list(string)` | `[]` | no |
| put\_rest\_api\_mode | Mode of the PutRestApi operation when importing an OpenAPI specification via the body argument. Valid values are merge and overwrite. | `string` | `null` | no |
| require\_authorization\_for\_cache\_control | Whether authorization is required for a cache invalidation request. | `bool` | `null` | no |
| rest\_api\_inline\_policy | JSON formatted policy document set inline on the aws\_api\_gateway\_rest\_api resource. Alternative to rest\_api\_policy when a separate policy resource is not desired. | `string` | `null` | no |
| rest\_api\_policy | The IAM policy document for the API. Used to create an aws\_api\_gateway\_rest\_api\_policy resource. | `string` | `null` | no |
| stage\_description | Description of the stage. | `string` | `null` | no |
| stage\_name | The name of the stage | `string` | `"default"` | no |
| stage\_variables | A map of variables to set on the stage. The vpc\_link\_id variable is automatically injected when a VPC Link is created. | `map(string)` | `{}` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| throttling\_burst\_limit | Throttling burst limit. Default: -1 (throttling disabled). | `number` | `-1` | no |
| throttling\_rate\_limit | Throttling rate limit. Default: -1 (throttling disabled). | `number` | `-1` | no |
| unauthorized\_cache\_control\_header\_strategy | How to handle unauthorized requests for cache invalidation. Valid values: FAIL\_WITH\_403, SUCCEED\_WITH\_RESPONSE\_HEADER, SUCCEED\_WITHOUT\_RESPONSE\_HEADER. | `string` | `null` | no |
| usage\_plans | Map of usage plans to create and attach to the stage. Each plan is named <name>-<key> and supports quota settings, plan-level throttling, and per-method throttling. | <pre>map(object({<br/>    description  = optional(string)<br/>    product_code = optional(string)<br/>    quota_settings = optional(object({<br/>      limit  = number<br/>      offset = optional(number)<br/>      period = string<br/>    }))<br/>    throttle_settings = optional(object({<br/>      burst_limit = optional(number)<br/>      rate_limit  = optional(number)<br/>    }))<br/>    method_throttle = optional(list(object({<br/>      path        = string<br/>      burst_limit = optional(number)<br/>      rate_limit  = optional(number)<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| vpc\_endpoint\_ids | Set of VPC Endpoint identifiers. Only supported for PRIVATE endpoint type. | `list(string)` | `null` | no |
| waf\_web\_acl\_arn | ARN of a WAFv2 web ACL (REGIONAL scope) to associate with the API Gateway stage. Leave null to skip. | `string` | `null` | no |
| xray\_tracing\_enabled | A flag to indicate whether to enable X-Ray tracing. | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| api\_gateway\_account\_cloudwatch\_role\_arn | The ARN of the IAM role used for the region-wide API Gateway account CloudWatch settings (if created) |
| api\_key\_ids | Map of API key keys to their IDs |
| api\_key\_values | Map of API key keys to their generated key values |
| arn | The ARN of the REST API |
| base\_path\_mapping\_id | The ID of the base path mapping (if created) |
| created\_date | The date the REST API was created |
| domain\_cloudfront\_domain\_name | The CloudFront distribution domain name for an EDGE custom domain - create an alias record pointing to this |
| domain\_cloudfront\_zone\_id | The CloudFront hosted zone ID for an EDGE custom domain |
| domain\_name | The custom domain name (if created) |
| domain\_name\_arn | The ARN of the custom domain name (if created) |
| domain\_regional\_domain\_name | The regional domain name for a REGIONAL custom domain - create an alias record pointing to this |
| domain\_regional\_zone\_id | The regional hosted zone ID for a REGIONAL custom domain |
| execution\_arn | The execution ARN part to be used in lambda\_permission's source\_arn when allowing API Gateway to invoke a Lambda <br/>    function, e.g., arn:aws:execute-api:eu-west-2:123456789012:z4675bid1j, which can be concatenated with allowed stage, <br/>    method and resource path.The ARN of the Lambda function that will be executed. |
| id | The ID of the REST API |
| invoke\_url | The URL to invoke the REST API |
| log\_group\_arn | The ARN of the CloudWatch log group for access logs |
| log\_group\_name | The name of the CloudWatch log group for access logs |
| root\_resource\_id | The resource ID of the REST API's root |
| stage\_arn | The ARN of the gateway stage |
| stage\_name | The name of the gateway stage |
| usage\_plan\_arns | Map of usage plan keys to their ARNs |
| usage\_plan\_ids | Map of usage plan keys to their IDs |
| vpc\_link\_arn | The ARN of the VPC Link (if created) |
| vpc\_link\_id | The ID of the VPC Link (if created) |
| waf\_web\_acl\_association\_id | The ID of the WAFv2 web ACL association (if created) |
<!-- END_TF_DOCS -->

</details>
