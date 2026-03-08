# EFS Module - Examples

## Basic File System

A general-purpose EFS file system with encryption enabled, backup policy, and mount targets in two availability zones.

```hcl
module "efs" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//efs?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//efs?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//efs?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//efs?depth=1&ref=v2.0.0"

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
