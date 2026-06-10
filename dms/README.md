# AWS Database Migration Service (DMS)

Provisions the full AWS DMS stack including IAM roles, replication subnet groups, replication instances, source and target endpoints, replication tasks, event subscriptions, and SSL certificates for database migrations.

## Features

- **Complete DMS Stack** - Creates all required DMS resources in a single module: IAM roles, subnet groups, replication instances, endpoints, and replication tasks
- **IAM Role Management** - Provisions the three required DMS service-linked IAM roles (endpoint access, CloudWatch logs, VPC management) with optional Redshift target permissions
- **Replication Instance** - Configurable instance class, storage, Multi-AZ, KMS encryption, maintenance windows, and network type (IPv4/dual-stack)
- **Flexible Endpoints** - Supports standard database endpoints (MySQL, PostgreSQL, Oracle, SQL Server, Aurora, etc.) and dedicated S3 endpoints for data lake targets
- **Replication Tasks** - Defines full-load, CDC (change data capture), or full-load-and-CDC migration tasks with JSON table mappings and task settings
- **Serverless Replication** - Supports serverless replication configurations alongside traditional instance-based tasks
- **Event Subscriptions** - Configures SNS-based event notifications for replication task state changes and failures
- **SSL Certificates** - Manages DMS certificates for encrypted endpoint connections
- **Access IAM Role** - Creates a customizable IAM role for DMS to access KMS keys, Secrets Manager secrets, S3 buckets, Elasticsearch, Kinesis, and DynamoDB targets
- **Existing Infrastructure** - Supports attaching to existing replication instances and subnet groups by skipping creation of those resources

## Security notes

- **Prefer `secrets_manager_arn` over plaintext `username`/`password` in endpoints.** The `endpoints` variable is marked `sensitive`, but any plaintext credentials supplied there are still stored in OpenTofu state. With `secrets_manager_arn` (plus `secrets_manager_access_role_arn` or the module-created access role) the credentials never enter state and can be rotated in Secrets Manager.
- The access IAM policy only grants `kms:Decrypt`/`kms:DescribeKey` on the keys listed in `access_kms_key_arns`; when the list is empty the KMS statement is omitted entirely. Provide the specific key ARNs your endpoints need.

## Notes

- `repl_instance_allow_major_version_upgrade` defaults to `false`, so the replication instance will not be upgraded across major engine versions unexpectedly. Set it to `true` explicitly when you intend to perform a major version upgrade.
- Replication tasks require either `create_repl_instance = true` or an explicit `replication_instance_arn` per task (enforced via a precondition).

## Usage

```hcl
module "dms" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//dms?depth=1&ref=master"

  create_iam_roles         = true
  create_repl_subnet_group = true
  repl_subnet_group_name   = "dms-migration-subnets"
  repl_subnet_group_subnet_ids = ["subnet-0aaa111122223333", "subnet-0bbb444455556666"]

  create_repl_instance = true
  repl_instance_id     = "dms-migration"
  repl_instance_class  = "dms.r5.large"

  # For production, use secrets_manager_arn instead of plaintext username/password.
  # See the "Existing Replication Instance" example for a secrets_manager_arn configuration.
  endpoints = {
    source = {
      endpoint_id   = "mysql-source"
      endpoint_type = "source"
      engine_name   = "mysql"
      server_name   = "mysql-source.rds.amazonaws.com"
      port          = 3306
      database_name = "appdb"
      username      = "dms_user"
      password      = "changeme-use-secrets-manager"
    }
    target = {
      endpoint_id   = "aurora-pg-target"
      endpoint_type = "target"
      engine_name   = "aurora-postgresql"
      server_name   = "aurora-cluster.rds.amazonaws.com"
      port          = 5432
      database_name = "appdb"
      username      = "dms_user"
      password      = "changeme-use-secrets-manager"
    }
  }

  tags = {
    Environment = "production"
    Team        = "data-engineering"
  }
}
```


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11.0 |
| aws | >= 6.49, < 7.0 |
| time | ~> 0.12 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |
| time | ~> 0.12 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| access\_iam\_role\_description | Description of the role | `string` | `null` | no |
| access\_iam\_role\_name | Name to use on IAM role created | `string` | `null` | no |
| access\_iam\_role\_path | IAM role path | `string` | `null` | no |
| access\_iam\_role\_permissions\_boundary | ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| access\_iam\_role\_policies | Map of IAM role policy ARNs to attach to the IAM role | `map(string)` | `{}` | no |
| access\_iam\_role\_tags | A map of additional tags to add to the IAM role created | `map(string)` | `{}` | no |
| access\_iam\_role\_use\_name\_prefix | Determines whether the IAM role name (`access_iam_role_name`) is used as a prefix | `bool` | `true` | no |
| access\_iam\_statements | A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage | `any` | `{}` | no |
| access\_kms\_key\_arns | A list of KMS key ARNs the access IAM role is permitted to decrypt | `list(string)` | `[]` | no |
| access\_secret\_arns | A list of SecretManager secret ARNs the access IAM role is permitted to access | `list(string)` | `[]` | no |
| access\_source\_s3\_bucket\_arns | A list of S3 bucket ARNs the access IAM role is permitted to access | `list(string)` | `[]` | no |
| access\_target\_dynamodb\_table\_arns | A list of DynamoDB table ARNs the access IAM role is permitted to access | `list(string)` | `[]` | no |
| access\_target\_elasticsearch\_arns | A list of Elasticsearch ARNs the access IAM role is permitted to access | `list(string)` | `[]` | no |
| access\_target\_kinesis\_arns | A list of Kinesis ARNs the access IAM role is permitted to access | `list(string)` | `[]` | no |
| access\_target\_s3\_bucket\_arns | A list of S3 bucket ARNs the access IAM role is permitted to access | `list(string)` | `[]` | no |
| certificates | Map of objects that define the certificates to be created | `map(any)` | `{}` | no |
| create\_access\_iam\_role | Determines whether the ECS task definition IAM role should be created | `bool` | `true` | no |
| create\_access\_policy | Determines whether the IAM policy should be created | `bool` | `true` | no |
| create\_iam\_roles | Determines whether the required [DMS IAM resources](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.html#CHAP_Security.APIRole) will be created | `bool` | `true` | no |
| create\_repl\_instance | Indicates whether a replication instace should be created | `bool` | `true` | no |
| create\_repl\_subnet\_group | Determines whether the replication subnet group will be created | `bool` | `true` | no |
| enable\_redshift\_target\_permissions | Determines whether `redshift.amazonaws.com` is permitted access to assume the `dms-access-for-endpoint` role | `bool` | `false` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| endpoint\_timeouts | A map of timeouts for endpoint create/delete operations | `map(string)` | `{}` | no |
| endpoints | Map of objects that define the endpoints to be created. May contain plaintext credentials (`username`/`password`, Kafka SASL, Redis auth) - prefer `secrets_manager_arn` so credentials live in Secrets Manager instead of OpenTofu state | `any` | `{}` | no |
| event\_subscription\_timeouts | A map of timeouts for event subscription create/update/delete operations | `map(string)` | `{}` | no |
| event\_subscriptions | Map of objects that define the event subscriptions to be created | `any` | `{}` | no |
| iam\_role\_permissions\_boundary | ARN of the policy that is used to set the permissions boundary for the role | `string` | `null` | no |
| iam\_role\_tags | A map of additional tags to apply to the DMS IAM roles | `map(string)` | `{}` | no |
| repl\_config\_timeouts | A map of timeouts for serverless replication config create/update/delete operations | `map(string)` | `{}` | no |
| repl\_instance\_allocated\_storage | The amount of storage (in gigabytes) to be initially allocated for the replication instance. Min: 5, Max: 6144, Default: 50 | `number` | `null` | no |
| repl\_instance\_allow\_major\_version\_upgrade | Indicates that major version upgrades are allowed. Disabled by default so the replication instance is not upgraded across major engine versions unexpectedly | `bool` | `false` | no |
| repl\_instance\_apply\_immediately | Indicates whether the changes should be applied immediately or during the next maintenance window | `bool` | `null` | no |
| repl\_instance\_auto\_minor\_version\_upgrade | Indicates that minor engine upgrades will be applied automatically to the replication instance during the maintenance window | `bool` | `true` | no |
| repl\_instance\_availability\_zone | The EC2 Availability Zone that the replication instance will be created in | `string` | `null` | no |
| repl\_instance\_class | The compute and memory capacity of the replication instance as specified by the replication instance class | `string` | `null` | no |
| repl\_instance\_dns\_name\_servers | Custom DNS name servers separated by a space for the replication instance | `string` | `null` | no |
| repl\_instance\_engine\_version | The [engine version](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_ReleaseNotes.html) number of the replication instance | `string` | `null` | no |
| repl\_instance\_id | The replication instance identifier. This parameter is stored as a lowercase string | `string` | `null` | no |
| repl\_instance\_kerberos\_authentication\_settings | Kerberos authentication settings for the replication instance. Includes key\_cache\_secret\_iam\_arn, key\_cache\_secret\_id, and krb5\_file\_contents | `any` | `null` | no |
| repl\_instance\_kms\_key\_arn | The Amazon Resource Name (ARN) for the KMS key that will be used to encrypt the connection parameters | `string` | `null` | no |
| repl\_instance\_multi\_az | Specifies if the replication instance is a multi-az deployment. You cannot set the `availability_zone` parameter if the `multi_az` parameter is set to `true` | `bool` | `null` | no |
| repl\_instance\_network\_type | The type of IP address protocol used by a replication instance. Valid values: IPV4, DUAL | `string` | `null` | no |
| repl\_instance\_preferred\_maintenance\_window | The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC) | `string` | `null` | no |
| repl\_instance\_publicly\_accessible | Specifies the accessibility options for the replication instance | `bool` | `false` | no |
| repl\_instance\_subnet\_group\_id | An existing subnet group to associate with the replication instance | `string` | `null` | no |
| repl\_instance\_tags | A map of additional tags to apply to the replication instance | `map(string)` | `{}` | no |
| repl\_instance\_timeouts | A map of timeouts for replication instance create/update/delete operations | `map(string)` | `{}` | no |
| repl\_instance\_vpc\_security\_group\_ids | A list of VPC security group IDs to be used with the replication instance | `list(string)` | `null` | no |
| repl\_subnet\_group\_description | The description for the subnet group | `string` | `null` | no |
| repl\_subnet\_group\_name | The name for the replication subnet group. Stored as a lowercase string, must contain no more than 255 alphanumeric characters, periods, spaces, underscores, or hyphens | `string` | `null` | no |
| repl\_subnet\_group\_subnet\_ids | A list of the EC2 subnet IDs for the subnet group | `list(string)` | `[]` | no |
| repl\_subnet\_group\_tags | A map of additional tags to apply to the replication subnet group | `map(string)` | `{}` | no |
| replication\_tasks | Map of objects that define the replication tasks to be created | `any` | `{}` | no |
| s3\_endpoints | Map of objects that define the S3 endpoints to be created | `any` | `{}` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| access\_iam\_role\_arn | Access IAM role ARN |
| access\_iam\_role\_name | Access IAM role name |
| access\_iam\_role\_unique\_id | Stable and unique string identifying the access IAM role |
| certificates | A map of maps containing the certificates created and their full output of attributes and values |
| dms\_access\_for\_endpoint\_iam\_role\_arn | Amazon Resource Name (ARN) specifying the role |
| dms\_access\_for\_endpoint\_iam\_role\_id | Name of the IAM role |
| dms\_access\_for\_endpoint\_iam\_role\_unique\_id | Stable and unique string identifying the role |
| dms\_cloudwatch\_logs\_iam\_role\_arn | Amazon Resource Name (ARN) specifying the role |
| dms\_cloudwatch\_logs\_iam\_role\_id | Name of the IAM role |
| dms\_cloudwatch\_logs\_iam\_role\_unique\_id | Stable and unique string identifying the role |
| dms\_vpc\_iam\_role\_arn | Amazon Resource Name (ARN) specifying the role |
| dms\_vpc\_iam\_role\_id | Name of the IAM role |
| dms\_vpc\_iam\_role\_unique\_id | Stable and unique string identifying the role |
| endpoints | A map of maps containing the endpoints created and their full output of attributes and values |
| event\_subscriptions | A map of maps containing the event subscriptions created and their full output of attributes and values |
| replication\_instance\_arn | The Amazon Resource Name (ARN) of the replication instance |
| replication\_instance\_private\_ips | A list of the private IP addresses of the replication instance |
| replication\_instance\_public\_ips | A list of the public IP addresses of the replication instance |
| replication\_instance\_tags\_all | A map of tags assigned to the resource, including those inherited from the provider `default_tags` configuration block |
| replication\_subnet\_group\_id | The ID of the subnet group |
| replication\_tasks | A map of maps containing the replication tasks created and their full output of attributes and values |
| s3\_endpoints | A map of maps containing the S3 endpoints created and their full output of attributes and values |
| serverless\_replication\_tasks | A map of maps containing the serverless replication tasks (replication\_config) created and their full output of attributes and values |
<!-- END_TF_DOCS -->

## Examples

## Basic Usage - MySQL to Aurora PostgreSQL Migration

Provisions the full DMS stack: required IAM roles, a replication subnet group, a replication instance, source and target endpoints, and a full-load migration task.

```hcl
module "dms_mysql_to_aurora" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//dms?depth=1&ref=master"

  enabled = true

  create_iam_roles = true

  # Subnet group
  create_repl_subnet_group        = true
  repl_subnet_group_name          = "dms-migration-subnets"
  repl_subnet_group_description   = "Subnet group for DMS replication instance"
  repl_subnet_group_subnet_ids    = [
    "subnet-0aaa111122223333",
    "subnet-0bbb444455556666",
  ]

  # Replication instance
  create_repl_instance              = true
  repl_instance_id                  = "dms-mysql-to-aurora"
  repl_instance_class               = "dms.r5.large"
  repl_instance_engine_version      = "3.5.3"
  repl_instance_allocated_storage   = 100
  repl_instance_multi_az            = true
  repl_instance_publicly_accessible = false
  repl_instance_vpc_security_group_ids = ["sg-0cc77788899900001"]

  # Source: MySQL
  endpoints = {
    source = {
      endpoint_id   = "mysql-source"
      endpoint_type = "source"
      engine_name   = "mysql"
      server_name   = "mysql-source.us-east-1.rds.amazonaws.com"
      port          = 3306
      database_name = "appdb"
      username      = "dms_user"
      password      = "changeme-use-secrets-manager"
      ssl_mode      = "require"
    }
    target = {
      endpoint_id   = "aurora-pg-target"
      endpoint_type = "target"
      engine_name   = "aurora-postgresql"
      server_name   = "aurora-cluster.cluster-abc123.us-east-1.rds.amazonaws.com"
      port          = 5432
      database_name = "appdb"
      username      = "dms_user"
      password      = "changeme-use-secrets-manager"
      ssl_mode      = "require"
    }
  }

  # Replication task
  replication_tasks = {
    full_load = {
      replication_task_id       = "mysql-to-aurora-full-load"
      migration_type            = "full-load"
      source_endpoint_key       = "source"
      target_endpoint_key       = "target"
      replication_instance_arn  = module.dms_mysql_to_aurora.replication_instance_arn
      table_mappings = jsonencode({
        rules = [{
          rule-type = "selection"
          rule-id   = "1"
          rule-name = "include-all"
          object-locator = {
            schema-name = "%"
            table-name  = "%"
          }
          rule-action = "include"
        }]
      })
    }
  }

  tags = {
    Environment = "production"
    Team        = "data-engineering"
  }
}
```

## Ongoing Replication with Event Subscriptions

Configures full-load-and-CDC (change data capture) replication from an Oracle source to S3 for a data lake, with SNS event notifications on task failures.

```hcl
module "dms_oracle_to_s3" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//dms?depth=1&ref=master"

  enabled = true

  create_iam_roles = true

  # Subnet group
  create_repl_subnet_group      = true
  repl_subnet_group_name        = "dms-oracle-s3-subnets"
  repl_subnet_group_subnet_ids  = [
    "subnet-0aaa111122223333",
    "subnet-0bbb444455556666",
  ]

  # Replication instance
  create_repl_instance              = true
  repl_instance_id                  = "dms-oracle-s3"
  repl_instance_class               = "dms.r5.xlarge"
  repl_instance_engine_version      = "3.5.3"
  repl_instance_allocated_storage   = 500
  repl_instance_multi_az            = true
  repl_instance_publicly_accessible = false
  repl_instance_vpc_security_group_ids = ["sg-0cc77788899900001"]
  repl_instance_kms_key_arn         = "arn:aws:kms:us-east-1:123456789012:key/mrk-1234abcd5678efgh"
  repl_instance_preferred_maintenance_window = "sun:03:00-sun:04:00"

  endpoints = {
    oracle_source = {
      endpoint_id     = "oracle-source"
      endpoint_type   = "source"
      engine_name     = "oracle"
      server_name     = "oracle-db.us-east-1.rds.amazonaws.com"
      port            = 1521
      database_name   = "ORCL"
      username        = "dms_user"
      password        = "changeme-use-secrets-manager"
      ssl_mode        = "require"
    }
    s3_target = {
      endpoint_id   = "s3-data-lake"
      endpoint_type = "target"
      engine_name   = "s3"
      s3_settings = {
        bucket_name             = "my-data-lake-bucket"
        bucket_folder           = "oracle-cdc"
        compression_type        = "GZIP"
        data_format             = "parquet"
        service_access_role_arn = "arn:aws:iam::123456789012:role/dms-s3-access-role"
      }
    }
  }

  replication_tasks = {
    full_load_cdc = {
      replication_task_id      = "oracle-to-s3-cdc"
      migration_type           = "full-load-and-cdc"
      source_endpoint_key      = "oracle_source"
      target_endpoint_key      = "s3_target"
      replication_instance_arn = module.dms_oracle_to_s3.replication_instance_arn
      table_mappings = jsonencode({
        rules = [{
          rule-type = "selection"
          rule-id   = "1"
          rule-name = "include-sales-schema"
          object-locator = {
            schema-name = "SALES"
            table-name  = "%"
          }
          rule-action = "include"
        }]
      })
    }
  }

  event_subscriptions = {
    task_failure = {
      name             = "dms-task-failure-alerts"
      enabled          = true
      event_categories = ["failure", "state change"]
      source_type      = "replication-task"
      sns_topic_arn    = "arn:aws:sns:us-east-1:123456789012:dms-alerts"
    }
  }

  tags = {
    Environment = "production"
    Team        = "data-engineering"
  }
}
```

## Existing Replication Instance - Endpoints and Tasks Only

Attaches new endpoints and a migration task to an existing replication instance and subnet group, skipping IAM role creation when they already exist in the account.

```hcl
module "dms_endpoints_only" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//dms?depth=1&ref=master"

  enabled = true

  create_iam_roles       = false
  create_repl_subnet_group = false
  create_repl_instance   = false
  repl_instance_subnet_group_id = "dms-existing-subnet-group"

  access_iam_role_name = "dms-access-role-existing"

  access_kms_key_arns = [
    "arn:aws:kms:us-east-1:123456789012:key/mrk-1234abcd5678efgh",
  ]
  access_secret_arns = [
    "arn:aws:secretsmanager:us-east-1:123456789012:secret:dms/source-db-credentials-AbCdEf",
    "arn:aws:secretsmanager:us-east-1:123456789012:secret:dms/target-db-credentials-GhIjKl",
  ]

  endpoints = {
    pg_source = {
      endpoint_id                 = "postgres-source"
      endpoint_type               = "source"
      engine_name                 = "postgres"
      secrets_manager_arn         = "arn:aws:secretsmanager:us-east-1:123456789012:secret:dms/source-db-credentials-AbCdEf"
      secrets_manager_access_role_arn = "arn:aws:iam::123456789012:role/dms-secrets-access-role"
      database_name               = "appdb"
      ssl_mode                    = "require"
    }
    pg_target = {
      endpoint_id                 = "postgres-target"
      endpoint_type               = "target"
      engine_name                 = "postgres"
      secrets_manager_arn         = "arn:aws:secretsmanager:us-east-1:123456789012:secret:dms/target-db-credentials-GhIjKl"
      secrets_manager_access_role_arn = "arn:aws:iam::123456789012:role/dms-secrets-access-role"
      database_name               = "appdb_replica"
      ssl_mode                    = "require"
    }
  }

  replication_tasks = {
    migrate = {
      replication_task_id      = "pg-to-pg-migrate"
      migration_type           = "full-load"
      source_endpoint_key      = "pg_source"
      target_endpoint_key      = "pg_target"
      replication_instance_arn = "arn:aws:dms:us-east-1:123456789012:rep:ABCDEFGHIJKLMNOPQRST"
      table_mappings = jsonencode({
        rules = [{
          rule-type = "selection"
          rule-id   = "1"
          rule-name = "include-all"
          object-locator = {
            schema-name = "public"
            table-name  = "%"
          }
          rule-action = "include"
        }]
      })
    }
  }

  tags = {
    Environment = "staging"
    Team        = "data-engineering"
  }
}
```
