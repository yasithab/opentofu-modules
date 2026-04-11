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
- **Logging** - CloudWatch logging with configurable field-level log level and automatic IAM role creation
- **WAF Integration** - WAFv2 Web ACL association for API protection
- **API Keys** - Multiple API key management with configurable expiration

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
