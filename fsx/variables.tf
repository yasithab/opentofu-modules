variable "enabled" {
  description = "Determines whether resources will be created (affects all resources)"
  type        = bool
  default     = true
}

variable "region" {
  description = "AWS region. If null, uses the provider's region."
  type        = string
  default     = null
}

variable "name" {
  description = "Name prefix used for FSx file system and related resources"
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Common
################################################################################

variable "file_system_type" {
  description = "Type of FSx file system to create. One of: `LUSTRE`, `ONTAP`, `OPENZFS`, `WINDOWS`"
  type        = string
  default     = "LUSTRE"
}

variable "subnet_ids" {
  description = "List of subnet IDs for the file system. Lustre/OpenZFS/Windows require 1, ONTAP requires 2 for multi-AZ."
  type        = list(string)
  default     = []
}

variable "storage_capacity" {
  description = "Storage capacity in GiB"
  type        = number
}

variable "storage_type" {
  description = "Storage type. `SSD` or `HDD` (Lustre/Windows only)"
  type        = string
  default     = "SSD"
}

variable "throughput_capacity" {
  description = "Throughput capacity in MBps. Required for ONTAP, OpenZFS, and Windows."
  type        = number
  default     = null
}

variable "kms_key_id" {
  description = "ARN of the KMS key to encrypt the file system at rest. If null, AWS-managed key is used."
  type        = string
  default     = null
}

variable "security_group_ids" {
  description = "List of existing security group IDs to attach to the file system"
  type        = list(string)
  default     = []
}

################################################################################
# Security Group
################################################################################

variable "create_security_group" {
  description = "Whether to create a security group for the file system"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID for the security group. Required if `create_security_group` is true."
  type        = string
  default     = null
}

variable "security_group_name" {
  description = "Name of the security group. Defaults to `var.name`."
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "Description for the security group"
  type        = string
  default     = "Security group for FSx file system"
}

variable "security_group_ingress_rules" {
  description = "Map of ingress rules for the security group"
  type = map(object({
    description              = optional(string)
    from_port                = number
    to_port                  = number
    protocol                 = string
    cidr_blocks              = optional(list(string), [])
    ipv6_cidr_blocks         = optional(list(string), [])
    source_security_group_id = optional(string)
    self                     = optional(bool, false)
  }))
  default = {}
}

variable "security_group_egress_rules" {
  description = "Map of egress rules for the security group"
  type = map(object({
    description      = optional(string)
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = optional(list(string), [])
    ipv6_cidr_blocks = optional(list(string), [])
  }))
  default = {
    all = {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

################################################################################
# Backup
################################################################################

variable "automatic_backup_retention_days" {
  description = "Number of days to retain automatic backups (0 to disable)"
  type        = number
  default     = 7
}

variable "daily_automatic_backup_start_time" {
  description = "Daily time to start automatic backups in UTC (HH:MM format)"
  type        = string
  default     = null
}

variable "weekly_maintenance_start_time" {
  description = "Weekly time to start maintenance in UTC (d:HH:MM format)"
  type        = string
  default     = null
}

################################################################################
# Lustre
################################################################################

variable "lustre_deployment_type" {
  description = "Lustre deployment type: `SCRATCH_1`, `SCRATCH_2`, `PERSISTENT_1`, or `PERSISTENT_2`"
  type        = string
  default     = "SCRATCH_2"
}

variable "lustre_per_unit_storage_throughput" {
  description = "Per-unit storage throughput in MBps for PERSISTENT deployments"
  type        = number
  default     = null
}

variable "lustre_data_compression_type" {
  description = "Data compression type for Lustre. `NONE` or `LZ4`"
  type        = string
  default     = "NONE"
}

variable "lustre_import_path" {
  description = "S3 import path for Lustre (e.g., s3://bucket/prefix)"
  type        = string
  default     = null
}

variable "lustre_export_path" {
  description = "S3 export path for Lustre (e.g., s3://bucket/prefix)"
  type        = string
  default     = null
}

variable "lustre_imported_file_chunk_size" {
  description = "Chunk size in MiB for files imported from S3"
  type        = number
  default     = null
}

variable "lustre_auto_import_policy" {
  description = "Auto-import policy for S3. `NONE`, `NEW`, `NEW_CHANGED`, or `NEW_CHANGED_DELETED`"
  type        = string
  default     = null
}

variable "lustre_drive_cache_type" {
  description = "Type of drive cache for HDD storage. `NONE` or `READ`"
  type        = string
  default     = null
}

variable "lustre_log_configuration" {
  description = "Lustre logging configuration"
  type = object({
    destination = optional(string)
    level       = optional(string, "WARN_ERROR")
  })
  default = null
}

################################################################################
# Data Repository Association (Lustre)
################################################################################

variable "data_repository_associations" {
  description = "Map of Lustre data repository associations to S3"
  type = map(object({
    data_repository_path             = string
    file_system_path                 = string
    batch_import_meta_data_on_create = optional(bool, false)
    imported_file_chunk_size         = optional(number)
    delete_data_in_filesystem        = optional(bool, false)
    s3_auto_export_policy            = optional(list(string))
    s3_auto_import_policy            = optional(list(string))
  }))
  default = {}
}

################################################################################
# ONTAP
################################################################################

variable "ontap_deployment_type" {
  description = "ONTAP deployment type: `SINGLE_AZ_1`, `SINGLE_AZ_2`, `MULTI_AZ_1`, or `MULTI_AZ_2`"
  type        = string
  default     = "SINGLE_AZ_1"
}

variable "ontap_preferred_subnet_id" {
  description = "Preferred subnet ID for ONTAP multi-AZ"
  type        = string
  default     = null
}

variable "ontap_endpoint_ip_address_range" {
  description = "IP address range for ONTAP endpoints (CIDR format)"
  type        = string
  default     = null
}

variable "ontap_route_table_ids" {
  description = "Route table IDs for ONTAP multi-AZ"
  type        = list(string)
  default     = []
}

variable "ontap_disk_iops_configuration" {
  description = "ONTAP disk IOPS configuration"
  type = object({
    iops = optional(number)
    mode = optional(string, "AUTOMATIC")
  })
  default = null
}

variable "ontap_ha_pairs" {
  description = "Number of HA pairs for ONTAP"
  type        = number
  default     = null
}

variable "ontap_svm" {
  description = "ONTAP Storage Virtual Machine (SVM) configuration"
  type = object({
    name                       = string
    root_volume_security_style = optional(string, "UNIX")
    svm_admin_password         = optional(string)
    active_directory = optional(object({
      dns_ips                                = list(string)
      domain_name                            = string
      file_system_administrators_group       = optional(string)
      organizational_unit_distinguished_name = optional(string)
      password                               = string
      username                               = string
    }))
  })
  default = null
}

variable "ontap_volumes" {
  description = "Map of ONTAP volumes to create"
  type = map(object({
    name                       = string
    junction_path              = optional(string)
    size_in_megabytes          = number
    storage_efficiency_enabled = optional(bool, true)
    security_style             = optional(string, "UNIX")
    ontap_volume_type          = optional(string, "RW")
    copy_tags_to_backups       = optional(bool, true)
    snapshot_policy            = optional(string)
    tiering_policy = optional(object({
      name           = string
      cooling_period = optional(number)
    }))
  }))
  default = {}
}

################################################################################
# OpenZFS
################################################################################

variable "openzfs_deployment_type" {
  description = "OpenZFS deployment type: `SINGLE_AZ_1`, `SINGLE_AZ_2`, or `MULTI_AZ_1`"
  type        = string
  default     = "SINGLE_AZ_1"
}

variable "openzfs_disk_iops_configuration" {
  description = "OpenZFS disk IOPS configuration"
  type = object({
    iops = optional(number)
    mode = optional(string, "AUTOMATIC")
  })
  default = null
}

variable "openzfs_root_volume_configuration" {
  description = "OpenZFS root volume configuration"
  type = object({
    copy_tags_to_snapshots = optional(bool, true)
    data_compression_type  = optional(string, "ZSTD")
    read_only              = optional(bool, false)
    record_size_kib        = optional(number, 128)
    nfs_exports = optional(object({
      client_configurations = list(object({
        clients = string
        options = list(string)
      }))
    }))
    user_and_group_quotas = optional(list(object({
      id                         = number
      storage_capacity_quota_gib = number
      type                       = string
    })), [])
  })
  default = null
}

variable "openzfs_volumes" {
  description = "Map of OpenZFS volumes to create"
  type = map(object({
    name                             = string
    parent_volume_id                 = optional(string)
    copy_tags_to_snapshots           = optional(bool, true)
    data_compression_type            = optional(string, "ZSTD")
    read_only                        = optional(bool, false)
    record_size_kib                  = optional(number, 128)
    storage_capacity_quota_gib       = optional(number)
    storage_capacity_reservation_gib = optional(number)
    nfs_exports = optional(object({
      client_configurations = list(object({
        clients = string
        options = list(string)
      }))
    }))
    user_and_group_quotas = optional(list(object({
      id                         = number
      storage_capacity_quota_gib = number
      type                       = string
    })), [])
    origin_snapshot = optional(object({
      copy_strategy = string
      snapshot_arn  = string
    }))
  }))
  default = {}
}

################################################################################
# Windows
################################################################################

variable "windows_deployment_type" {
  description = "Windows deployment type: `SINGLE_AZ_1`, `SINGLE_AZ_2`, or `MULTI_AZ_1`"
  type        = string
  default     = "SINGLE_AZ_1"
}

variable "windows_preferred_subnet_id" {
  description = "Preferred subnet ID for Windows multi-AZ"
  type        = string
  default     = null
}

variable "windows_active_directory_id" {
  description = "AWS Managed Microsoft AD directory ID for Windows File Server"
  type        = string
  default     = null
}

variable "windows_self_managed_active_directory" {
  description = "Self-managed Active Directory configuration for Windows"
  type = object({
    dns_ips                                = list(string)
    domain_name                            = string
    file_system_administrators_group       = optional(string, "Domain Admins")
    organizational_unit_distinguished_name = optional(string)
    password                               = string
    username                               = string
  })
  default = null
}

variable "windows_aliases" {
  description = "List of DNS alias names to associate with the Windows file system"
  type        = list(string)
  default     = []
}

variable "windows_audit_log_configuration" {
  description = "Windows audit log configuration"
  type = object({
    audit_log_destination             = optional(string)
    file_access_audit_log_level       = optional(string, "SUCCESS_AND_FAILURE")
    file_share_access_audit_log_level = optional(string, "SUCCESS_AND_FAILURE")
  })
  default = null
}

variable "windows_disk_iops_configuration" {
  description = "Windows disk IOPS configuration"
  type = object({
    iops = optional(number)
    mode = optional(string, "AUTOMATIC")
  })
  default = null
}

variable "windows_copy_tags_to_backups" {
  description = "Whether to copy tags to backups for Windows file system"
  type        = bool
  default     = true
}
