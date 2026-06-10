# Amazon EFS

OpenTofu module for provisioning and managing Amazon Elastic File System (EFS) with support for mount targets, access points, security groups, backup policies, and cross-region replication.

## Features

- **Encryption** - Encrypted at rest by default with optional custom KMS key support
- **Mount Targets** - Configurable mount targets across multiple subnets with IPv4 and IPv6 address support
- **Access Points** - Create multiple access points with POSIX user mapping and root directory configuration for application-level isolation
- **Security Groups** - Optional managed security group with customizable ingress and egress rules (NFS port 2049 by default)
- **File System Policy** - Built-in secure transport enforcement (deny non-TLS connections) with support for custom IAM policy statements. `deny_nonsecure_transport` (defaults to true) blocks non-TLS API calls; `deny_nonsecure_transport_via_mount_target` (defaults to true) blocks non-TLS mount target connections
- **Lifecycle Management** - Configurable lifecycle policies for transitioning files to Infrequent Access (IA) and Archive storage classes
- **Backup Policy** - AWS Backup integration enabled by default with toggle control
- **Replication** - Cross-region or cross-account file system replication with configurable destination settings
- **Throughput Modes** - Support for bursting, elastic, and provisioned throughput modes
- **Deletion Protection** - Prevent-destroy lifecycle enabled by default to guard against accidental deletion

## Usage

```hcl
module "efs" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//efs?depth=1&ref=master"

  name = "my-filesystem"

  mount_targets = {
    "us-east-1a" = { subnet_id = "subnet-0123456789abcdef0" }
    "us-east-1b" = { subnet_id = "subnet-0123456789abcdef1" }
  }

  security_group_vpc_id = "vpc-0123456789abcdef0"
  security_group_rules = {
    vpc_ingress = {
      description = "NFS ingress from VPC"
      cidr_ipv4   = "10.0.0.0/16"
    }
  }

  tags = {
    Environment = "production"
  }
}
```

## Examples

## Basic File System

A general-purpose EFS file system with encryption enabled, backup policy, and mount targets in two availability zones.

```hcl
module "efs" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//efs?depth=1&ref=master"

  enabled = true
  name    = "myapp-shared-storage"

  mount_targets = {
    "ap-southeast-1a" = {
      subnet_id = "subnet-0abc123def456789a"
    }
    "ap-southeast-1b" = {
      subnet_id = "subnet-0def456789abc1230b"
    }
  }

  security_group_vpc_id = "vpc-0abc123def456789a"

  security_group_rules = {
    ingress_ecs = {
      description              = "NFS from ECS tasks"
      cidr_ipv4                = "10.0.0.0/16"
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## With KMS Encryption and Lifecycle Policies

A file system with a customer-managed KMS key, infrequent-access lifecycle tiering, and elastic throughput.

```hcl
module "efs_cms" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//efs?depth=1&ref=master"

  enabled = true
  name    = "cms-uploads"

  encrypted   = true
  kms_key_arn = "arn:aws:kms:ap-southeast-1:123456789012:key/mrk-abc123def456"

  throughput_mode = "elastic"

  lifecycle_policy = {
    transition_to_ia                    = "AFTER_30_DAYS"
    transition_to_archive               = "AFTER_90_DAYS"
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  mount_targets = {
    "ap-southeast-1a" = {
      subnet_id = "subnet-0abc123def456789a"
    }
    "ap-southeast-1b" = {
      subnet_id = "subnet-0def456789abc1230b"
    }
    "ap-southeast-1c" = {
      subnet_id = "subnet-0fed987654321abcd0c"
    }
  }

  security_group_vpc_id = "vpc-0abc123def456789a"

  tags = {
    Environment = "production"
    Team        = "content"
  }
}
```

## With Access Points

A file system with POSIX access points to allow ECS tasks with specific user identities to access isolated directory paths.

```hcl
module "efs_shared" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//efs?depth=1&ref=master"

  enabled = true
  name    = "shared-data"

  mount_targets = {
    "ap-southeast-1a" = {
      subnet_id = "subnet-0abc123def456789a"
    }
    "ap-southeast-1b" = {
      subnet_id = "subnet-0def456789abc1230b"
    }
  }

  security_group_vpc_id = "vpc-0abc123def456789a"

  access_points = {
    api = {
      name = "api-data"
      posix_user = {
        uid = 1001
        gid = 1001
      }
      root_directory = {
        path = "/api"
        creation_info = {
          owner_gid   = 1001
          owner_uid   = 1001
          permissions = "755"
        }
      }
      tags = { Service = "api" }
    }

    worker = {
      name = "worker-data"
      posix_user = {
        uid = 1002
        gid = 1002
      }
      root_directory = {
        path = "/worker"
        creation_info = {
          owner_gid   = 1002
          owner_uid   = 1002
          permissions = "755"
        }
      }
      tags = { Service = "worker" }
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## With Cross-Region Replication

A file system with replication to a disaster recovery region for durability.

```hcl
module "efs_primary" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//efs?depth=1&ref=master"

  enabled = true
  name    = "primary-data"

  encrypted   = true
  kms_key_arn = "arn:aws:kms:ap-southeast-1:123456789012:key/mrk-abc123def456"

  mount_targets = {
    "ap-southeast-1a" = {
      subnet_id = "subnet-0abc123def456789a"
    }
  }

  security_group_vpc_id = "vpc-0abc123def456789a"

  create_replication_configuration = true
  replication_configuration_destination = {
    region     = "ap-south-1"
    kms_key_id = "arn:aws:kms:ap-south-1:123456789012:key/mrk-def456abc789"
  }

  # Disable replication overwrite protection so this FS can act as a source
  replication_overwrite_protection = "DISABLED"

  tags = {
    Environment = "production"
    Team        = "platform"
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
| access\_points | A map of access point definitions to create | `any` | `{}` | no |
| attach\_policy | Determines whether a policy is attached to the file system | `bool` | `true` | no |
| availability\_zone\_name | The AWS Availability Zone in which to create the file system. Used to create a file system that uses One Zone storage classes | `string` | `null` | no |
| bypass\_policy\_lockout\_safety\_check | A flag to indicate whether to bypass the `aws_efs_file_system_policy` lockout safety check. Defaults to `false` | `bool` | `null` | no |
| create\_backup\_policy | Determines whether a backup policy is created | `bool` | `true` | no |
| create\_replication\_configuration | Determines whether a replication configuration is created | `bool` | `false` | no |
| create\_security\_group | Determines whether a security group is created | `bool` | `true` | no |
| creation\_token | A unique name (a maximum of 64 characters are allowed) used as reference when creating the Elastic File System to ensure idempotent file system creation. By default generated by Terraform | `string` | `null` | no |
| deny\_nonsecure\_transport | Determines whether `aws:SecureTransport` is required when connecting to elastic file system | `bool` | `true` | no |
| deny\_nonsecure\_transport\_via\_mount\_target | Determines whether to use the common policy option for denying nonsecure transport which allows all AWS principals when accessed via EFS mounted target | `bool` | `true` | no |
| enable\_backup\_policy | Determines whether a backup policy is `ENABLED` or `DISABLED` | `bool` | `true` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| encrypted | If `true`, the disk will be encrypted | `bool` | `true` | no |
| kms\_key\_arn | The ARN for the KMS encryption key. When specifying `kms_key_arn`, encrypted needs to be set to `true` | `string` | `null` | no |
| lifecycle\_policy | A file system [lifecycle policy](https://docs.aws.amazon.com/efs/latest/ug/API_LifecyclePolicy.html) object | `any` | `{}` | no |
| mount\_targets | A map of mount target definitions to create | `any` | `{}` | no |
| name | Name to use for resource naming and tagging. | `string` | `null` | no |
| override\_policy\_documents | List of IAM policy documents that are merged together into the exported document. In merging, statements with non-blank `sid`s will override statements with the same `sid` | `list(string)` | `[]` | no |
| performance\_mode | The file system performance mode. Can be either `generalPurpose` or `maxIO`. Default is `generalPurpose` | `string` | `null` | no |
| policy\_statements | A list of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage | `any` | `[]` | no |
| provisioned\_throughput\_in\_mibps | The throughput, measured in MiB/s, that you want to provision for the file system. Only applicable with `throughput_mode` set to `provisioned` | `number` | `null` | no |
| replication\_configuration\_destination | A destination configuration block | `any` | `{}` | no |
| replication\_overwrite\_protection | Whether to enable or disable the file system's replication overwrite protection. Valid values: ENABLED or DISABLED. When set to ENABLED, the file system cannot be used as a replication destination. | `string` | `null` | no |
| security\_group\_description | Security group description. Defaults to Managed by Terraform | `string` | `null` | no |
| security\_group\_name | Name to assign to the security group. If omitted, Terraform will assign a random, unique name | `string` | `null` | no |
| security\_group\_rules | Map of security group rule definitions to create | <pre>map(object({<br/>    type                         = optional(string, "ingress")<br/>    ip_protocol                  = optional(string, "tcp")<br/>    from_port                    = optional(number)<br/>    to_port                      = optional(number)<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    description                  = optional(string)<br/>    prefix_list_id               = optional(string)<br/>    referenced_security_group_id = optional(string)<br/>    tags                         = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| security\_group\_use\_name\_prefix | Determines whether to use a name prefix for the security group. If `true`, the `security_group_name` value will be used as a prefix | `bool` | `false` | no |
| security\_group\_vpc\_id | The VPC ID where the security group will be created | `string` | `null` | no |
| source\_policy\_documents | List of IAM policy documents that are merged together into the exported document. Statements must have unique `sid`s | `list(string)` | `[]` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| throughput\_mode | Throughput mode for the file system. Defaults to `bursting`. Valid values: `bursting`, `elastic`, and `provisioned`. When using `provisioned`, also set `provisioned_throughput_in_mibps` | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| access\_points | Map of access points created and their attributes |
| arn | Amazon Resource Name of the file system |
| dns\_name | The DNS name for the filesystem per [documented convention](http://docs.aws.amazon.com/efs/latest/ug/mounting-fs-mount-cmd-dns-name.html) |
| id | The ID that identifies the file system (e.g., `fs-ccfc0d65`) |
| mount\_targets | Map of mount targets created and their attributes |
| replication\_configuration\_destination\_file\_system\_id | The file system ID of the replica |
| security\_group\_arn | ARN of the security group |
| security\_group\_id | ID of the security group |
| size\_in\_bytes | The latest known metered size (in bytes) of data stored in the file system, the value is not the exact size that the file system was at any point in time |
<!-- END_TF_DOCS -->

</details>
