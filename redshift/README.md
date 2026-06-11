# Redshift

Provisions Amazon Redshift clusters with support for single-node and multi-node configurations, RA3 node types, managed credentials, scheduled actions, snapshot schedules, and comprehensive security controls.

## Features

- **Flexible Cluster Sizing** - Deploy single-node or multi-node clusters that automatically switch cluster type based on the number of nodes
- **Secrets Manager Integration** - Optionally manage the master password through AWS Secrets Manager with automatic rotation, or use write-only passwords that are never stored in state
- **Random Password Generation** - Generate secure random passwords for the master user when not using Secrets Manager
- **Parameter and Subnet Groups** - Create custom Redshift parameter groups and subnet groups, or reference existing ones
- **Snapshot Schedules** - Define automated snapshot schedules with cron or rate expressions
- **Scheduled Actions** - Configure time-based cluster operations such as pause, resume, and resize for cost optimization
- **Security Group Management** - Automatically create and configure VPC security groups with flexible ingress and egress rules
- **Endpoint Access** - Create Redshift-managed VPC endpoints for private connectivity
- **Usage Limits** - Set concurrency scaling and spectrum usage limits with configurable breach actions
- **Authentication Profiles** - Define named authentication profiles for client connection management
- **Logging** - Configure audit logging to S3 or CloudWatch with managed log group creation
- **Snapshot Copy** - Enable cross-region snapshot replication for disaster recovery
- **Multi-AZ** - Support for multi-AZ deployments with RA3 instance families
- **Encryption** - Enable at-rest encryption with KMS customer-managed keys

## Notes

- **`master_password` changes are ignored after creation** - the cluster resource has `lifecycle { ignore_changes = [master_password] }`, so changing `master_password` (or the generated random password) after the cluster exists will *not* update the actual password. Rotate credentials via `manage_master_password` (Secrets Manager rotation) or the write-only path (`use_master_password_wo` + incrementing `master_password_wo_version`).

## Usage

```hcl
module "redshift" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//redshift?depth=1&ref=master"

  name               = "analytics"
  cluster_identifier = "analytics-prod"
  node_type          = "ra3.xlplus"
  number_of_nodes    = 1
  database_name      = "analyticsdb"
  master_username    = "awsuser"

  # Admin password is managed in Secrets Manager by default
  # (manage_master_password = true)

  subnet_ids = ["subnet-aaa", "subnet-bbb"]
  vpc_id     = "vpc-0abc123def456789"

  security_group_rules = {
    bi_tools = {
      from_port                    = 5439
      to_port                      = 5439
      ip_protocol                  = "tcp"
      referenced_security_group_id = "sg-0abc123def456789a"
    }
  }

  tags = {
    Environment = "production"
  }
}
```

## Examples

## Basic Usage

Single-node Redshift cluster with a randomly generated password (instead of the default Secrets Manager-managed password) and auto-created subnet and parameter groups.

```hcl
module "redshift" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//redshift?depth=1&ref=master"

  enabled = true
  name    = "analytics"

  cluster_identifier = "analytics-prod"
  node_type          = "ra3.xlplus"
  number_of_nodes    = 1
  database_name      = "analyticsdb"
  master_username    = "awsuser"

  manage_master_password = false
  create_random_password = true

  subnet_ids = ["subnet-0aa111bbb222", "subnet-0cc333ddd444"]
  vpc_id     = "vpc-0abc123def456789"

  security_group_rules = {
    app_ingress = {
      from_port                    = 5439
      to_port                      = 5439
      ip_protocol                  = "tcp"
      referenced_security_group_id = "sg-0abc123def456789a"
      description                  = "Allow BI tools access"
    }
  }

  tags = {
    Environment = "production"
    Team        = "data"
  }
}
```

## Multi-Node with KMS Encryption

Three-node RA3 cluster with CMK encryption, enhanced VPC routing, and S3-based audit logging.

```hcl
module "redshift_multi_node" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//redshift?depth=1&ref=master"

  enabled = true
  name    = "dw"

  cluster_identifier = "dw-prod"
  node_type          = "ra3.4xlarge"
  number_of_nodes    = 3
  database_name      = "warehouse"
  master_username    = "dwadmin"

  manage_master_password = false
  create_random_password = true

  encrypted   = true
  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"

  enhanced_vpc_routing = true

  subnet_ids = ["subnet-0aa111bbb222", "subnet-0cc333ddd444", "subnet-0ee555fff666"]
  vpc_id     = "vpc-0abc123def456789"

  security_group_rules = {
    bi_tools = {
      from_port                    = 5439
      to_port                      = 5439
      ip_protocol                  = "tcp"
      referenced_security_group_id = "sg-0abc123def456789a"
      description                  = "Allow BI tools"
    }
  }

  logging = {
    log_destination_type = "s3"
    bucket_name          = "my-redshift-audit-logs-123456789012"
    s3_key_prefix        = "dw-prod/"
    log_exports          = ["connectionlog", "userlog", "useractivitylog"]
  }

  create_cloudwatch_log_group            = true
  cloudwatch_log_group_retention_in_days = 30

  preferred_maintenance_window = "sun:10:00-sun:11:00"
  automated_snapshot_retention_period = 7

  tags = {
    Environment = "production"
    Team        = "data"
    DataClass   = "confidential"
  }
}
```

## With Secrets Manager-Managed Password and Snapshot Schedule

RA3 cluster using Secrets Manager for credential rotation and a custom snapshot schedule.

```hcl
module "redshift_managed_secret" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//redshift?depth=1&ref=master"

  enabled = true
  name    = "reporting"

  cluster_identifier = "reporting-prod"
  node_type          = "ra3.xlplus"
  number_of_nodes    = 2
  database_name      = "reportingdb"
  master_username    = "reportingadmin"

  manage_master_password    = true
  create_random_password    = false

  encrypted   = true
  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"

  subnet_ids = ["subnet-0aa111bbb222", "subnet-0cc333ddd444"]
  vpc_id     = "vpc-0abc123def456789"

  security_group_rules = {
    analytics_ingress = {
      from_port   = 5439
      to_port     = 5439
      ip_protocol = "tcp"
      cidr_ipv4   = "10.0.0.0/8"
      description = "Allow from internal network"
    }
  }

  create_snapshot_schedule = true
  snapshot_schedule_identifier = "reporting-daily"
  snapshot_schedule_definitions = ["cron(0 20 * * ? *)"]

  manage_master_password_rotation                   = true
  master_password_rotation_automatically_after_days = 30

  tags = {
    Environment = "production"
    Team        = "reporting"
  }
}
```

## Advanced - Multi-AZ with Scheduled Resize Actions

Multi-AZ RA3 cluster with scheduled actions to scale down outside business hours and usage limits.

```hcl
module "redshift_advanced" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//redshift?depth=1&ref=master"

  enabled = true
  name    = "etl"

  cluster_identifier                   = "etl-prod"
  node_type                            = "ra3.4xlarge"
  number_of_nodes                      = 4
  database_name                        = "etldb"
  master_username                      = "etladmin"
  manage_master_password               = false
  create_random_password               = true
  encrypted                            = true
  kms_key_arn                          = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"
  multi_az                             = true
  availability_zone_relocation_enabled = true

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

  create_scheduled_action_iam_role = true

  scheduled_actions = {
    scale_down_weekend = {
      name        = "etl-scale-down"
      description = "Scale down to 2 nodes on weekends"
      schedule    = "cron(0 20 ? * FRI *)"
      resize_cluster = {
        node_type       = "ra3.xlplus"
        number_of_nodes = 2
      }
    }
    scale_up_monday = {
      name        = "etl-scale-up"
      description = "Scale back up Monday morning"
      schedule    = "cron(0 6 ? * MON *)"
      resize_cluster = {
        node_type       = "ra3.4xlarge"
        number_of_nodes = 4
      }
    }
  }

  usage_limits = {
    daily_compute = {
      feature_type  = "concurrency-scaling"
      limit_type    = "time"
      amount        = 60
      period        = "daily"
      breach_action = "emit-metric"
    }
  }

  tags = {
    Environment = "production"
    Team        = "data-engineering"
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

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |
| random | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| allow\_version\_upgrade | If `true`, major version upgrades can be applied during the maintenance window to the Amazon Redshift engine that is running on the cluster. Default is `true` | `bool` | `null` | no |
| apply\_immediately | Specifies whether any cluster modifications are applied immediately, or during the next maintenance window. Default is `false` | `bool` | `null` | no |
| aqua\_configuration\_status | The value represents how the cluster is configured to use AQUA (Advanced Query Accelerator) after the cluster is restored. Possible values are `enabled`, `disabled`, and `auto`. Requires `node_type` to be RA3 | `string` | `null` | no |
| authentication\_profiles | Map of authentication profiles to create | `any` | `{}` | no |
| automated\_snapshot\_retention\_period | The number of days that automated snapshots are retained. If the value is 0, automated snapshots are disabled. Even if automated snapshots are disabled, you can still create manual snapshots when you want with create-cluster-snapshot. Defaults to 7 | `number` | `7` | no |
| availability\_zone | The EC2 Availability Zone (AZ) in which you want Amazon Redshift to provision the cluster. Can only be changed if `availability_zone_relocation_enabled` is `true` | `string` | `null` | no |
| availability\_zone\_relocation\_enabled | If `true`, the cluster can be relocated to another availability zone, either automatically by AWS or when requested. Default is `false`. Available for use on clusters from the RA3 instance family | `bool` | `null` | no |
| cloudwatch\_log\_group\_class | Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT\_ACCESS | `string` | `null` | no |
| cloudwatch\_log\_group\_kms\_key\_id | The ARN of the KMS Key to use when encrypting log data | `string` | `null` | no |
| cloudwatch\_log\_group\_retention\_in\_days | The number of days to retain CloudWatch logs for the redshift cluster | `number` | `30` | no |
| cloudwatch\_log\_group\_skip\_destroy | Set to true if you do not wish the log group (and any logs it may contain) to be deleted at destroy time, and instead just remove the log group from the Terraform state | `bool` | `null` | no |
| cloudwatch\_log\_group\_tags | Additional tags to add to cloudwatch log groups created | `map(string)` | `{}` | no |
| cluster\_identifier | The Cluster Identifier. Must be a lower case string | `string` | `null` | no |
| cluster\_timeouts | Create, update, and delete timeout configurations for the cluster | `map(string)` | `{}` | no |
| cluster\_version | The version of the Amazon Redshift engine software that you want to deploy on the cluster. The version selected runs on all the nodes in the cluster | `string` | `null` | no |
| create\_cloudwatch\_log\_group | Determines whether a CloudWatch log group is created for each `var.logging.log_exports` | `bool` | `false` | no |
| create\_endpoint\_access | Determines whether to create an endpoint access (managed VPC endpoint) | `bool` | `false` | no |
| create\_parameter\_group | Determines whether to create a parameter group or use existing | `bool` | `true` | no |
| create\_random\_password | Determines whether to create random password for cluster `master_password`. Disabled by default - prefer `manage_master_password` so no password is stored in OpenTofu state | `bool` | `false` | no |
| create\_scheduled\_action\_iam\_role | Determines whether a scheduled action IAM role is created | `bool` | `false` | no |
| create\_security\_group | Determines if a security group is created | `bool` | `true` | no |
| create\_snapshot\_schedule | Determines whether to create a snapshot schedule | `bool` | `false` | no |
| create\_subnet\_group | Determines whether to create a subnet group or use existing | `bool` | `true` | no |
| database\_name | The name of the first database to be created when the cluster is created. If you do not provide a name, Amazon Redshift will create a default database called `dev` | `string` | `null` | no |
| default\_iam\_role\_arn | The Amazon Resource Name (ARN) for the IAM role that was set as default for the cluster when the cluster was created | `string` | `null` | no |
| elastic\_ip | The Elastic IP (EIP) address for the cluster | `string` | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| encrypted | If `true`, the data in the cluster is encrypted at rest | `bool` | `true` | no |
| endpoint\_name | The Redshift-managed VPC endpoint name | `string` | `null` | no |
| endpoint\_resource\_owner | The Amazon Web Services account ID of the owner of the cluster. This is only required if the cluster is in another Amazon Web Services account | `string` | `null` | no |
| endpoint\_subnet\_group\_name | The subnet group from which Amazon Redshift chooses the subnet to deploy the endpoint | `string` | `null` | no |
| endpoint\_vpc\_security\_group\_ids | The security group IDs to use for the endpoint access (managed VPC endpoint) | `list(string)` | `[]` | no |
| enhanced\_vpc\_routing | If `true`, enhanced VPC routing is enabled | `bool` | `null` | no |
| final\_snapshot\_identifier | The identifier of the final snapshot that is to be created immediately before deleting the cluster. If this parameter is provided, `skip_final_snapshot` must be `false` | `string` | `null` | no |
| iam\_role\_arns | A list of IAM Role ARNs to associate with the cluster. A Maximum of 10 can be associated to the cluster at any time | `list(string)` | `[]` | no |
| iam\_role\_description | Description of the scheduled action IAM role | `string` | `null` | no |
| iam\_role\_name | Name to use on scheduled action IAM role created | `string` | `null` | no |
| iam\_role\_path | Scheduled action IAM role path | `string` | `null` | no |
| iam\_role\_permissions\_boundary | ARN of the policy that is used to set the permissions boundary for the scheduled action IAM role | `string` | `null` | no |
| iam\_role\_tags | A map of additional tags to add to the scheduled action IAM role created | `map(string)` | `{}` | no |
| iam\_role\_use\_name\_prefix | Determines whether scheduled action the IAM role name (`iam_role_name`) is used as a prefix | `bool` | `true` | no |
| kms\_key\_arn | The ARN for the KMS encryption key. When specifying `kms_key_arn`, `encrypted` needs to be set to `true` | `string` | `null` | no |
| logging | Logging configuration for the cluster | `any` | `{}` | no |
| maintenance\_track\_name | The name of the maintenance track for the restored cluster. When you take a snapshot, the snapshot inherits the MaintenanceTrack value from the cluster. The snapshot might be on a different track than the cluster that was the source for the snapshot. Default value is `current` | `string` | `null` | no |
| manage\_master\_password | Whether to use AWS SecretsManager to manage the cluster admin credentials. Enabled by default so no password is stored in OpenTofu state. Conflicts with `master_password`. One of `master_password` or `manage_master_password` is required unless `snapshot_identifier` is provided | `bool` | `true` | no |
| manage\_master\_password\_rotation | Whether to manage the master user password rotation. Setting this value to false after previously having been set to true will disable automatic rotation. | `bool` | `false` | no |
| manual\_snapshot\_retention\_period | The default number of days to retain a manual snapshot. If the value is -1, the snapshot is retained indefinitely. This setting doesn't change the retention period of existing snapshots. Valid values are between `-1` and `3653`. Default value is `-1` | `number` | `null` | no |
| master\_password | Password for the master DB user. (Required unless a `snapshot_identifier` is provided). Must contain at least 8 chars, one uppercase letter, one lowercase letter, and one number. Conflicts with `use_master_password_wo` | `string` | `null` | no |
| master\_password\_rotate\_immediately | Specifies whether to rotate the secret immediately or wait until the next scheduled rotation window. | `bool` | `null` | no |
| master\_password\_rotation\_automatically\_after\_days | Specifies the number of days between automatic scheduled rotations of the secret. Either `master_user_password_rotation_automatically_after_days` or `master_user_password_rotation_schedule_expression` must be specified. | `number` | `null` | no |
| master\_password\_rotation\_duration | The length of the rotation window in hours. For example, 3h for a three hour window. | `string` | `null` | no |
| master\_password\_rotation\_schedule\_expression | A cron() or rate() expression that defines the schedule for rotating your secret. Either `master_user_password_rotation_automatically_after_days` or `master_user_password_rotation_schedule_expression` must be specified. | `string` | `null` | no |
| master\_password\_secret\_kms\_key\_id | ID of the KMS key used to encrypt the cluster admin credentials secret | `string` | `null` | no |
| master\_password\_wo\_version | Version counter for `master_password_wo`. Increment to trigger a password rotation when `use_master_password_wo` is true | `number` | `1` | no |
| master\_username | Username for the master DB user (Required unless a `snapshot_identifier` is provided). Defaults to `awsuser` | `string` | `"awsuser"` | no |
| multi\_az | Specifies if the Redshift cluster is multi-AZ | `bool` | `null` | no |
| name | Name to use for resource naming and tagging. | `string` | `null` | no |
| node\_type | The node type to be provisioned for the cluster | `string` | `null` | no |
| number\_of\_nodes | Number of nodes in the cluster. Defaults to 1. Note: values greater than 1 will trigger `cluster_type` to switch to `multi-node` | `number` | `1` | no |
| owner\_account | The AWS customer account used to create or copy the snapshot. Required if you are restoring a snapshot you do not own, optional if you own the snapshot | `string` | `null` | no |
| parameter\_group\_description | The description of the Redshift parameter group. Defaults to `Managed by Terraform` | `string` | `null` | no |
| parameter\_group\_family | The family of the Redshift parameter group | `string` | `"redshift-1.0"` | no |
| parameter\_group\_name | The name of the Redshift parameter group, existing or to be created | `string` | `null` | no |
| parameter\_group\_parameters | value | `map(any)` | `{}` | no |
| parameter\_group\_tags | Additional tags to add to the parameter group | `map(string)` | `{}` | no |
| port | The port number on which the cluster accepts incoming connections. Default port is 5439 | `number` | `null` | no |
| preferred\_maintenance\_window | The weekly time range (in UTC) during which automated cluster maintenance can occur. Format: `ddd:hh24:mi-ddd:hh24:mi` | `string` | `"sat:10:00-sat:10:30"` | no |
| publicly\_accessible | If true, the cluster can be accessed from a public network | `bool` | `false` | no |
| random\_password\_length | Length of random password to create. Defaults to `16` | `number` | `16` | no |
| scheduled\_actions | Map of maps containing scheduled action definitions | `any` | `{}` | no |
| security\_group\_description | Description of the security group created | `string` | `null` | no |
| security\_group\_name | Name to use on security group created | `string` | `null` | no |
| security\_group\_rules | Security group ingress and egress rules to add to the security group created | <pre>map(object({<br/>    type                         = optional(string, "ingress")<br/>    ip_protocol                  = optional(string, "tcp")<br/>    from_port                    = optional(number)<br/>    to_port                      = optional(number)<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    description                  = optional(string)<br/>    prefix_list_id               = optional(string)<br/>    referenced_security_group_id = optional(string)<br/>    tags                         = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| security\_group\_tags | A map of additional tags to add to the security group created | `map(string)` | `{}` | no |
| security\_group\_use\_name\_prefix | Determines whether the security group name (`security_group_name`) is used as a prefix | `bool` | `true` | no |
| skip\_final\_snapshot | Determines whether a final snapshot of the cluster is created before Redshift deletes the cluster. If true, a final cluster snapshot is not created. If false , a final cluster snapshot is created before the cluster is deleted | `bool` | `false` | no |
| snapshot\_arn | The ARN of the snapshot from which to create the new cluster. Conflicts with `snapshot_identifier` | `string` | `null` | no |
| snapshot\_cluster\_identifier | The name of the cluster the source snapshot was created from | `string` | `null` | no |
| snapshot\_copy | Configuration of automatic copy of snapshots from one region to another | `any` | `{}` | no |
| snapshot\_identifier | The name of the snapshot from which to create the new cluster | `string` | `null` | no |
| snapshot\_schedule\_definitions | The definition of the snapshot schedule. The definition is made up of schedule expressions, for example `cron(30 12 *)` or `rate(12 hours)` | `list(string)` | `[]` | no |
| snapshot\_schedule\_description | The description of the snapshot schedule | `string` | `null` | no |
| snapshot\_schedule\_force\_destroy | Whether to destroy all associated clusters with this snapshot schedule on deletion. Must be enabled and applied before attempting deletion | `bool` | `null` | no |
| snapshot\_schedule\_identifier | The snapshot schedule identifier | `string` | `null` | no |
| subnet\_group\_description | The description of the Redshift Subnet group. Defaults to `Managed by Terraform` | `string` | `null` | no |
| subnet\_group\_name | The name of the Redshift subnet group, existing or to be created | `string` | `null` | no |
| subnet\_group\_tags | Additional tags to add to the subnet group | `map(string)` | `{}` | no |
| subnet\_ids | An array of VPC subnet IDs to use in the subnet group | `list(string)` | `[]` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| usage\_limits | Map of usage limit definitions to create | `any` | `{}` | no |
| use\_master\_password\_wo | Whether to use the write-only `master_password_wo` attribute instead of `master_password`. When true, the password is never stored in Terraform state. Requires OpenTofu >= 1.11.0 | `bool` | `false` | no |
| use\_snapshot\_identifier\_prefix | Determines whether the identifier (`snapshot_schedule_identifier`) is used as a prefix | `bool` | `true` | no |
| vpc\_id | Identifier of the VPC where the security group will be created | `string` | `null` | no |
| vpc\_security\_group\_ids | A list of Virtual Private Cloud (VPC) security groups to be associated with the cluster | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| authentication\_profiles | Map of authentication profiles created and their associated attributes |
| cluster\_arn | The Redshift cluster ARN |
| cluster\_automated\_snapshot\_retention\_period | The backup retention period |
| cluster\_availability\_zone | The availability zone of the Cluster |
| cluster\_database\_name | The name of the default database in the Cluster |
| cluster\_dns\_name | The DNS name of the cluster |
| cluster\_encrypted | Whether the data in the cluster is encrypted |
| cluster\_endpoint | The connection endpoint |
| cluster\_hostname | The hostname of the Redshift cluster |
| cluster\_id | The Redshift cluster ID |
| cluster\_identifier | The Redshift cluster identifier |
| cluster\_namespace\_arn | The namespace Amazon Resource Name (ARN) of the cluster |
| cluster\_node\_type | The type of nodes in the cluster |
| cluster\_nodes | The nodes in the cluster. Each node is a map of the following attributes: `node_role`, `private_ip_address`, and `public_ip_address` |
| cluster\_parameter\_group\_name | The name of the parameter group to be associated with this cluster |
| cluster\_port | The port the cluster responds on |
| cluster\_preferred\_maintenance\_window | The backup window |
| cluster\_public\_key | The public key for the cluster |
| cluster\_revision\_number | The specific revision number of the database in the cluster |
| cluster\_secretsmanager\_secret\_rotation\_enabled | Specifies whether automatic rotation is enabled for the secret |
| cluster\_subnet\_group\_name | The name of a cluster subnet group to be associated with this cluster |
| cluster\_type | The Redshift cluster type |
| cluster\_version | The version of Redshift engine software |
| cluster\_vpc\_security\_group\_ids | The VPC security group ids associated with the cluster |
| endpoint\_access\_address | The DNS address of the endpoint |
| endpoint\_access\_id | The Redshift-managed VPC endpoint name |
| endpoint\_access\_port | The port number on which the cluster accepts incoming connections |
| endpoint\_access\_vpc\_endpoint | The connection endpoint for connecting to an Amazon Redshift cluster through the proxy. See details below |
| master\_password\_secret\_arn | ARN of managed master password secret |
| parameter\_group\_arn | Amazon Resource Name (ARN) of the parameter group created |
| parameter\_group\_id | The name of the Redshift parameter group created |
| scheduled\_action\_iam\_role\_arn | Scheduled actions IAM role ARN |
| scheduled\_action\_iam\_role\_name | Scheduled actions IAM role name |
| scheduled\_action\_iam\_role\_unique\_id | Stable and unique string identifying the scheduled action IAM role |
| scheduled\_actions | A map of maps containing scheduled action details |
| snapshot\_schedule\_arn | Amazon Resource Name (ARN) of the Redshift Snapshot Schedule |
| subnet\_group\_arn | Amazon Resource Name (ARN) of the Redshift subnet group created |
| subnet\_group\_id | The ID of Redshift Subnet group created |
| usage\_limits | Map of usage limits created and their associated attributes |
<!-- END_TF_DOCS -->

</details>
