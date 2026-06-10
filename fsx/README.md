# Amazon FSx

OpenTofu module for provisioning and managing Amazon FSx file systems with support for Lustre, NetApp ONTAP, OpenZFS, and Windows File Server.

## Features

- **FSx for Lustre** - High-performance scratch and persistent file systems with S3 data repository integration
- **FSx for NetApp ONTAP** - Multi-protocol file storage with multiple Storage Virtual Machines (`ontap_svms`) and volumes per file system
- **FSx for OpenZFS** - Fully managed ZFS file system with snapshots, compression, and NFS exports
- **FSx for Windows File Server** - Fully managed Windows-native file storage with Active Directory integration
- **Security Group Management** - Optional creation of a dedicated security group with configurable ingress and egress rules
- **KMS Encryption** - Server-side encryption at rest using AWS KMS (customer-managed or AWS-managed keys)
- **Backup Configuration** - Automatic daily backups with configurable retention and maintenance windows
- **Data Repository Associations** - Lustre-to-S3 bidirectional data synchronisation with auto-import and auto-export policies
- **OpenZFS Snapshots** - Optional point-in-time snapshots of the root volume or any module-managed OpenZFS volume (`openzfs_snapshots`)

ONTAP volumes reference their parent SVM via `svm_key`, which must match a key of the `ontap_svms` map.

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
| automatic\_backup\_retention\_days | Number of days to retain automatic backups (0 to disable) | `number` | `7` | no |
| create\_security\_group | Whether to create a security group for the file system | `bool` | `true` | no |
| daily\_automatic\_backup\_start\_time | Daily time to start automatic backups in UTC (HH:MM format) | `string` | `null` | no |
| data\_repository\_associations | Map of Lustre data repository associations to S3 | <pre>map(object({<br/>    data_repository_path             = string<br/>    file_system_path                 = string<br/>    batch_import_meta_data_on_create = optional(bool, false)<br/>    imported_file_chunk_size         = optional(number)<br/>    delete_data_in_filesystem        = optional(bool, false)<br/>    s3_auto_export_policy            = optional(list(string))<br/>    s3_auto_import_policy            = optional(list(string))<br/>  }))</pre> | `{}` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| file\_system\_type | Type of FSx file system to create. One of: `LUSTRE`, `ONTAP`, `OPENZFS`, `WINDOWS` | `string` | `"LUSTRE"` | no |
| kms\_key\_id | ARN of the KMS key to encrypt the file system at rest. If null, AWS-managed key is used. | `string` | `null` | no |
| lustre\_auto\_import\_policy | Auto-import policy for S3. `NONE`, `NEW`, `NEW_CHANGED`, or `NEW_CHANGED_DELETED` | `string` | `null` | no |
| lustre\_data\_compression\_type | Data compression type for Lustre. `NONE` or `LZ4` | `string` | `"NONE"` | no |
| lustre\_deployment\_type | Lustre deployment type: `SCRATCH_1`, `SCRATCH_2`, `PERSISTENT_1`, or `PERSISTENT_2` | `string` | `"SCRATCH_2"` | no |
| lustre\_drive\_cache\_type | Type of drive cache for HDD storage. `NONE` or `READ` | `string` | `null` | no |
| lustre\_export\_path | S3 export path for Lustre (e.g., s3://bucket/prefix) | `string` | `null` | no |
| lustre\_import\_path | S3 import path for Lustre (e.g., s3://bucket/prefix) | `string` | `null` | no |
| lustre\_imported\_file\_chunk\_size | Chunk size in MiB for files imported from S3 | `number` | `null` | no |
| lustre\_log\_configuration | Lustre logging configuration | <pre>object({<br/>    destination = optional(string)<br/>    level       = optional(string, "WARN_ERROR")<br/>  })</pre> | `null` | no |
| lustre\_per\_unit\_storage\_throughput | Per-unit storage throughput in MBps for PERSISTENT deployments | `number` | `null` | no |
| name | Name prefix used for FSx file system and related resources | `string` | n/a | yes |
| ontap\_deployment\_type | ONTAP deployment type: `SINGLE_AZ_1`, `SINGLE_AZ_2`, `MULTI_AZ_1`, or `MULTI_AZ_2` | `string` | `"SINGLE_AZ_1"` | no |
| ontap\_disk\_iops\_configuration | ONTAP disk IOPS configuration | <pre>object({<br/>    iops = optional(number)<br/>    mode = optional(string, "AUTOMATIC")<br/>  })</pre> | `null` | no |
| ontap\_endpoint\_ip\_address\_range | IP address range for ONTAP endpoints (CIDR format) | `string` | `null` | no |
| ontap\_ha\_pairs | Number of HA pairs for ONTAP | `number` | `null` | no |
| ontap\_preferred\_subnet\_id | Preferred subnet ID for ONTAP multi-AZ | `string` | `null` | no |
| ontap\_route\_table\_ids | Route table IDs for ONTAP multi-AZ | `list(string)` | `[]` | no |
| ontap\_svms | Map of ONTAP Storage Virtual Machines (SVMs) to create. The map key is used as the SVM name when `name` is not set, and is referenced by `ontap_volumes` via `svm_key`. Note: svm\_admin\_password and active\_directory password will be stored in state as the provider does not support write\_only for these fields | <pre>map(object({<br/>    name                       = optional(string)<br/>    root_volume_security_style = optional(string, "UNIX")<br/>    svm_admin_password         = optional(string)<br/>    active_directory = optional(object({<br/>      netbios_name                           = optional(string)<br/>      dns_ips                                = list(string)<br/>      domain_name                            = string<br/>      file_system_administrators_group       = optional(string)<br/>      organizational_unit_distinguished_name = optional(string)<br/>      password                               = string<br/>      username                               = string<br/>    }))<br/>  }))</pre> | `{}` | no |
| ontap\_volumes | Map of ONTAP volumes to create. Each volume must reference an SVM via `svm_key` (a key of `ontap_svms`) | <pre>map(object({<br/>    name                       = string<br/>    svm_key                    = string<br/>    junction_path              = optional(string)<br/>    size_in_megabytes          = number<br/>    storage_efficiency_enabled = optional(bool, true)<br/>    security_style             = optional(string, "UNIX")<br/>    ontap_volume_type          = optional(string, "RW")<br/>    copy_tags_to_backups       = optional(bool, true)<br/>    snapshot_policy            = optional(string)<br/>    tiering_policy = optional(object({<br/>      name           = string<br/>      cooling_period = optional(number)<br/>    }))<br/>  }))</pre> | `{}` | no |
| openzfs\_deployment\_type | OpenZFS deployment type: `SINGLE_AZ_1`, `SINGLE_AZ_2`, or `MULTI_AZ_1` | `string` | `"SINGLE_AZ_1"` | no |
| openzfs\_disk\_iops\_configuration | OpenZFS disk IOPS configuration | <pre>object({<br/>    iops = optional(number)<br/>    mode = optional(string, "AUTOMATIC")<br/>  })</pre> | `null` | no |
| openzfs\_root\_volume\_configuration | OpenZFS root volume configuration | <pre>object({<br/>    copy_tags_to_snapshots = optional(bool, true)<br/>    data_compression_type  = optional(string, "ZSTD")<br/>    read_only              = optional(bool, false)<br/>    record_size_kib        = optional(number, 128)<br/>    nfs_exports = optional(object({<br/>      client_configurations = list(object({<br/>        clients = string<br/>        options = list(string)<br/>      }))<br/>    }))<br/>    user_and_group_quotas = optional(list(object({<br/>      id                         = number<br/>      storage_capacity_quota_gib = number<br/>      type                       = string<br/>    })), [])<br/>  })</pre> | `null` | no |
| openzfs\_snapshots | Map of OpenZFS snapshots to create. `volume_key` references a key of `openzfs_volumes`; when omitted the snapshot targets the file system root volume. `name` defaults to `<name>-<map key>` | <pre>map(object({<br/>    name       = optional(string)<br/>    volume_key = optional(string)<br/>  }))</pre> | `{}` | no |
| openzfs\_volumes | Map of OpenZFS volumes to create | <pre>map(object({<br/>    name                             = string<br/>    parent_volume_id                 = optional(string)<br/>    copy_tags_to_snapshots           = optional(bool, true)<br/>    data_compression_type            = optional(string, "ZSTD")<br/>    read_only                        = optional(bool, false)<br/>    record_size_kib                  = optional(number, 128)<br/>    storage_capacity_quota_gib       = optional(number)<br/>    storage_capacity_reservation_gib = optional(number)<br/>    nfs_exports = optional(object({<br/>      client_configurations = list(object({<br/>        clients = string<br/>        options = list(string)<br/>      }))<br/>    }))<br/>    user_and_group_quotas = optional(list(object({<br/>      id                         = number<br/>      storage_capacity_quota_gib = number<br/>      type                       = string<br/>    })), [])<br/>    origin_snapshot = optional(object({<br/>      copy_strategy = string<br/>      snapshot_arn  = string<br/>    }))<br/>  }))</pre> | `{}` | no |
| security\_group\_description | Description for the security group | `string` | `"Security group for FSx file system"` | no |
| security\_group\_egress\_rules | Map of egress rules for the security group | <pre>map(object({<br/>    description      = optional(string)<br/>    from_port        = number<br/>    to_port          = number<br/>    protocol         = string<br/>    cidr_blocks      = optional(list(string), [])<br/>    ipv6_cidr_blocks = optional(list(string), [])<br/>  }))</pre> | <pre>{<br/>  "all": {<br/>    "cidr_blocks": [<br/>      "0.0.0.0/0"<br/>    ],<br/>    "description": "Allow all outbound traffic",<br/>    "from_port": 0,<br/>    "protocol": "-1",<br/>    "to_port": 0<br/>  }<br/>}</pre> | no |
| security\_group\_ids | List of existing security group IDs to attach to the file system | `list(string)` | `[]` | no |
| security\_group\_ingress\_rules | Map of ingress rules for the security group | <pre>map(object({<br/>    description              = optional(string)<br/>    from_port                = number<br/>    to_port                  = number<br/>    protocol                 = string<br/>    cidr_blocks              = optional(list(string), [])<br/>    ipv6_cidr_blocks         = optional(list(string), [])<br/>    source_security_group_id = optional(string)<br/>    self                     = optional(bool, false)<br/>  }))</pre> | `{}` | no |
| security\_group\_name | Name of the security group. Defaults to `var.name`. | `string` | `null` | no |
| storage\_capacity | Storage capacity in GiB | `number` | n/a | yes |
| storage\_type | Storage type. `SSD` or `HDD` (Lustre/Windows only) | `string` | `"SSD"` | no |
| subnet\_ids | List of subnet IDs for the file system. Lustre/OpenZFS/Windows require 1, ONTAP requires 2 for multi-AZ. | `list(string)` | `[]` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| throughput\_capacity | Throughput capacity in MBps. Required for ONTAP, OpenZFS, and Windows. | `number` | `null` | no |
| vpc\_id | VPC ID for the security group. Required if `create_security_group` is true. | `string` | `null` | no |
| weekly\_maintenance\_start\_time | Weekly time to start maintenance in UTC (d:HH:MM format) | `string` | `null` | no |
| windows\_active\_directory\_id | AWS Managed Microsoft AD directory ID for Windows File Server | `string` | `null` | no |
| windows\_aliases | List of DNS alias names to associate with the Windows file system | `list(string)` | `[]` | no |
| windows\_audit\_log\_configuration | Windows audit log configuration | <pre>object({<br/>    audit_log_destination             = optional(string)<br/>    file_access_audit_log_level       = optional(string, "SUCCESS_AND_FAILURE")<br/>    file_share_access_audit_log_level = optional(string, "SUCCESS_AND_FAILURE")<br/>  })</pre> | `null` | no |
| windows\_copy\_tags\_to\_backups | Whether to copy tags to backups for Windows file system | `bool` | `true` | no |
| windows\_deployment\_type | Windows deployment type: `SINGLE_AZ_1`, `SINGLE_AZ_2`, or `MULTI_AZ_1` | `string` | `"SINGLE_AZ_1"` | no |
| windows\_disk\_iops\_configuration | Windows disk IOPS configuration | <pre>object({<br/>    iops = optional(number)<br/>    mode = optional(string, "AUTOMATIC")<br/>  })</pre> | `null` | no |
| windows\_preferred\_subnet\_id | Preferred subnet ID for Windows multi-AZ | `string` | `null` | no |
| windows\_self\_managed\_active\_directory | Self-managed Active Directory configuration for Windows. Note: password will be stored in state as the provider does not support write\_only for this field | <pre>object({<br/>    dns_ips                                = list(string)<br/>    domain_name                            = string<br/>    file_system_administrators_group       = optional(string, "Domain Admins")<br/>    organizational_unit_distinguished_name = optional(string)<br/>    password                               = string<br/>    username                               = string<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| lustre\_arn | ARN of the Lustre file system |
| lustre\_data\_repository\_associations | Map of data repository association attributes |
| lustre\_dns\_name | DNS name of the Lustre file system |
| lustre\_id | ID of the Lustre file system |
| lustre\_mount\_name | Mount name of the Lustre file system |
| lustre\_network\_interface\_ids | Network interface IDs of the Lustre file system |
| lustre\_owner\_id | AWS account ID that owns the Lustre file system |
| lustre\_vpc\_id | VPC ID of the Lustre file system |
| ontap\_arn | ARN of the ONTAP file system |
| ontap\_dns\_name | DNS name of the ONTAP file system |
| ontap\_endpoints | Endpoints of the ONTAP file system |
| ontap\_id | ID of the ONTAP file system |
| ontap\_network\_interface\_ids | Network interface IDs of the ONTAP file system |
| ontap\_owner\_id | AWS account ID that owns the ONTAP file system |
| ontap\_svms | Map of ONTAP Storage Virtual Machine attributes, keyed by `ontap_svms` map key |
| ontap\_volumes | Map of ONTAP volume attributes |
| ontap\_vpc\_id | VPC ID of the ONTAP file system |
| openzfs\_arn | ARN of the OpenZFS file system |
| openzfs\_dns\_name | DNS name of the OpenZFS file system |
| openzfs\_id | ID of the OpenZFS file system |
| openzfs\_network\_interface\_ids | Network interface IDs of the OpenZFS file system |
| openzfs\_owner\_id | AWS account ID that owns the OpenZFS file system |
| openzfs\_root\_volume\_id | Root volume ID of the OpenZFS file system |
| openzfs\_snapshots | Map of OpenZFS snapshot attributes, keyed by `openzfs_snapshots` map key |
| openzfs\_volumes | Map of OpenZFS volume attributes |
| openzfs\_vpc\_id | VPC ID of the OpenZFS file system |
| security\_group\_arn | ARN of the security group created for the file system |
| security\_group\_id | ID of the security group created for the file system |
| windows\_arn | ARN of the Windows file system |
| windows\_dns\_name | DNS name of the Windows file system |
| windows\_id | ID of the Windows file system |
| windows\_network\_interface\_ids | Network interface IDs of the Windows file system |
| windows\_owner\_id | AWS account ID that owns the Windows file system |
| windows\_preferred\_file\_server\_ip | IP address of the preferred Windows file server |
| windows\_remote\_administration\_endpoint | Remote administration endpoint for the Windows file system |
| windows\_vpc\_id | VPC ID of the Windows file system |
<!-- END_TF_DOCS -->

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

## ONTAP Multi-Protocol with Multiple SVMs

An ONTAP file system hosting multiple SVMs, each with its own volumes, supporting both NFS and SMB access patterns.

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

  ontap_svms = {
    apps = {
      name                       = "svm01"
      root_volume_security_style = "MIXED"
    }
    analytics = {
      # name defaults to the map key ("analytics")
      root_volume_security_style = "UNIX"
    }
  }

  ontap_volumes = {
    data = {
      name              = "data_vol"
      svm_key           = "apps"
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
      svm_key           = "analytics"
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

  openzfs_snapshots = {
    databases-baseline = {
      volume_key = "databases" # snapshot of the "databases" volume
    }
    root-baseline = {
      name = "app-storage-root" # volume_key omitted: snapshots the root volume
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
