# RDS Proxy

Provisions Amazon RDS Proxy instances to pool and share database connections, reducing connection overhead for applications that open many short-lived connections to RDS or Aurora databases.

## Features

- **Multi-Engine Support** - Connect to MySQL, PostgreSQL, and SQL Server databases via the `engine_family` setting
- **Connection Pooling** - Configure connection pool sizing, idle connection management, borrow timeouts, and session pinning filters
- **TLS Enforcement** - Require TLS encryption for all client-to-proxy connections by default
- **Secrets Manager Authentication** - Authenticate using credentials stored in AWS Secrets Manager with optional IAM database authentication
- **Flexible Targeting** - Target either a standalone RDS DB instance or an Aurora DB cluster
- **Custom Endpoints** - Create additional proxy endpoints with read-only or read-write target roles for routing traffic
- **IAM Role and Policy** - Automatically create an IAM role with policies for Secrets Manager and KMS access, or bring your own role
- **CloudWatch Logging** - Manage a dedicated CloudWatch log group for proxy diagnostic logs with configurable retention
- **Dual-Stack Networking** - Support for IPv4, IPv6, and dual-stack endpoint and target connection network types

## Usage

```hcl
module "rds_proxy" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds-proxy?depth=1&ref=master"

  name          = "app-db-proxy"
  engine_family = "POSTGRESQL"
  require_tls   = true

  vpc_subnet_ids         = ["subnet-aaa", "subnet-bbb"]
  vpc_security_group_ids = ["sg-0abc123def456789a"]

  auth = [
    {
      auth_scheme = "SECRETS"
      iam_auth    = "DISABLED"
      secret_arn  = "arn:aws:secretsmanager:us-east-1:123456789012:secret:rds!cluster-abc123-AbCdEf"
    }
  ]

  target_db_cluster     = true
  db_cluster_identifier = "app-db"

  tags = {
    Environment = "production"
  }
}
```

## Examples

## Basic Usage

RDS Proxy in front of an Aurora PostgreSQL cluster using Secrets Manager for credentials.

```hcl
module "rds_proxy" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds-proxy?depth=1&ref=master"

  enabled        = true
  name           = "app-db-proxy"
  engine_family  = "POSTGRESQL"
  require_tls    = true

  vpc_subnet_ids         = ["subnet-0aa111bbb222", "subnet-0cc333ddd444"]
  vpc_security_group_ids = ["sg-0abc123def456789a"]

  auth = [
    {
      auth_scheme = "SECRETS"
      iam_auth    = "DISABLED"
      secret_arn  = "arn:aws:secretsmanager:us-east-1:123456789012:secret:rds!cluster-abc123-AbCdEf"
    }
  ]

  target_db_cluster    = true
  db_cluster_identifier = "app-db"

  tags = {
    Environment = "production"
    Team        = "backend"
  }
}
```

## With IAM Authentication

RDS Proxy enforcing IAM database authentication for passwordless connections from application roles.

```hcl
module "rds_proxy_iam" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds-proxy?depth=1&ref=master"

  enabled        = true
  name           = "listings-db-proxy"
  engine_family  = "POSTGRESQL"
  require_tls    = true
  idle_client_timeout = 1800

  vpc_subnet_ids         = ["subnet-0aa111bbb222", "subnet-0cc333ddd444", "subnet-0ee555fff666"]
  vpc_security_group_ids = ["sg-0abc123def456789a"]

  auth = [
    {
      auth_scheme               = "SECRETS"
      iam_auth                  = "REQUIRED"
      client_password_auth_type = "POSTGRES_SCRAM_SHA_256"
      secret_arn                = "arn:aws:secretsmanager:us-east-1:123456789012:secret:rds!cluster-listings-AbCdEf"
      description               = "IAM-authenticated app user"
    }
  ]

  target_db_cluster     = true
  db_cluster_identifier = "listings-db"

  max_connections_percent      = 90
  max_idle_connections_percent = 50
  connection_borrow_timeout    = 120

  log_group_retention_in_days = 30
  kms_key_arns = [
    "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"
  ]

  tags = {
    Environment = "production"
    Team        = "listings"
  }
}
```

## MySQL Proxy with Additional Read-Only Endpoint

MySQL RDS Proxy with a custom read-only endpoint for analytics traffic.

```hcl
module "rds_proxy_mysql" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//rds-proxy?depth=1&ref=master"

  enabled        = true
  name           = "orders-db-proxy"
  engine_family  = "MYSQL"
  require_tls    = true

  vpc_subnet_ids         = ["subnet-0aa111bbb222", "subnet-0cc333ddd444"]
  vpc_security_group_ids = ["sg-0abc123def456789b"]

  auth = [
    {
      auth_scheme = "SECRETS"
      iam_auth    = "DISABLED"
      secret_arn  = "arn:aws:secretsmanager:us-east-1:123456789012:secret:orders-db-creds-AbCdEf"
    }
  ]

  target_db_cluster     = true
  db_cluster_identifier = "orders-db"

  endpoints = {
    read_only = {
      name                   = "orders-db-proxy-ro"
      vpc_subnet_ids         = ["subnet-0aa111bbb222", "subnet-0cc333ddd444"]
      vpc_security_group_ids = ["sg-0abc123def456789b"]
      target_role            = "READ_ONLY"
    }
  }

  max_connections_percent      = 75
  max_idle_connections_percent = 25

  tags = {
    Environment = "production"
    Team        = "orders"
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
| auth | Configuration block(s) with authorization mechanisms to connect to the associated instances or clusters | <pre>list(object({<br/>    auth_scheme               = optional(string, "SECRETS")<br/>    client_password_auth_type = optional(string)<br/>    description               = optional(string)<br/>    iam_auth                  = optional(string)<br/>    secret_arn                = optional(string)<br/>    username                  = optional(string)<br/>  }))</pre> | `[]` | no |
| connection\_borrow\_timeout | The number of seconds for a proxy to wait for a connection to become available in the connection pool | `number` | `null` | no |
| create\_iam\_policy | Determines whether an IAM policy is created | `bool` | `true` | no |
| create\_iam\_role | Determines whether an IAM role is created | `bool` | `true` | no |
| db\_cluster\_identifier | DB cluster identifier | `string` | `null` | no |
| db\_instance\_identifier | DB instance identifier | `string` | `null` | no |
| debug\_logging | Whether the proxy includes detailed information about SQL statements in its logs | `bool` | `false` | no |
| default\_auth\_scheme | The default authentication scheme for new connections. Valid values are NONE and IAM\_AUTH. Defaults to NONE | `string` | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| endpoint\_network\_type | The type of network protocol for client connections to the proxy. Valid values are IPV4, IPV6, or DUAL. Defaults to IPV4 | `string` | `null` | no |
| endpoints | Map of DB proxy endpoints to create and their attributes (see `aws_db_proxy_endpoint`) | `any` | `{}` | no |
| engine\_family | The kind of database engine that the proxy will connect to. Valid values are `MYSQL`, `POSTGRESQL`, or `SQLSERVER` | `string` | `null` | no |
| iam\_policy\_name | The name of the role policy. If omitted, Terraform will assign a random, unique name | `string` | `null` | no |
| iam\_role\_description | The description of the role | `string` | `null` | no |
| iam\_role\_force\_detach\_policies | Specifies to force detaching any policies the role has before destroying it | `bool` | `true` | no |
| iam\_role\_max\_session\_duration | The maximum session duration (in seconds) that you want to set for the specified role | `number` | `43200` | no |
| iam\_role\_name | The name of the role. If omitted, Terraform will assign a random, unique name | `string` | `null` | no |
| iam\_role\_path | The path to the role | `string` | `null` | no |
| iam\_role\_permissions\_boundary | The ARN of the policy that is used to set the permissions boundary for the role | `string` | `null` | no |
| iam\_role\_tags | A map of tags to apply to the IAM role | `map(string)` | `{}` | no |
| idle\_client\_timeout | The number of seconds that a connection to the proxy can be inactive before the proxy disconnects it | `number` | `1800` | no |
| init\_query | One or more SQL statements for the proxy to run when opening each new database connection | `string` | `null` | no |
| kms\_key\_arns | List of KMS Key ARNs to allow access to decrypt SecretsManager secrets | `list(string)` | `[]` | no |
| log\_group\_class | Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT\_ACCESS | `string` | `null` | no |
| log\_group\_kms\_key\_id | The ARN of the KMS Key to use when encrypting log data | `string` | `null` | no |
| log\_group\_retention\_in\_days | Specifies the number of days you want to retain log events in the log group | `number` | `30` | no |
| log\_group\_skip\_destroy | Set to true if you do not wish the log group (and any logs it may contain) to be deleted at destroy time, and instead just remove the log group from the Terraform state | `bool` | `null` | no |
| log\_group\_tags | A map of tags to apply to the CloudWatch log group | `map(string)` | `{}` | no |
| manage\_log\_group | Determines whether Terraform will create/manage the CloudWatch log group or not. Note - this will fail if set to true after the log group has been created as the resource will already exist | `bool` | `true` | no |
| max\_connections\_percent | The maximum size of the connection pool for each target in a target group | `number` | `90` | no |
| max\_idle\_connections\_percent | Controls how actively the proxy closes idle database connections in the connection pool | `number` | `50` | no |
| name | Name to use for resource naming and tagging. | `string` | `null` | no |
| proxy\_tags | A map of tags to apply to the RDS Proxy | `map(string)` | `{}` | no |
| proxy\_timeouts | Create, update, and delete timeout configurations for the RDS Proxy | `map(string)` | `{}` | no |
| require\_tls | A Boolean parameter that specifies whether Transport Layer Security (TLS) encryption is required for connections to the proxy | `bool` | `true` | no |
| role\_arn | The Amazon Resource Name (ARN) of the IAM role that the proxy uses to access secrets in AWS Secrets Manager | `string` | `null` | no |
| session\_pinning\_filters | Each item in the list represents a class of SQL operations that normally cause all later statements in a session using a proxy to be pinned to the same underlying database connection | `list(string)` | `[]` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| target\_connection\_network\_type | The type of network protocol used for connections to the proxy target. Valid values are IPV4 or IPV6 | `string` | `null` | no |
| target\_db\_cluster | Determines whether DB cluster is targeted by proxy | `bool` | `false` | no |
| target\_db\_instance | Determines whether DB instance is targeted by proxy | `bool` | `false` | no |
| use\_policy\_name\_prefix | Whether to use unique name beginning with the specified `iam_policy_name` | `bool` | `false` | no |
| use\_role\_name\_prefix | Whether to use unique name beginning with the specified `iam_role_name` | `bool` | `false` | no |
| vpc\_security\_group\_ids | One or more VPC security group IDs to associate with the new proxy | `list(string)` | `[]` | no |
| vpc\_subnet\_ids | One or more VPC subnet IDs to associate with the new proxy | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| db\_proxy\_endpoints | Array containing the full resource object and attributes for all DB proxy endpoints created |
| iam\_role\_arn | The Amazon Resource Name (ARN) of the IAM role that the proxy uses to access secrets in AWS Secrets Manager. |
| iam\_role\_name | IAM role name |
| iam\_role\_unique\_id | Stable and unique string identifying the IAM role |
| log\_group\_arn | The Amazon Resource Name (ARN) of the CloudWatch log group |
| log\_group\_name | The name of the CloudWatch log group |
| proxy\_arn | The Amazon Resource Name (ARN) for the proxy |
| proxy\_default\_target\_group\_arn | The Amazon Resource Name (ARN) for the default target group |
| proxy\_default\_target\_group\_id | The ID for the default target group |
| proxy\_default\_target\_group\_name | The name of the default target group |
| proxy\_endpoint | The endpoint that you can use to connect to the proxy |
| proxy\_id | The ID for the proxy |
| proxy\_target\_endpoint | Hostname for the target RDS DB Instance. Only returned for `RDS_INSTANCE` type |
| proxy\_target\_id | Identifier of `db_proxy_name`, `target_group_name`, target type (e.g. `RDS_INSTANCE` or `TRACKED_CLUSTER`), and resource identifier separated by forward slashes (/) |
| proxy\_target\_port | Port for the target RDS DB Instance or Aurora DB Cluster |
| proxy\_target\_rds\_resource\_id | Identifier representing the DB Instance or DB Cluster target |
| proxy\_target\_target\_arn | Amazon Resource Name (ARN) for the DB instance or DB cluster. Currently not returned by the RDS API |
| proxy\_target\_tracked\_cluster\_id | DB Cluster identifier for the DB Instance target. Not returned unless manually importing an RDS\_INSTANCE target that is part of a DB Cluster |
| proxy\_target\_type | Type of target. e.g. `RDS_INSTANCE` or `TRACKED_CLUSTER` |
<!-- END_TF_DOCS -->

</details>
