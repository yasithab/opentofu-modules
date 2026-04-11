# Amazon FSx

OpenTofu module for provisioning and managing Amazon FSx file systems with support for Lustre, NetApp ONTAP, OpenZFS, and Windows File Server.

## Features

- **FSx for Lustre** - High-performance scratch and persistent file systems with S3 data repository integration
- **FSx for NetApp ONTAP** - Multi-protocol file storage with Storage Virtual Machines and volumes
- **FSx for OpenZFS** - Fully managed ZFS file system with snapshots, compression, and NFS exports
- **FSx for Windows File Server** - Fully managed Windows-native file storage with Active Directory integration
- **Security Group Management** - Optional creation of a dedicated security group with configurable ingress and egress rules
- **KMS Encryption** - Server-side encryption at rest using AWS KMS (customer-managed or AWS-managed keys)
- **Backup Configuration** - Automatic daily backups with configurable retention and maintenance windows
- **Data Repository Associations** - Lustre-to-S3 bidirectional data synchronisation with auto-import and auto-export policies

## Usage

```hcl
module "fsx" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//fsx?depth=1&ref=master"

  name             = "my-lustre-fs"
  file_system_type = "LUSTRE"
  storage_capacity = 1200
  subnet_ids       = ["subnet-abc123"]
  vpc_id           = "vpc-abc123"

  tags = {
    Environment = "production"
  }
}
```

## Examples

## Lustre Scratch Filesystem

A high-performance scratch file system for temporary workloads such as batch processing or HPC jobs.

```hcl
module "fsx_lustre_scratch" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//fsx?depth=1&ref=master"

  name             = "hpc-scratch"
  file_system_type = "LUSTRE"
  storage_capacity = 1200
  subnet_ids       = ["subnet-abc123"]
  vpc_id           = "vpc-abc123"

  lustre_deployment_type    = "SCRATCH_2"
  lustre_data_compression_type = "LZ4"

  automatic_backup_retention_days = 0

  security_group_ingress_rules = {
    lustre = {
      description              = "Lustre traffic from compute nodes"
      from_port                = 988
      to_port                  = 988
      protocol                 = "tcp"
      source_security_group_id = "sg-compute123"
    }
  }

  tags = {
    Environment = "production"
    Team        = "hpc"
  }
}
```

## Lustre Persistent with S3 Data Repository

A persistent Lustre file system linked to an S3 bucket for automated data import and export.

```hcl
module "fsx_lustre_persistent" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//fsx?depth=1&ref=master"

  name             = "ml-training-data"
  file_system_type = "LUSTRE"
  storage_capacity = 2400
  subnet_ids       = ["subnet-abc123"]
  vpc_id           = "vpc-abc123"

  lustre_deployment_type            = "PERSISTENT_2"
  lustre_per_unit_storage_throughput = 250
  lustre_data_compression_type       = "LZ4"

  kms_key_id = "arn:aws:kms:ap-southeast-1:123456789012:key/mrk-abc123"

  data_repository_associations = {
    training = {
      data_repository_path = "s3://ml-datasets-bucket/training"
      file_system_path     = "/training"
      s3_auto_import_policy = ["NEW", "CHANGED", "DELETED"]
      s3_auto_export_policy = ["NEW", "CHANGED", "DELETED"]
    }
    results = {
      data_repository_path = "s3://ml-datasets-bucket/results"
      file_system_path     = "/results"
      s3_auto_export_policy = ["NEW", "CHANGED"]
    }
  }

  security_group_ingress_rules = {
    lustre = {
      description = "Lustre traffic from VPC"
      from_port   = 988
      to_port     = 988
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  }

  tags = {
    Environment = "production"
    Team        = "ml-platform"
  }
}
```

## ONTAP Multi-Protocol

An ONTAP file system with an SVM and volumes supporting both NFS and SMB access patterns.

```hcl
module "fsx_ontap" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//fsx?depth=1&ref=master"

  name             = "shared-storage"
  file_system_type = "ONTAP"
  storage_capacity = 1024
  storage_type     = "SSD"
  subnet_ids       = ["subnet-abc123", "subnet-def456"]
  vpc_id           = "vpc-abc123"

  throughput_capacity  = 256
  ontap_deployment_type = "MULTI_AZ_1"
  ontap_preferred_subnet_id = "subnet-abc123"
  ontap_route_table_ids     = ["rtb-abc123", "rtb-def456"]

  kms_key_id = "arn:aws:kms:ap-southeast-1:123456789012:key/mrk-abc123"

  ontap_svm = {
    name                       = "svm01"
    root_volume_security_style = "MIXED"
  }

  ontap_volumes = {
    data = {
      name              = "data_vol"
      junction_path     = "/data"
      size_in_megabytes = 204800
      security_style    = "MIXED"
      tiering_policy = {
        name           = "AUTO"
        cooling_period = 31
      }
    }
    logs = {
      name              = "logs_vol"
      junction_path     = "/logs"
      size_in_megabytes = 51200
      security_style    = "UNIX"
      tiering_policy = {
        name           = "ALL"
      }
    }
  }

  security_group_ingress_rules = {
    nfs = {
      description = "NFS from VPC"
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
    smb = {
      description = "SMB from VPC"
      from_port   = 445
      to_port     = 445
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  }

  tags = {
    Environment = "production"
    Team        = "storage"
  }
}
```

## OpenZFS with Snapshots

An OpenZFS file system with ZSTD compression, NFS exports, and child volumes.

```hcl
module "fsx_openzfs" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//fsx?depth=1&ref=master"

  name             = "app-storage"
  file_system_type = "OPENZFS"
  storage_capacity = 512
  subnet_ids       = ["subnet-abc123"]
  vpc_id           = "vpc-abc123"

  throughput_capacity   = 160
  openzfs_deployment_type = "SINGLE_AZ_2"

  kms_key_id = "arn:aws:kms:ap-southeast-1:123456789012:key/mrk-abc123"

  openzfs_root_volume_configuration = {
    data_compression_type  = "ZSTD"
    copy_tags_to_snapshots = true
    record_size_kib        = 128
    nfs_exports = {
      client_configurations = [
        {
          clients = "10.0.0.0/16"
          options = ["rw", "crossmnt", "no_root_squash"]
        }
      ]
    }
  }

  openzfs_volumes = {
    databases = {
      name                           = "databases"
      data_compression_type          = "ZSTD"
      record_size_kib                = 16
      storage_capacity_quota_gib     = 200
      storage_capacity_reservation_gib = 100
      nfs_exports = {
        client_configurations = [
          {
            clients = "10.0.0.0/16"
            options = ["rw", "no_root_squash"]
          }
        ]
      }
    }
    media = {
      name                       = "media"
      data_compression_type      = "ZSTD"
      record_size_kib            = 1024
      storage_capacity_quota_gib = 300
      nfs_exports = {
        client_configurations = [
          {
            clients = "10.0.0.0/16"
            options = ["rw", "crossmnt"]
          }
        ]
      }
    }
  }

  security_group_ingress_rules = {
    nfs = {
      description = "NFS from VPC"
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Windows File Server with AD Integration

A Windows File Server file system joined to an AWS Managed Microsoft AD with audit logging.

```hcl
module "fsx_windows" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//fsx?depth=1&ref=master"

  name             = "corp-shares"
  file_system_type = "WINDOWS"
  storage_capacity = 500
  storage_type     = "SSD"
  subnet_ids       = ["subnet-abc123", "subnet-def456"]
  vpc_id           = "vpc-abc123"

  throughput_capacity       = 64
  windows_deployment_type   = "MULTI_AZ_1"
  windows_preferred_subnet_id = "subnet-abc123"
  windows_active_directory_id = "d-1234567890"
  windows_aliases           = ["shares.corp.example.com"]
  windows_copy_tags_to_backups = true

  kms_key_id = "arn:aws:kms:ap-southeast-1:123456789012:key/mrk-abc123"

  windows_audit_log_configuration = {
    audit_log_destination             = "arn:aws:logs:ap-southeast-1:123456789012:log-group:/aws/fsx/windows"
    file_access_audit_log_level       = "SUCCESS_AND_FAILURE"
    file_share_access_audit_log_level = "SUCCESS_AND_FAILURE"
  }

  automatic_backup_retention_days   = 30
  daily_automatic_backup_start_time = "02:00"
  weekly_maintenance_start_time     = "7:03:00"

  security_group_ingress_rules = {
    smb = {
      description = "SMB from VPC"
      from_port   = 445
      to_port     = 445
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
    dns_tcp = {
      description = "DNS TCP from VPC"
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
    dns_udp = {
      description = "DNS UDP from VPC"
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  }

  tags = {
    Environment = "production"
    Team        = "infrastructure"
  }
}
```
