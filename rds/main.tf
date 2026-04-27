data "aws_partition" "current" {}

locals {
  enabled = var.enabled

  port = coalesce(var.port, (
    var.engine == "postgres" ? 5432 :
    can(regex("^oracle", var.engine)) ? 1521 :
    can(regex("^sqlserver", var.engine)) ? 1433 :
    3306 # mysql, mariadb
  ))

  internal_db_subnet_group_name = try(coalesce(var.db_subnet_group_name, var.name), "")
  db_subnet_group_name          = var.create_db_subnet_group ? try(aws_db_subnet_group.this.name, null) : local.internal_db_subnet_group_name

  security_group_name = try(coalesce(var.security_group_name, var.name), "")

  db_parameter_group_name = try(coalesce(var.db_parameter_group_name, var.name), null)
  option_group_name       = try(coalesce(var.db_option_group_name, var.name), null)

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# DB Subnet Group
################################################################################

resource "aws_db_subnet_group" "this" {
  name        = local.internal_db_subnet_group_name
  description = "For RDS instance ${var.name}"
  subnet_ids  = var.subnets

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_db_subnet_group
  }
}

################################################################################
# DB Instance
################################################################################

resource "aws_db_instance" "this" {
  allocated_storage                     = var.allocated_storage
  allow_major_version_upgrade           = var.allow_major_version_upgrade
  apply_immediately                     = var.apply_immediately
  auto_minor_version_upgrade            = var.auto_minor_version_upgrade
  availability_zone                     = var.availability_zone
  backup_retention_period               = var.backup_retention_period
  backup_window                         = var.backup_window
  ca_cert_identifier                    = var.ca_cert_identifier
  character_set_name                    = var.character_set_name
  copy_tags_to_snapshot                 = var.copy_tags_to_snapshot
  custom_iam_instance_profile           = var.custom_iam_instance_profile
  database_insights_mode                = var.database_insights_mode
  db_name                               = var.database_name
  db_subnet_group_name                  = local.db_subnet_group_name
  dedicated_log_volume                  = var.dedicated_log_volume
  delete_automated_backups              = var.delete_automated_backups
  deletion_protection                   = var.deletion_protection
  domain                                = var.domain
  domain_iam_role_name                  = var.domain_iam_role_name
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports
  engine                                = var.engine
  engine_lifecycle_support              = var.engine_lifecycle_support
  engine_version                        = var.engine_version
  final_snapshot_identifier             = var.final_snapshot_identifier
  iam_database_authentication_enabled   = var.iam_database_authentication_enabled
  identifier                            = var.use_identifier_prefix ? null : var.name
  identifier_prefix                     = var.use_identifier_prefix ? "${var.name}-" : null
  instance_class                        = var.instance_class
  iops                                  = var.iops
  kms_key_id                            = var.kms_key_id
  license_model                         = var.license_model
  maintenance_window                    = var.maintenance_window
  manage_master_user_password           = var.manage_master_user_password ? var.manage_master_user_password : null
  master_user_secret_kms_key_id         = var.manage_master_user_password ? var.master_user_secret_kms_key_id : null
  max_allocated_storage                 = var.max_allocated_storage
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.create_monitoring_role ? try(aws_iam_role.rds_enhanced_monitoring.arn, null) : var.monitoring_role_arn
  multi_az                              = var.multi_az
  network_type                          = var.network_type
  option_group_name                     = var.create_db_option_group ? aws_db_option_group.this.name : var.option_group_name
  parameter_group_name                  = var.create_db_parameter_group ? aws_db_parameter_group.this.id : var.db_parameter_group_name
  password_wo                           = !var.manage_master_user_password ? var.master_password_wo : null
  password_wo_version                   = !var.manage_master_user_password ? var.master_password_wo_version : null
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = var.performance_insights_kms_key_id
  performance_insights_retention_period = var.performance_insights_retention_period
  port                                  = local.port
  publicly_accessible                   = var.publicly_accessible
  replica_mode                          = var.replica_mode
  replicate_source_db                   = var.replicate_source_db
  skip_final_snapshot                   = var.skip_final_snapshot
  snapshot_identifier                   = var.snapshot_identifier
  storage_encrypted                     = var.storage_encrypted
  storage_throughput                    = var.storage_throughput
  storage_type                          = var.storage_type
  timezone                              = var.timezone
  username                              = var.replicate_source_db == null ? var.master_username : null
  vpc_security_group_ids                = compact(concat([try(aws_security_group.this.id, "")], var.vpc_security_group_ids))

  dynamic "blue_green_update" {
    for_each = length(var.blue_green_update) > 0 ? [var.blue_green_update] : []

    content {
      enabled = try(blue_green_update.value.enabled, null)
    }
  }

  dynamic "restore_to_point_in_time" {
    for_each = length(var.restore_to_point_in_time) > 0 ? [var.restore_to_point_in_time] : []

    content {
      restore_time                             = try(restore_to_point_in_time.value.restore_time, null)
      source_db_instance_identifier            = try(restore_to_point_in_time.value.source_db_instance_identifier, null)
      source_db_instance_automated_backups_arn = try(restore_to_point_in_time.value.source_db_instance_automated_backups_arn, null)
      source_dbi_resource_id                   = try(restore_to_point_in_time.value.source_dbi_resource_id, null)
      use_latest_restorable_time               = try(restore_to_point_in_time.value.use_latest_restorable_time, null)
    }
  }

  dynamic "s3_import" {
    for_each = length(var.s3_import) > 0 ? [var.s3_import] : []

    content {
      bucket_name           = s3_import.value.bucket_name
      bucket_prefix         = try(s3_import.value.bucket_prefix, null)
      ingestion_role        = s3_import.value.ingestion_role
      source_engine         = "mysql"
      source_engine_version = s3_import.value.source_engine_version
    }
  }

  tags = merge(local.tags, var.instance_tags)

  timeouts {
    create = try(var.instance_timeouts.create, null)
    update = try(var.instance_timeouts.update, null)
    delete = try(var.instance_timeouts.delete, null)
  }

  lifecycle {
    enabled = local.enabled
    ignore_changes = [
      snapshot_identifier,
    ]
  }

  depends_on = [aws_cloudwatch_log_group.this]
}

################################################################################
# Read Replica(s)
################################################################################

resource "aws_db_instance" "read_replica" {
  for_each = { for k, v in var.read_replicas : k => v if local.enabled }

  replicate_source_db = aws_db_instance.this.identifier

  allocated_storage                     = try(each.value.allocated_storage, var.allocated_storage)
  allow_major_version_upgrade           = try(each.value.allow_major_version_upgrade, var.allow_major_version_upgrade)
  apply_immediately                     = try(each.value.apply_immediately, var.apply_immediately)
  auto_minor_version_upgrade            = try(each.value.auto_minor_version_upgrade, var.auto_minor_version_upgrade)
  availability_zone                     = try(each.value.availability_zone, null)
  backup_retention_period               = try(each.value.backup_retention_period, 0)
  ca_cert_identifier                    = var.ca_cert_identifier
  copy_tags_to_snapshot                 = try(each.value.copy_tags_to_snapshot, var.copy_tags_to_snapshot)
  custom_iam_instance_profile           = try(each.value.custom_iam_instance_profile, var.custom_iam_instance_profile)
  database_insights_mode                = try(each.value.database_insights_mode, var.database_insights_mode)
  db_subnet_group_name                  = local.db_subnet_group_name
  dedicated_log_volume                  = try(each.value.dedicated_log_volume, var.dedicated_log_volume)
  deletion_protection                   = try(each.value.deletion_protection, var.deletion_protection)
  enabled_cloudwatch_logs_exports       = try(each.value.enabled_cloudwatch_logs_exports, var.enabled_cloudwatch_logs_exports)
  engine                                = var.engine
  engine_version                        = var.engine_version
  identifier                            = var.use_identifier_prefix ? null : try(each.value.identifier, "${var.name}-${each.key}")
  identifier_prefix                     = var.use_identifier_prefix ? try(each.value.identifier_prefix, "${var.name}-${each.key}-") : null
  instance_class                        = try(each.value.instance_class, var.instance_class)
  iops                                  = try(each.value.iops, var.iops)
  kms_key_id                            = try(each.value.kms_key_id, var.kms_key_id)
  max_allocated_storage                 = try(each.value.max_allocated_storage, var.max_allocated_storage)
  monitoring_interval                   = try(each.value.monitoring_interval, var.monitoring_interval)
  monitoring_role_arn                   = var.create_monitoring_role ? try(aws_iam_role.rds_enhanced_monitoring.arn, null) : var.monitoring_role_arn
  multi_az                              = try(each.value.multi_az, false)
  network_type                          = try(each.value.network_type, var.network_type)
  option_group_name                     = var.create_db_option_group ? aws_db_option_group.this.name : try(each.value.option_group_name, var.option_group_name)
  parameter_group_name                  = var.create_db_parameter_group ? aws_db_parameter_group.this.id : try(each.value.parameter_group_name, var.db_parameter_group_name)
  performance_insights_enabled          = try(each.value.performance_insights_enabled, var.performance_insights_enabled)
  performance_insights_kms_key_id       = try(each.value.performance_insights_kms_key_id, var.performance_insights_kms_key_id)
  performance_insights_retention_period = try(each.value.performance_insights_retention_period, var.performance_insights_retention_period)
  port                                  = local.port
  publicly_accessible                   = try(each.value.publicly_accessible, var.publicly_accessible)
  replica_mode                          = try(each.value.replica_mode, var.replica_mode)
  skip_final_snapshot                   = true
  storage_encrypted                     = var.storage_encrypted
  storage_throughput                    = try(each.value.storage_throughput, var.storage_throughput)
  storage_type                          = try(each.value.storage_type, var.storage_type)
  vpc_security_group_ids                = compact(concat([try(aws_security_group.this.id, "")], var.vpc_security_group_ids))

  tags = merge(local.tags, try(each.value.tags, {}))

  timeouts {
    create = try(var.instance_timeouts.create, null)
    update = try(var.instance_timeouts.update, null)
    delete = try(var.instance_timeouts.delete, null)
  }
}

################################################################################
# Enhanced Monitoring
################################################################################

locals {
  create_monitoring_role = local.enabled && var.create_monitoring_role && var.monitoring_interval > 0
}

data "aws_iam_policy_document" "monitoring_rds_assume_role" {
  count = local.create_monitoring_role ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name        = var.iam_role_use_name_prefix ? null : var.iam_role_name
  name_prefix = var.iam_role_use_name_prefix ? "${var.iam_role_name}-" : null
  description = var.iam_role_description
  path        = var.iam_role_path

  assume_role_policy    = data.aws_iam_policy_document.monitoring_rds_assume_role[0].json
  permissions_boundary  = var.iam_role_permissions_boundary
  force_detach_policies = var.iam_role_force_detach_policies
  max_session_duration  = var.iam_role_max_session_duration

  tags = local.tags

  lifecycle {
    enabled = local.create_monitoring_role
  }
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"

  lifecycle {
    enabled = local.create_monitoring_role
  }
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring_custom" {
  for_each = { for idx, arn in(var.iam_role_managed_policy_arns != null ? var.iam_role_managed_policy_arns : []) : tostring(idx) => arn if local.create_monitoring_role }

  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = each.value
}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "this" {
  name        = var.security_group_use_name_prefix ? null : local.security_group_name
  name_prefix = var.security_group_use_name_prefix ? "${local.security_group_name}-" : null
  vpc_id      = var.vpc_id
  description = coalesce(var.security_group_description, "Control traffic to/from RDS instance ${var.name}")

  tags = merge(local.tags, var.security_group_tags, { Name = local.security_group_name })

  lifecycle {
    enabled               = local.enabled && var.create_security_group
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = { for k, v in var.security_group_rules : k => v if local.enabled && var.create_security_group && try(v.type, "ingress") == "ingress" }

  # Required
  security_group_id = aws_security_group.this.id
  ip_protocol       = try(each.value.ip_protocol, "tcp")

  # Optional
  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  cidr_ipv6                    = lookup(each.value, "cidr_ipv6", null)
  description                  = try(each.value.description, null)
  from_port                    = try(each.value.from_port, local.port)
  prefix_list_id               = lookup(each.value, "prefix_list_id", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
  to_port                      = try(each.value.to_port, local.port)

  tags = merge(local.tags, var.security_group_tags, try(each.value.tags, {}))
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = { for k, v in var.security_group_rules : k => v if local.enabled && var.create_security_group && try(v.type, "ingress") == "egress" }

  # Required
  security_group_id = aws_security_group.this.id
  ip_protocol       = try(each.value.ip_protocol, "tcp")

  # Optional
  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  cidr_ipv6                    = lookup(each.value, "cidr_ipv6", null)
  description                  = try(each.value.description, null)
  from_port                    = try(each.value.from_port, null)
  prefix_list_id               = lookup(each.value, "prefix_list_id", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
  to_port                      = try(each.value.to_port, null)

  tags = merge(local.tags, var.security_group_tags, try(each.value.tags, {}))
}

################################################################################
# DB Option Group
################################################################################

resource "aws_db_option_group" "this" {
  name                     = var.db_option_group_use_name_prefix ? null : local.option_group_name
  name_prefix              = var.db_option_group_use_name_prefix ? "${local.option_group_name}-" : null
  option_group_description = coalesce(var.db_option_group_description, "Option group for ${var.name}")
  engine_name              = coalesce(var.db_option_group_engine_name, var.engine)
  major_engine_version     = var.db_option_group_major_engine_version

  dynamic "option" {
    for_each = var.db_option_group_options

    content {
      option_name                    = option.value.option_name
      port                           = try(option.value.port, null)
      version                        = try(option.value.version, null)
      db_security_group_memberships  = try(option.value.db_security_group_memberships, null)
      vpc_security_group_memberships = try(option.value.vpc_security_group_memberships, null)

      dynamic "option_settings" {
        for_each = try(option.value.option_settings, [])

        content {
          name  = option_settings.value.name
          value = option_settings.value.value
        }
      }
    }
  }

  lifecycle {
    enabled               = local.enabled && var.create_db_option_group
    create_before_destroy = true
  }

  tags = local.tags
}

################################################################################
# DB Parameter Group
################################################################################

resource "aws_db_parameter_group" "this" {
  name        = var.db_parameter_group_use_name_prefix ? null : local.db_parameter_group_name
  name_prefix = var.db_parameter_group_use_name_prefix ? "${local.db_parameter_group_name}-" : null
  description = var.db_parameter_group_description
  family      = var.db_parameter_group_family

  dynamic "parameter" {
    for_each = var.db_parameter_group_parameters

    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = try(parameter.value.apply_method, "immediate")
    }
  }

  lifecycle {
    enabled               = local.enabled && var.create_db_parameter_group
    create_before_destroy = true
  }

  tags = local.tags
}

################################################################################
# CloudWatch Log Group
################################################################################

resource "aws_cloudwatch_log_group" "this" {
  for_each = toset([for log in var.enabled_cloudwatch_logs_exports : log if local.enabled && var.create_cloudwatch_log_group && !var.use_identifier_prefix])

  name              = "/aws/rds/instance/${var.name}/${each.value}"
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id
  skip_destroy      = var.cloudwatch_log_group_skip_destroy
  log_group_class   = var.cloudwatch_log_group_class

  tags = merge(local.tags, var.cloudwatch_log_group_tags)
}

################################################################################
# Managed Secret Rotation
################################################################################

resource "aws_secretsmanager_secret_rotation" "this" {
  secret_id          = aws_db_instance.this.master_user_secret[0].secret_arn
  rotate_immediately = var.master_user_password_rotate_immediately

  rotation_rules {
    automatically_after_days = var.master_user_password_rotation_automatically_after_days
    duration                 = var.master_user_password_rotation_duration
    schedule_expression      = var.master_user_password_rotation_schedule_expression
  }

  lifecycle {
    enabled = local.enabled && var.manage_master_user_password && var.manage_master_user_password_rotation
  }
}

################################################################################
# OpenTofu Check Blocks
################################################################################

check "encryption_enabled" {
  assert {
    condition     = !var.enabled || aws_db_instance.this.storage_encrypted
    error_message = "RDS instance must have storage encryption enabled."
  }
}
