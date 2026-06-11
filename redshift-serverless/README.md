# Redshift Serverless

Amazon Redshift Serverless module for on-demand analytics without cluster management. Automatically scales compute capacity based on workload.

## Features

- **Namespace and workgroup** - creates both the namespace (database, users, schemas) and workgroup (compute resources)
- **Auto-scaling capacity** - configurable base and max RPU capacity with optional price-performance targeting
- **Admin password management** - AWS Secrets Manager managed passwords, random generation, or write-only passwords (never in state)
- **KMS encryption** - optional customer-managed key for namespace encryption
- **Security group** - built-in security group with configurable ingress/egress rules
- **Usage limits** - RPU consumption caps with configurable breach actions (log, emit-metric, deactivate)
- **VPC endpoint access** - managed VPC endpoints for cross-account or private connectivity
- **Snapshots** - on-demand snapshots with configurable retention and resource policies
- **Custom domain** - associate a custom domain with ACM certificate
- **IAM role** - optional dedicated IAM role with inline or managed policies for S3/data access
- **CloudWatch logging** - export connection, user, and user activity logs
- **Random password generation** - optionally generates a random admin password when `create_random_password` is enabled (default: false; the Secrets Manager-managed admin password is the default)
- **Internal KMS key creation** - optionally create a module-managed KMS key for namespace encryption via `kms_enabled`
- **VPC endpoint by default** - a managed VPC endpoint is created by default (`endpoint_enabled` defaults to true) for private connectivity
- **Private by default** - `publicly_accessible` defaults to false, ensuring the workgroup is not reachable from public networks

## Usage

```hcl
module "redshift_serverless" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//redshift-serverless?depth=1&ref=master"

  name           = "analytics"
  namespace_name = "analytics-ns"
  workgroup_name = "analytics-wg"
  db_name        = "analyticsdb"
  admin_username = "awsadmin"

  manage_admin_password   = true
  workgroup_base_capacity = 32
  workgroup_max_capacity  = 128

  subnet_ids = module.vpc.private_subnets
  vpc_id     = module.vpc.vpc_id
}
```

## Examples

## Basic Usage

Minimal Redshift Serverless namespace and workgroup using Secrets Manager for the admin password.

```hcl
module "redshift_serverless" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//redshift-serverless?depth=1&ref=master"

  enabled          = true
  name             = "analytics"
  iam_role_enabled = false

  namespace_name  = "analytics-ns"
  workgroup_name  = "analytics-wg"
  db_name         = "analyticsdb"
  admin_username  = "awsadmin"

  manage_admin_password = true

  workgroup_base_capacity = 32
  workgroup_max_capacity  = 128

  subnet_ids = ["subnet-0aa111bbb222", "subnet-0cc333ddd444", "subnet-0ee555fff666"]
  vpc_id     = "vpc-0abc123def456789"

  security_group_rules = {
    bi_tools = {
      from_port   = 5439
      to_port     = 5439
      ip_protocol = "tcp"
      cidr_ipv4   = "10.0.0.0/8"
      description = "Allow BI tools from internal network"
    }
  }

  tags = {
    Environment = "production"
    Team        = "analytics"
  }
}
```

## With KMS Encryption and IAM Role

Redshift Serverless with a CMK, a dedicated IAM role for S3 access, and CloudWatch audit logs.

```hcl
module "redshift_serverless_encrypted" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//redshift-serverless?depth=1&ref=master"

  enabled = true
  name    = "dw"

  namespace_name  = "dw-ns"
  workgroup_name  = "dw-wg"
  db_name         = "warehouse"
  admin_username  = "dwadmin"

  manage_admin_password = true
  admin_password_secret_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"

  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"

  iam_role_enabled = true
  iam_role_name    = "redshift-serverless-s3-access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "redshift-serverless.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"

  log_exports = ["connectionlog", "userlog", "useractivitylog"]

  workgroup_base_capacity = 64
  workgroup_max_capacity  = 256

  subnet_ids = ["subnet-0aa111bbb222", "subnet-0cc333ddd444", "subnet-0ee555fff666"]
  vpc_id     = "vpc-0abc123def456789"

  security_group_rules = {
    internal = {
      from_port   = 5439
      to_port     = 5439
      ip_protocol = "tcp"
      cidr_ipv4   = "10.0.0.0/8"
    }
  }

  tags = {
    Environment = "production"
    Team        = "data"
    DataClass   = "confidential"
  }
}
```

## With Usage Limit and Write-Only Password

Redshift Serverless with a monthly RPU usage cap and a write-only admin password (never stored in state).

```hcl
module "redshift_serverless_limited" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//redshift-serverless?depth=1&ref=master"

  enabled          = true
  name             = "reporting"
  iam_role_enabled = false

  namespace_name  = "reporting-ns"
  workgroup_name  = "reporting-wg"
  db_name         = "reportingdb"
  admin_username  = "repadmin"

  manage_admin_password   = false
  use_admin_password_wo   = true
  # Provide the actual password via a variable marked sensitive=true:
  # admin_password = var.reporting_admin_password
  admin_user_password_wo_version = 1

  workgroup_base_capacity = 16
  workgroup_max_capacity  = 64

  usage_limit_enabled  = true
  usage_type           = "serverless-compute"
  usage_amount         = 100
  usage_period         = "monthly"
  usage_breach_action  = "emit-metric"

  subnet_ids = ["subnet-0aa111bbb222", "subnet-0cc333ddd444"]
  vpc_id     = "vpc-0abc123def456789"

  security_group_rules = {
    app = {
      from_port                    = 5439
      to_port                      = 5439
      ip_protocol                  = "tcp"
      referenced_security_group_id = "sg-0abc123def456789a"
    }
  }

  tags = {
    Environment = "production"
    Team        = "reporting"
  }
}
```

## Advanced - Price Performance Targeting with Custom Domain

Redshift Serverless with price-performance targeting, a custom domain, and snapshot management.

```hcl
module "redshift_serverless_advanced" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//redshift-serverless?depth=1&ref=master"

  enabled          = true
  name             = "platform-dw"
  iam_role_enabled = false

  namespace_name  = "platform-ns"
  workgroup_name  = "platform-wg"
  db_name         = "platformdb"
  admin_username  = "platformadmin"

  manage_admin_password            = true
  admin_password_secret_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"

  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"

  workgroup_base_capacity = 128
  workgroup_max_capacity  = 512

  workgroup_price_performance_target = {
    enabled = true
    level   = 75
  }

  workgroup_config_parameter = [
    {
      parameter_key   = "max_query_execution_time"
      parameter_value = "14400"
    }
  ]

  custom_domain_enabled        = true
  custom_domain_name           = "redshift.example.com"
  custom_domain_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc12345-1234-1234-1234-abc123456789"

  snapshot_enabled          = true
  snapshot_name             = "platform-dw-daily"
  snapshot_retention_period = "7"

  endpoint_enabled = true
  endpoint_name    = "platform-dw-endpoint"

  subnet_ids = ["subnet-0aa111bbb222", "subnet-0cc333ddd444", "subnet-0ee555fff666"]
  vpc_id     = "vpc-0abc123def456789"

  security_group_rules = {
    internal = {
      from_port   = 5439
      to_port     = 5439
      ip_protocol = "tcp"
      cidr_ipv4   = "10.0.0.0/8"
    }
  }

  tags = {
    Environment = "production"
    Team        = "data-platform"
    CostCenter  = "data"
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
| random | ~> 3.0 |
| time | ~> 0.12 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |
| random | ~> 3.0 |
| time | ~> 0.12 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| admin\_password | The password of the administrator for the first database created in the namespace | `string` | `null` | no |
| admin\_password\_secret\_kms\_key\_id | ID of the KMS key used to encrypt the namespace admin credentials secret when `manage_admin_password` is true | `string` | `null` | no |
| admin\_user\_password\_wo\_version | Version counter for admin\_user\_password\_wo. Increment to trigger a password rotation when use\_admin\_password\_wo is true | `number` | `1` | no |
| admin\_username | The username of the administrator for the first database created in the namespace | `string` | `null` | no |
| assume\_role\_policy | Policy that grants an entity permission to assume the role | `any` | `null` | no |
| create\_random\_password | Determines whether to create a random password for the namespace admin user when `manage_admin_password` is false. Disabled by default - prefer `manage_admin_password` so no password is stored in OpenTofu state | `bool` | `false` | no |
| create\_security\_group | Determines if a security group is created | `bool` | `true` | no |
| custom\_domain\_certificate\_arn | ARN of the certificate for the custom domain association | `string` | `null` | no |
| custom\_domain\_enabled | If `true`, custom domain is enabled | `bool` | `false` | no |
| custom\_domain\_name | Custom domain to associate with the workgroup | `string` | `null` | no |
| db\_name | The name of the first database created in the namespace | `string` | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| endpoint\_enabled | If `true`, VPC endpoint is enabled | `bool` | `true` | no |
| endpoint\_name | The Redshift-managed VPC endpoint name | `string` | `null` | no |
| endpoint\_owner\_account | The AWS account ID of the owner of the workgroup. This is only required if the workgroup is in another AWS account | `string` | `null` | no |
| endpoint\_security\_group\_ids | The security group IDs to use for the endpoint access (managed VPC endpoint) | `list(string)` | `[]` | no |
| iam\_role\_enabled | If `true`, iam role resource is enabled | `bool` | `true` | no |
| iam\_role\_name | The name of the iam role | `string` | `null` | no |
| kms\_alias | The display name of the alias. The name must start with the word 'alias' followed by a forward slash (alias/) | `string` | `"alias/redshift-serverless"` | no |
| kms\_deletion\_window\_in\_days | Duration in days after which the module-created KMS key is deleted after destruction of the resource. Must be between 7 and 30 days | `number` | `10` | no |
| kms\_enabled | If `true`, kms key is enabled | `bool` | `false` | no |
| kms\_key\_arn | The ARN for the KMS encryption key. When specifying `kms_key_arn`, `encrypted` needs to be set to `true` | `string` | `null` | no |
| kms\_key\_policy | A valid policy JSON document to attach to the module-created KMS key. Defaults to the AWS account default key policy | `string` | `null` | no |
| log\_exports | The types of logs the namespace can export. Available export types are userlog, connectionlog, and useractivitylog. | `list(string)` | `[]` | no |
| manage\_admin\_password | Whether to use AWS SecretsManager to manage the cluster admin credentials. Conflicts with `admin_password`. One of `admin_password` or `manage_admin_password` is required unless `snapshot_identifier` is provided | `bool` | `true` | no |
| managed\_policy\_arns | n/a | `set(string)` | `[]` | no |
| name | Name to use for resource naming and tagging. | `string` | `null` | no |
| namespace\_name | The name of the namespace | `string` | `null` | no |
| policy | If `true`, iam policy is enabled | `any` | `null` | no |
| policy\_arn | The ARN of the policy you want to apply | `string` | `null` | no |
| policy\_enabled | Whether to Attach Iam policy with role | `bool` | `true` | no |
| policy\_name | The name of the iam policy name | `string` | `null` | no |
| port | RedShift cluster port, default is `5439` | `number` | `5439` | no |
| publicly\_accessible | If true, the cluster can be accessed from a public network | `bool` | `false` | no |
| random\_password\_length | Length of random password to create. Defaults to `16` | `number` | `16` | no |
| security\_group\_description | Description of the security group created | `string` | `null` | no |
| security\_group\_ids | A list of existing security group IDs to associate with the workgroup, in addition to the module-created security group (if any) | `list(string)` | `[]` | no |
| security\_group\_name | Name to use on security group created | `string` | `null` | no |
| security\_group\_rules | Security group ingress and egress rules to add to the security group created | <pre>map(object({<br/>    type                         = optional(string, "ingress")<br/>    ip_protocol                  = optional(string, "tcp")<br/>    from_port                    = optional(number)<br/>    to_port                      = optional(number)<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    description                  = optional(string)<br/>    prefix_list_id               = optional(string)<br/>    referenced_security_group_id = optional(string)<br/>    tags                         = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| security\_group\_tags | A map of additional tags to add to the security group created | `map(string)` | `{}` | no |
| security\_group\_use\_name\_prefix | Determines whether the security group name (`security_group_name`) is used as a prefix | `bool` | `true` | no |
| snapshot\_enabled | If `true`, snapshot is enabled | `bool` | `false` | no |
| snapshot\_name | The name of the snapshot. | `string` | `null` | no |
| snapshot\_policy | If `true`, serverless snapshot policy is enabled | `any` | `null` | no |
| snapshot\_policy\_enabled | If `true`, snapshot policy is enabled | `bool` | `false` | no |
| snapshot\_retention\_period | How long to retain the created snapshot. Default value is -1. | `string` | `"-1"` | no |
| subnet\_ids | An array of VPC subnet IDs to use in the subnet group | `list(string)` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| usage\_amount | The limit amount. If time-based, this amount is in Redshift Processing Units (RPU) consumed per hour. If data-based, this amount is in terabytes (TB) of data transferred between Regions in cross-account sharing. The value must be a positive number. | `number` | `60` | no |
| usage\_breach\_action | The action that Amazon Redshift Serverless takes when the limit is reached. Valid values are log, emit-metric, and deactivate. The default is log. | `string` | `"log"` | no |
| usage\_limit\_enabled | If `true`, it creates a new amazon redshift serverless usage limit. | `bool` | `false` | no |
| usage\_period | The time period that the amount applies to. A weekly period begins on Sunday. Valid values are daily, weekly, and monthly. The default is monthly. | `string` | `"monthly"` | no |
| usage\_type | The type of Amazon Redshift Serverless usage to create a usage limit for. Valid values are serverless-compute or cross-region-datasharing. | `string` | `"serverless-compute"` | no |
| use\_admin\_password\_wo | Whether to use the write-only admin\_user\_password\_wo attribute instead of admin\_user\_password. When true, the password is never stored in state | `bool` | `false` | no |
| vpc\_id | Identifier of the VPC where the security group will be created | `string` | `null` | no |
| workgroup\_base\_capacity | The base data warehouse capacity of the workgroup in Redshift Processing Units (RPUs). | `number` | `16` | no |
| workgroup\_config\_parameter | An array of parameters to set for more control over a serverless database. | `list(any)` | `[]` | no |
| workgroup\_enhanced\_vpc\_routing | If `true`, enhanced VPC routing is enabled | `bool` | `null` | no |
| workgroup\_max\_capacity | The maximum data-warehouse capacity Amazon Redshift Serverless uses to serve queries, specified in Redshift Processing Units (RPUs) | `number` | `64` | no |
| workgroup\_name | The name of the workgroup | `string` | `null` | no |
| workgroup\_port | The custom port to use when connecting to a workgroup. Valid port ranges are 5431-5455 and 8191-8215. The default is 5439 | `number` | `null` | no |
| workgroup\_price\_performance\_target | The price performance target configuration for the workgroup. Set `enabled = true` and provide a `level` (1-100) to enable price performance targeting | <pre>object({<br/>    enabled = optional(bool, false)<br/>    level   = optional(number, null)<br/>  })</pre> | `null` | no |
| workgroup\_track\_name | The release track for the workgroup. Valid values are `current` or `trailing` | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| endpoint\_access\_arn | Amazon Resource Name (ARN) of the Redshift Serverless Endpoint Access. |
| endpoint\_access\_name | Amazon Resource Name (ARN) of the Redshift Serverless Endpoint Access. |
| endpoint\_address | The DNS address of the workgroup endpoint |
| limit\_arn | Amazon Resource Name (ARN) of the Redshift Serverless Usage Limit. |
| limit\_id | The Redshift Usage Limit id. |
| namespace\_arn | The Redshift Namespace ID. |
| namespace\_id | The Redshift Namespace ID. |
| namespace\_name | The Redshift Namespace Name. |
| snapshot\_accounts\_with\_restore\_access | All of the Amazon Web Services accounts that have access to restore a snapshot to a namespace. |
| snapshot\_admin\_username | The username of the database within a snapshot. |
| snapshot\_arn | The Amazon Resource Name (ARN) of the namespace the snapshot was created from. |
| snapshot\_name | The name of the snapshot. |
| snapshot\_namespace\_arn | The Amazon Resource Name (ARN) of the namespace the snapshot was created from. |
| snapshot\_owner\_account | The owner Amazon Web Services; account of the snapshot. |
| vpc\_endpoint | The VPC endpoint or the Redshift Serverless workgroup |
| vpc\_endpoint\_address | The DNS address of the VPC endpoint |
| workgroup\_arn | Amazon Resource Name (ARN) of the Redshift Serverless Workgroup. |
| workgroup\_id | The Redshift Workgroup ID. |
| workgroup\_name | The Redshift Workgroup Name. |
<!-- END_TF_DOCS -->

</details>
