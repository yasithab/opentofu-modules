# AWS AppSync

OpenTofu module for provisioning AWS AppSync GraphQL APIs with multiple authentication methods, data sources, resolvers, caching, custom domains, and WAF integration.

## Features

- **GraphQL API** - Full AppSync GraphQL API with schema definition, X-Ray tracing, and introspection configuration
- **Authentication** - API key, Cognito User Pools, IAM, OpenID Connect, and Lambda authorizer support with multiple authentication providers
- **Data Sources** - DynamoDB, Lambda, HTTP, RDS (Aurora Serverless), OpenSearch, EventBridge, and None data source types
- **Resolvers** - Unit and pipeline resolvers with VTL mapping templates or JavaScript runtime, caching, and sync configuration
- **Functions** - Pipeline functions with configurable runtime, batching, and conflict resolution
- **API Cache** - Configurable caching with per-resolver or full-request behavior and encryption at rest and in transit enabled by default
- **Domain Name** - Custom domain name with ACM certificate and automatic API association
- **Logging** - CloudWatch logging with configurable field-level log level, automatic IAM role creation, and a managed log group (`/aws/appsync/apis/<api_id>`) with configurable retention (`log_group_retention_in_days`) and KMS encryption (`log_group_kms_key_id`)
- **WAF Integration** - WAFv2 Web ACL association for API protection
- **API Keys** - Multiple API key management with configurable expiration

> **Warning:** the default `authentication_type` is `API_KEY`, which is only suitable for development and public read-only APIs. API keys are long-lived bearer credentials with no per-user identity - anyone holding the key can call the API. For production workloads use `AWS_IAM`, `AMAZON_COGNITO_USER_POOLS`, `OPENID_CONNECT`, or `AWS_LAMBDA` authorization.

## Notes

- The AppSync logging IAM role trust policy is scoped with an `aws:SourceAccount` condition so the role can only be assumed by AppSync on behalf of this account (confused-deputy protection).
- When `logging_enabled = true` (default), the module manages the `/aws/appsync/apis/<api_id>` CloudWatch log group with a 30-day retention default. Set `create_log_group = false` if the log group is managed elsewhere.

## Usage

```hcl
module "appsync" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//appsync?depth=1&ref=master"

  name                = "my-graphql-api"
  authentication_type = "API_KEY"

  schema = <<-EOF
    type Query {
      getItem(id: ID!): Item
    }
    type Item {
      id: ID!
      name: String
    }
  EOF

  api_keys = {
    default = {
      description = "Default API key"
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
| additional\_authentication\_providers | List of additional authentication provider configurations. | <pre>list(object({<br/>    authentication_type = string<br/>    user_pool_config = optional(object({<br/>      user_pool_id        = string<br/>      app_id_client_regex = optional(string)<br/>      aws_region          = optional(string)<br/>    }))<br/>    openid_connect_config = optional(object({<br/>      issuer    = string<br/>      auth_ttl  = optional(number)<br/>      client_id = optional(string)<br/>      iat_ttl   = optional(number)<br/>    }))<br/>    lambda_authorizer_config = optional(object({<br/>      authorizer_uri                   = string<br/>      authorizer_result_ttl_in_seconds = optional(number, 300)<br/>      identity_validation_expression   = optional(string)<br/>    }))<br/>  }))</pre> | `[]` | no |
| api\_keys | Map of API key configurations. | <pre>map(object({<br/>    description = optional(string)<br/>    expires     = optional(string)<br/>  }))</pre> | `{}` | no |
| authentication\_type | Default authentication type. Valid values: `API_KEY`, `AWS_IAM`, `AMAZON_COGNITO_USER_POOLS`, `OPENID_CONNECT`, `AWS_LAMBDA`. | `string` | `"API_KEY"` | no |
| cache\_api\_caching\_behavior | Caching behavior. Valid values: `FULL_REQUEST_CACHING`, `PER_RESOLVER_CACHING`. | `string` | `"FULL_REQUEST_CACHING"` | no |
| cache\_at\_rest\_encryption\_enabled | Whether at-rest encryption is enabled for the API cache. | `bool` | `true` | no |
| cache\_transit\_encryption\_enabled | Whether transit encryption is enabled for the API cache. | `bool` | `true` | no |
| cache\_ttl | TTL in seconds for cache entries. | `number` | `3600` | no |
| cache\_type | Cache instance type. Valid values: `SMALL`, `MEDIUM`, `LARGE`, `XLARGE`, `LARGE_2X`, `LARGE_4X`, `LARGE_8X`, `LARGE_12X`, `T2_SMALL`, `T2_MEDIUM`, `R4_LARGE`, `R4_XLARGE`, `R4_2XLARGE`, `R4_4XLARGE`, `R4_8XLARGE`. | `string` | `"SMALL"` | no |
| create\_api\_cache | Whether to create an API cache. | `bool` | `false` | no |
| create\_domain\_name | Whether to create a custom domain name for the API. | `bool` | `false` | no |
| create\_log\_group | Whether to manage the CloudWatch log group (`/aws/appsync/apis/<api_id>`) that AppSync writes to, enforcing retention and optional KMS encryption. Only applies when `logging_enabled` is true. | `bool` | `true` | no |
| create\_logging\_role | Whether to create an IAM role for CloudWatch logging. | `bool` | `true` | no |
| datasources | Map of data source configurations. Supports DynamoDB, Lambda, HTTP, RDS, OpenSearch, EventBridge, and None types. | `any` | `{}` | no |
| domain\_certificate\_arn | ARN of the ACM certificate for the custom domain. | `string` | `null` | no |
| domain\_description | Description of the custom domain name. | `string` | `null` | no |
| domain\_name | Custom domain name for the AppSync API. | `string` | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| functions | Map of AppSync function configurations for pipeline resolvers. | `any` | `{}` | no |
| introspection\_config | Introspection configuration. Valid values: `ENABLED`, `DISABLED`. | `string` | `"ENABLED"` | no |
| lambda\_authorizer\_config | Lambda authorizer configuration for AWS\_LAMBDA authentication. | <pre>object({<br/>    authorizer_uri                   = string<br/>    authorizer_result_ttl_in_seconds = optional(number, 300)<br/>    identity_validation_expression   = optional(string)<br/>  })</pre> | `null` | no |
| log\_exclude\_verbose\_content | Whether to exclude verbose content (headers, context, evaluated mapping templates) from logs. | `bool` | `true` | no |
| log\_field\_log\_level | Field-level logging level. Valid values: `ALL`, `ERROR`, `NONE`. | `string` | `"ERROR"` | no |
| log\_group\_kms\_key\_id | ARN of the KMS key to use for encrypting the managed CloudWatch log group. | `string` | `null` | no |
| log\_group\_retention\_in\_days | Number of days to retain AppSync API logs in the managed CloudWatch log group. | `number` | `30` | no |
| logging\_enabled | Whether CloudWatch logging is enabled for the API. | `bool` | `true` | no |
| logging\_role\_arn | ARN of an existing IAM role for CloudWatch logging. Used when `create_logging_role` is false. | `string` | `null` | no |
| name | Name of the AppSync GraphQL API. | `string` | n/a | yes |
| openid\_connect\_config | OpenID Connect configuration for OPENID\_CONNECT authentication. | <pre>object({<br/>    issuer    = string<br/>    auth_ttl  = optional(number)<br/>    client_id = optional(string)<br/>    iat_ttl   = optional(number)<br/>  })</pre> | `null` | no |
| query\_depth\_limit | Maximum depth of a query. Valid range: 1-75. | `number` | `null` | no |
| resolver\_count\_limit | Maximum number of resolvers per query. Valid range: 1-10000. | `number` | `null` | no |
| resolvers | Map of resolver configurations. Supports unit and pipeline resolver kinds. | `any` | `{}` | no |
| schema | GraphQL schema definition string. | `string` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| user\_pool\_config | Cognito User Pool configuration for AMAZON\_COGNITO\_USER\_POOLS authentication. | <pre>object({<br/>    user_pool_id        = string<br/>    default_action      = optional(string, "DENY")<br/>    app_id_client_regex = optional(string)<br/>    aws_region          = optional(string)<br/>  })</pre> | `null` | no |
| visibility | API visibility. Valid values: `GLOBAL`, `PRIVATE`. | `string` | `"GLOBAL"` | no |
| waf\_web\_acl\_arn | ARN of the WAFv2 Web ACL to associate with the GraphQL API. | `string` | `null` | no |
| xray\_enabled | Whether X-Ray tracing is enabled. | `bool` | `true` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| api\_arn | The ARN of the AppSync GraphQL API. |
| api\_cache\_id | The ID of the API cache. |
| api\_id | The ID of the AppSync GraphQL API. |
| api\_key\_ids | Map of API key IDs. |
| api\_key\_keys | Map of API key values. |
| api\_name | The name of the AppSync GraphQL API. |
| api\_uris | Map of URIs for the AppSync GraphQL API (GRAPHQL, REALTIME). |
| datasource\_arns | Map of data source ARNs. |
| domain\_appsync\_domain\_name | The AppSync-provided domain name for CNAME configuration. |
| domain\_hosted\_zone\_id | The hosted zone ID for the AppSync domain. |
| domain\_name | The custom domain name. |
| function\_arns | Map of AppSync function ARNs. |
| function\_ids | Map of AppSync function IDs. |
| log\_group\_arn | The ARN of the managed CloudWatch log group for AppSync API logs. |
| log\_group\_name | The name of the managed CloudWatch log group for AppSync API logs. |
| logging\_role\_arn | The ARN of the AppSync logging IAM role. |
| resolver\_arns | Map of resolver ARNs. |
<!-- END_TF_DOCS -->

## Examples

### DynamoDB-Backed API with Cognito Auth

A GraphQL API backed by DynamoDB tables with Cognito User Pool authentication and API key as an additional provider.

```hcl
module "appsync_dynamodb" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//appsync?depth=1&ref=master"

  name                = "todo-api"
  authentication_type = "AMAZON_COGNITO_USER_POOLS"

  user_pool_config = {
    user_pool_id   = "us-east-1_AbCdEfGhI"
    default_action = "ALLOW"
  }

  additional_authentication_providers = [
    {
      authentication_type = "API_KEY"
    }
  ]

  api_keys = {
    public = {
      description = "Public read-only key"
    }
  }

  schema = <<-EOF
    type Todo {
      id: ID!
      title: String!
      completed: Boolean!
    }
    type Query {
      getTodo(id: ID!): Todo
      listTodos: [Todo]
    }
    type Mutation {
      createTodo(title: String!): Todo
    }
  EOF

  datasources = {
    todos = {
      name             = "TodosTable"
      type             = "AMAZON_DYNAMODB"
      service_role_arn = "arn:aws:iam::123456789012:role/appsync-dynamodb-role"
      dynamodb_config = {
        table_name = "Todos"
      }
    }
  }

  resolvers = {
    get_todo = {
      type           = "Query"
      field          = "getTodo"
      datasource_key = "todos"
      request_template = <<-VTL
        {
          "version": "2017-02-28",
          "operation": "GetItem",
          "key": { "id": $util.dynamodb.toDynamoDBJson($ctx.args.id) }
        }
      VTL
      response_template = "$util.toJson($ctx.result)"
    }
    create_todo = {
      type           = "Mutation"
      field          = "createTodo"
      datasource_key = "todos"
      request_template = <<-VTL
        {
          "version": "2017-02-28",
          "operation": "PutItem",
          "key": { "id": $util.dynamodb.toDynamoDBJson($util.autoId()) },
          "attributeValues": {
            "title": $util.dynamodb.toDynamoDBJson($ctx.args.title),
            "completed": $util.dynamodb.toDynamoDBJson(false)
          }
        }
      VTL
      response_template = "$util.toJson($ctx.result)"
    }
  }

  tags = {
    Environment = "production"
    Service     = "todo-app"
  }
}
```

### Pipeline Resolver with Multiple Data Sources

A GraphQL API with pipeline resolvers combining Lambda and DynamoDB data sources.

```hcl
module "appsync_pipeline" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//appsync?depth=1&ref=master"

  name                = "order-api"
  authentication_type = "AWS_IAM"
  xray_enabled        = true

  schema = <<-EOF
    type Order {
      id: ID!
      items: [OrderItem]
      total: Float
    }
    type OrderItem {
      productId: String!
      quantity: Int!
      price: Float!
    }
    type Mutation {
      createOrder(items: [OrderItemInput!]!): Order
    }
    input OrderItemInput {
      productId: String!
      quantity: Int!
    }
  EOF

  datasources = {
    orders_table = {
      name             = "OrdersTable"
      type             = "AMAZON_DYNAMODB"
      service_role_arn = "arn:aws:iam::123456789012:role/appsync-dynamodb-role"
      dynamodb_config = {
        table_name = "Orders"
      }
    }
    pricing_lambda = {
      name             = "PricingService"
      type             = "AWS_LAMBDA"
      service_role_arn = "arn:aws:iam::123456789012:role/appsync-lambda-role"
      lambda_config = {
        function_arn = "arn:aws:lambda:us-east-1:123456789012:function:pricing-service"
      }
    }
    none = {
      name = "None"
      type = "NONE"
    }
  }

  functions = {
    calculate_price = {
      name           = "CalculatePrice"
      datasource_key = "pricing_lambda"
      runtime = {
        name            = "APPSYNC_JS"
        runtime_version = "1.0.0"
      }
      code = <<-JS
        export function request(ctx) {
          return { operation: 'Invoke', payload: ctx.prev.result };
        }
        export function response(ctx) {
          return ctx.result;
        }
      JS
    }
    save_order = {
      name           = "SaveOrder"
      datasource_key = "orders_table"
      runtime = {
        name            = "APPSYNC_JS"
        runtime_version = "1.0.0"
      }
      code = <<-JS
        export function request(ctx) {
          return { operation: 'PutItem', key: util.dynamodb.toMapValues({ id: util.autoId() }), attributeValues: util.dynamodb.toMapValues(ctx.prev.result) };
        }
        export function response(ctx) {
          return ctx.result;
        }
      JS
    }
  }

  resolvers = {
    create_order = {
      type               = "Mutation"
      field              = "createOrder"
      kind               = "PIPELINE"
      pipeline_functions = ["calculate_price", "save_order"]
      runtime = {
        name            = "APPSYNC_JS"
        runtime_version = "1.0.0"
      }
      code = <<-JS
        export function request(ctx) {
          return {};
        }
        export function response(ctx) {
          return ctx.prev.result;
        }
      JS
    }
  }

  tags = {
    Environment = "production"
    Service     = "order-service"
  }
}
```

### API with Custom Domain and WAF

A GraphQL API with a custom domain name, API caching, and WAF protection.

```hcl
module "appsync_secured" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//appsync?depth=1&ref=master"

  name                = "secured-api"
  authentication_type = "OPENID_CONNECT"

  openid_connect_config = {
    issuer    = "https://auth.example.com"
    client_id = "my-client-id"
    auth_ttl  = 3600
    iat_ttl   = 3600
  }

  schema = <<-EOF
    type Query {
      me: User
    }
    type User {
      id: ID!
      email: String!
    }
  EOF

  create_domain_name     = true
  domain_name            = "api.example.com"
  domain_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc-123"

  create_api_cache                 = true
  cache_type                       = "SMALL"
  cache_ttl                        = 3600
  cache_transit_encryption_enabled = true
  cache_at_rest_encryption_enabled = true

  waf_web_acl_arn = "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/my-acl/abc-123"

  tags = {
    Environment = "production"
    Compliance  = "soc2"
  }
}
```
