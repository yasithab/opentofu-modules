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
      cidr_blocks = "10.0.0.0/16"
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
      cidr_blocks              = "10.0.0.0/16"
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
