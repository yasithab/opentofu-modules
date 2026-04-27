locals {
  enabled = var.enabled
  name    = var.name
  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  is_lustre  = local.enabled && var.file_system_type == "LUSTRE"
  is_ontap   = local.enabled && var.file_system_type == "ONTAP"
  is_openzfs = local.enabled && var.file_system_type == "OPENZFS"
  is_windows = local.enabled && var.file_system_type == "WINDOWS"

  create_security_group = local.enabled && var.create_security_group

  security_group_ids = compact(concat(
    var.security_group_ids,
    local.create_security_group ? [aws_security_group.this.id] : []
  ))
}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "this" {
  name        = coalesce(var.security_group_name, local.name)
  description = var.security_group_description
  vpc_id      = var.vpc_id

  tags = merge(local.tags, {
    Name = coalesce(var.security_group_name, local.name)
  })

  lifecycle {
    enabled = local.create_security_group
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = { for k, v in var.security_group_ingress_rules : k => v if local.create_security_group }

  security_group_id            = aws_security_group.this.id
  description                  = try(each.value.description, null)
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  ip_protocol                  = each.value.protocol
  cidr_ipv4                    = try(each.value.cidr_blocks[0], null)
  cidr_ipv6                    = try(each.value.ipv6_cidr_blocks[0], null)
  referenced_security_group_id = try(each.value.source_security_group_id, each.value.self ? aws_security_group.this.id : null, null)

  tags = local.tags
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = { for k, v in var.security_group_egress_rules : k => v if local.create_security_group }

  security_group_id = aws_security_group.this.id
  description       = try(each.value.description, null)
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.protocol
  cidr_ipv4         = try(each.value.cidr_blocks[0], null)
  cidr_ipv6         = try(each.value.ipv6_cidr_blocks[0], null)

  tags = local.tags
}

################################################################################
# FSx for Lustre
################################################################################

resource "aws_fsx_lustre_file_system" "this" {
  subnet_ids                        = var.subnet_ids
  storage_capacity                  = var.storage_capacity
  storage_type                      = var.storage_type
  security_group_ids                = local.security_group_ids
  kms_key_id                        = var.kms_key_id
  deployment_type                   = var.lustre_deployment_type
  per_unit_storage_throughput       = var.lustre_per_unit_storage_throughput
  data_compression_type             = var.lustre_data_compression_type
  import_path                       = var.lustre_import_path
  export_path                       = var.lustre_export_path
  imported_file_chunk_size          = var.lustre_imported_file_chunk_size
  auto_import_policy                = var.lustre_auto_import_policy
  drive_cache_type                  = var.lustre_drive_cache_type
  automatic_backup_retention_days   = var.automatic_backup_retention_days
  daily_automatic_backup_start_time = var.daily_automatic_backup_start_time
  weekly_maintenance_start_time     = var.weekly_maintenance_start_time

  dynamic "log_configuration" {
    for_each = var.lustre_log_configuration != null ? [var.lustre_log_configuration] : []

    content {
      destination = try(log_configuration.value.destination, null)
      level       = try(log_configuration.value.level, "WARN_ERROR")
    }
  }

  tags = merge(local.tags, {
    Name = local.name
  })

  lifecycle {
    enabled = local.is_lustre
  }
}

################################################################################
# Data Repository Association (Lustre)
################################################################################

resource "aws_fsx_data_repository_association" "this" {
  for_each = { for k, v in var.data_repository_associations : k => v if local.is_lustre }

  file_system_id                   = aws_fsx_lustre_file_system.this.id
  data_repository_path             = each.value.data_repository_path
  file_system_path                 = each.value.file_system_path
  batch_import_meta_data_on_create = try(each.value.batch_import_meta_data_on_create, false)
  imported_file_chunk_size         = try(each.value.imported_file_chunk_size, null)
  delete_data_in_filesystem        = try(each.value.delete_data_in_filesystem, false)

  dynamic "s3" {
    for_each = try(each.value.s3_auto_export_policy, null) != null || try(each.value.s3_auto_import_policy, null) != null ? [1] : []

    content {
      dynamic "auto_export_policy" {
        for_each = try(each.value.s3_auto_export_policy, null) != null ? [1] : []

        content {
          events = each.value.s3_auto_export_policy
        }
      }

      dynamic "auto_import_policy" {
        for_each = try(each.value.s3_auto_import_policy, null) != null ? [1] : []

        content {
          events = each.value.s3_auto_import_policy
        }
      }
    }
  }

  tags = local.tags
}

################################################################################
# FSx for NetApp ONTAP
################################################################################

resource "aws_fsx_ontap_file_system" "this" {
  subnet_ids                        = var.subnet_ids
  storage_capacity                  = var.storage_capacity
  storage_type                      = var.storage_type
  security_group_ids                = local.security_group_ids
  kms_key_id                        = var.kms_key_id
  deployment_type                   = var.ontap_deployment_type
  throughput_capacity               = var.throughput_capacity
  preferred_subnet_id               = var.ontap_preferred_subnet_id
  endpoint_ip_address_range         = var.ontap_endpoint_ip_address_range
  route_table_ids                   = var.ontap_route_table_ids
  ha_pairs                          = var.ontap_ha_pairs
  automatic_backup_retention_days   = var.automatic_backup_retention_days
  daily_automatic_backup_start_time = var.daily_automatic_backup_start_time
  weekly_maintenance_start_time     = var.weekly_maintenance_start_time

  dynamic "disk_iops_configuration" {
    for_each = var.ontap_disk_iops_configuration != null ? [var.ontap_disk_iops_configuration] : []

    content {
      iops = try(disk_iops_configuration.value.iops, null)
      mode = try(disk_iops_configuration.value.mode, "AUTOMATIC")
    }
  }

  tags = merge(local.tags, {
    Name = local.name
  })

  lifecycle {
    enabled = local.is_ontap
  }
}

################################################################################
# ONTAP Storage Virtual Machine
################################################################################

resource "aws_fsx_ontap_storage_virtual_machine" "this" {
  file_system_id             = aws_fsx_ontap_file_system.this.id
  name                       = try(var.ontap_svm.name, local.name)
  root_volume_security_style = try(var.ontap_svm.root_volume_security_style, "UNIX")
  svm_admin_password         = try(var.ontap_svm.svm_admin_password, null)

  dynamic "active_directory_configuration" {
    for_each = try(var.ontap_svm.active_directory, null) != null ? [var.ontap_svm.active_directory] : []

    content {
      netbios_name = try(active_directory_configuration.value.netbios_name, null)

      self_managed_active_directory_configuration {
        dns_ips                                = active_directory_configuration.value.dns_ips
        domain_name                            = active_directory_configuration.value.domain_name
        file_system_administrators_group       = try(active_directory_configuration.value.file_system_administrators_group, null)
        organizational_unit_distinguished_name = try(active_directory_configuration.value.organizational_unit_distinguished_name, null)
        password                               = active_directory_configuration.value.password
        username                               = active_directory_configuration.value.username
      }
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.is_ontap && nonsensitive(var.ontap_svm != null)
  }
}

################################################################################
# ONTAP Volumes
################################################################################

resource "aws_fsx_ontap_volume" "this" {
  for_each = { for k, v in var.ontap_volumes : k => v if local.is_ontap && nonsensitive(var.ontap_svm != null) }

  name                       = each.value.name
  junction_path              = try(each.value.junction_path, "/${each.value.name}")
  size_in_megabytes          = each.value.size_in_megabytes
  storage_efficiency_enabled = try(each.value.storage_efficiency_enabled, true)
  storage_virtual_machine_id = aws_fsx_ontap_storage_virtual_machine.this.id
  ontap_volume_type          = try(each.value.ontap_volume_type, "RW")
  security_style             = try(each.value.security_style, "UNIX")
  copy_tags_to_backups       = try(each.value.copy_tags_to_backups, true)
  snapshot_policy            = try(each.value.snapshot_policy, null)

  dynamic "tiering_policy" {
    for_each = try(each.value.tiering_policy, null) != null ? [each.value.tiering_policy] : []

    content {
      name           = tiering_policy.value.name
      cooling_period = try(tiering_policy.value.cooling_period, null)
    }
  }

  tags = local.tags
}

################################################################################
# FSx for OpenZFS
################################################################################

resource "aws_fsx_openzfs_file_system" "this" {
  subnet_ids                        = var.subnet_ids
  storage_capacity                  = var.storage_capacity
  storage_type                      = var.storage_type
  security_group_ids                = local.security_group_ids
  kms_key_id                        = var.kms_key_id
  deployment_type                   = var.openzfs_deployment_type
  throughput_capacity               = var.throughput_capacity
  automatic_backup_retention_days   = var.automatic_backup_retention_days
  daily_automatic_backup_start_time = var.daily_automatic_backup_start_time
  weekly_maintenance_start_time     = var.weekly_maintenance_start_time

  dynamic "disk_iops_configuration" {
    for_each = var.openzfs_disk_iops_configuration != null ? [var.openzfs_disk_iops_configuration] : []

    content {
      iops = try(disk_iops_configuration.value.iops, null)
      mode = try(disk_iops_configuration.value.mode, "AUTOMATIC")
    }
  }

  dynamic "root_volume_configuration" {
    for_each = var.openzfs_root_volume_configuration != null ? [var.openzfs_root_volume_configuration] : []

    content {
      copy_tags_to_snapshots = try(root_volume_configuration.value.copy_tags_to_snapshots, true)
      data_compression_type  = try(root_volume_configuration.value.data_compression_type, "ZSTD")
      read_only              = try(root_volume_configuration.value.read_only, false)
      record_size_kib        = try(root_volume_configuration.value.record_size_kib, 128)

      dynamic "nfs_exports" {
        for_each = try(root_volume_configuration.value.nfs_exports, null) != null ? [root_volume_configuration.value.nfs_exports] : []

        content {
          dynamic "client_configurations" {
            for_each = nfs_exports.value.client_configurations

            content {
              clients = client_configurations.value.clients
              options = client_configurations.value.options
            }
          }
        }
      }

      dynamic "user_and_group_quotas" {
        for_each = try(root_volume_configuration.value.user_and_group_quotas, [])

        content {
          id                         = user_and_group_quotas.value.id
          storage_capacity_quota_gib = user_and_group_quotas.value.storage_capacity_quota_gib
          type                       = user_and_group_quotas.value.type
        }
      }
    }
  }

  tags = merge(local.tags, {
    Name = local.name
  })

  lifecycle {
    enabled = local.is_openzfs
  }
}

################################################################################
# OpenZFS Volumes
################################################################################

resource "aws_fsx_openzfs_volume" "this" {
  for_each = { for k, v in var.openzfs_volumes : k => v if local.is_openzfs }

  name                             = each.value.name
  parent_volume_id                 = try(each.value.parent_volume_id, aws_fsx_openzfs_file_system.this.root_volume_id)
  copy_tags_to_snapshots           = try(each.value.copy_tags_to_snapshots, true)
  data_compression_type            = try(each.value.data_compression_type, "ZSTD")
  read_only                        = try(each.value.read_only, false)
  record_size_kib                  = try(each.value.record_size_kib, 128)
  storage_capacity_quota_gib       = try(each.value.storage_capacity_quota_gib, null)
  storage_capacity_reservation_gib = try(each.value.storage_capacity_reservation_gib, null)

  dynamic "nfs_exports" {
    for_each = try(each.value.nfs_exports, null) != null ? [each.value.nfs_exports] : []

    content {
      dynamic "client_configurations" {
        for_each = nfs_exports.value.client_configurations

        content {
          clients = client_configurations.value.clients
          options = client_configurations.value.options
        }
      }
    }
  }

  dynamic "user_and_group_quotas" {
    for_each = try(each.value.user_and_group_quotas, [])

    content {
      id                         = user_and_group_quotas.value.id
      storage_capacity_quota_gib = user_and_group_quotas.value.storage_capacity_quota_gib
      type                       = user_and_group_quotas.value.type
    }
  }

  dynamic "origin_snapshot" {
    for_each = try(each.value.origin_snapshot, null) != null ? [each.value.origin_snapshot] : []

    content {
      copy_strategy = origin_snapshot.value.copy_strategy
      snapshot_arn  = origin_snapshot.value.snapshot_arn
    }
  }

  tags = local.tags
}

################################################################################
# FSx for Windows File Server
################################################################################

resource "aws_fsx_windows_file_system" "this" {
  subnet_ids                        = var.subnet_ids
  storage_capacity                  = var.storage_capacity
  storage_type                      = var.storage_type
  security_group_ids                = local.security_group_ids
  kms_key_id                        = var.kms_key_id
  deployment_type                   = var.windows_deployment_type
  throughput_capacity               = var.throughput_capacity
  preferred_subnet_id               = var.windows_preferred_subnet_id
  active_directory_id               = var.windows_active_directory_id
  aliases                           = var.windows_aliases
  copy_tags_to_backups              = var.windows_copy_tags_to_backups
  automatic_backup_retention_days   = var.automatic_backup_retention_days
  daily_automatic_backup_start_time = var.daily_automatic_backup_start_time
  weekly_maintenance_start_time     = var.weekly_maintenance_start_time

  dynamic "self_managed_active_directory" {
    for_each = var.windows_self_managed_active_directory != null ? [var.windows_self_managed_active_directory] : []

    content {
      dns_ips                                = self_managed_active_directory.value.dns_ips
      domain_name                            = self_managed_active_directory.value.domain_name
      file_system_administrators_group       = try(self_managed_active_directory.value.file_system_administrators_group, "Domain Admins")
      organizational_unit_distinguished_name = try(self_managed_active_directory.value.organizational_unit_distinguished_name, null)
      password                               = self_managed_active_directory.value.password
      username                               = self_managed_active_directory.value.username
    }
  }

  dynamic "audit_log_configuration" {
    for_each = var.windows_audit_log_configuration != null ? [var.windows_audit_log_configuration] : []

    content {
      audit_log_destination             = try(audit_log_configuration.value.audit_log_destination, null)
      file_access_audit_log_level       = try(audit_log_configuration.value.file_access_audit_log_level, "SUCCESS_AND_FAILURE")
      file_share_access_audit_log_level = try(audit_log_configuration.value.file_share_access_audit_log_level, "SUCCESS_AND_FAILURE")
    }
  }

  dynamic "disk_iops_configuration" {
    for_each = var.windows_disk_iops_configuration != null ? [var.windows_disk_iops_configuration] : []

    content {
      iops = try(disk_iops_configuration.value.iops, null)
      mode = try(disk_iops_configuration.value.mode, "AUTOMATIC")
    }
  }

  tags = merge(local.tags, {
    Name = local.name
  })

  lifecycle {
    enabled = local.is_windows
  }
}
