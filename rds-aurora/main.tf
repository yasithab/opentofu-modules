data "aws_partition" "current" {}

locals {
  create = var.enabled

  port = coalesce(var.port, (var.engine == "aurora-postgresql" || var.engine == "postgres" ? 5432 : 3306))

  internal_db_subnet_group_name = try(coalesce(var.db_subnet_group_name, var.name), "")
  db_subnet_group_name          = var.create_db_subnet_group ? try(aws_db_subnet_group.this.name, null) : local.internal_db_subnet_group_name

  security_group_name = try(coalesce(var.security_group_name, var.name), "")

  cluster_parameter_group_name = try(coalesce(var.db_cluster_parameter_group_name, var.name), null)
  db_parameter_group_name      = try(coalesce(var.db_parameter_group_name, var.name), null)

  backtrack_window = (var.engine == "aurora-mysql" || var.engine == "aurora") && var.engine_mode != "serverless" ? var.backtrack_window : 0

  is_serverless = var.engine_mode == "serverless"

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# DB Subnet Group
################################################################################

resource "aws_db_subnet_group" "this" {
  name        = local.internal_db_subnet_group_name
  description = "For Aurora cluster ${var.name}"
  subnet_ids  = var.subnets

  tags = local.tags

  lifecycle {
    enabled = local.create && var.create_db_subnet_group
  }
}

################################################################################
# Cluster
################################################################################

resource "aws_rds_cluster" "this" {
  allocated_storage                   = var.allocated_storage
  allow_major_version_upgrade         = var.allow_major_version_upgrade
  apply_immediately                   = var.apply_immediately
  availability_zones                  = var.availability_zones
  backup_retention_period             = var.backup_retention_period
  backtrack_window                    = local.backtrack_window
  ca_certificate_identifier           = var.cluster_ca_cert_identifier
  cluster_identifier                  = var.cluster_use_name_prefix ? null : var.name
  cluster_identifier_prefix           = var.cluster_use_name_prefix ? "${var.name}-" : null
  cluster_members                     = var.cluster_members
  cluster_scalability_type            = var.cluster_scalability_type
  copy_tags_to_snapshot               = var.copy_tags_to_snapshot
  database_insights_mode              = var.database_insights_mode
  database_name                       = var.is_primary_cluster ? var.database_name : null
  db_cluster_instance_class           = var.db_cluster_instance_class
  db_cluster_parameter_group_name     = var.create_db_cluster_parameter_group ? aws_rds_cluster_parameter_group.this.id : var.db_cluster_parameter_group_name
  db_instance_parameter_group_name    = var.allow_major_version_upgrade ? var.db_cluster_db_instance_parameter_group_name : null
  db_subnet_group_name                = local.db_subnet_group_name
  db_system_id                        = var.db_system_id
  delete_automated_backups            = var.delete_automated_backups
  deletion_protection                 = var.deletion_protection
  enable_global_write_forwarding      = var.enable_global_write_forwarding
  enable_local_write_forwarding       = var.enable_local_write_forwarding
  enabled_cloudwatch_logs_exports     = var.enabled_cloudwatch_logs_exports
  enable_http_endpoint                = var.enable_http_endpoint
  engine                              = var.engine
  engine_mode                         = var.cluster_scalability_type == "limitless" ? "" : var.engine_mode
  engine_version                      = var.engine_version
  engine_lifecycle_support            = var.engine_lifecycle_support
  final_snapshot_identifier           = var.final_snapshot_identifier
  global_cluster_identifier           = var.global_cluster_identifier
  domain                              = var.domain
  domain_iam_role_name                = var.domain_iam_role_name
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  # iam_roles has been removed from this resource and instead will be used with aws_rds_cluster_role_association below to avoid conflicts per docs
  iops                                  = var.iops
  kms_key_id                            = var.kms_key_id
  manage_master_user_password           = var.global_cluster_identifier == null && var.manage_master_user_password ? var.manage_master_user_password : null
  master_user_secret_kms_key_id         = var.global_cluster_identifier == null && var.manage_master_user_password ? var.master_user_secret_kms_key_id : null
  master_password_wo                    = var.is_primary_cluster && !var.manage_master_user_password ? var.master_password_wo : null
  master_password_wo_version            = var.is_primary_cluster && !var.manage_master_user_password ? var.master_password_wo_version : null
  master_username                       = var.is_primary_cluster ? var.master_username : null
  monitoring_interval                   = var.cluster_monitoring_interval
  monitoring_role_arn                   = var.create_monitoring_role && var.cluster_monitoring_interval > 0 ? try(aws_iam_role.rds_enhanced_monitoring.arn, null) : var.monitoring_role_arn
  network_type                          = var.network_type
  performance_insights_enabled          = var.cluster_performance_insights_enabled
  performance_insights_kms_key_id       = var.cluster_performance_insights_kms_key_id
  performance_insights_retention_period = var.cluster_performance_insights_retention_period
  port                                  = local.port
  preferred_backup_window               = local.is_serverless ? null : var.preferred_backup_window
  preferred_maintenance_window          = var.preferred_maintenance_window
  replication_source_identifier         = var.replication_source_identifier

  dynamic "restore_to_point_in_time" {
    for_each = length(var.restore_to_point_in_time) > 0 ? [var.restore_to_point_in_time] : []

    content {
      restore_to_time            = try(restore_to_point_in_time.value.restore_to_time, null)
      restore_type               = try(restore_to_point_in_time.value.restore_type, null)
      source_cluster_identifier  = try(restore_to_point_in_time.value.source_cluster_identifier, null)
      source_cluster_resource_id = try(restore_to_point_in_time.value.source_cluster_resource_id, null)
      use_latest_restorable_time = try(restore_to_point_in_time.value.use_latest_restorable_time, null)
    }
  }

  dynamic "s3_import" {
    for_each = length(var.s3_import) > 0 && !local.is_serverless ? [var.s3_import] : []

    content {
      bucket_name           = s3_import.value.bucket_name
      bucket_prefix         = try(s3_import.value.bucket_prefix, null)
      ingestion_role        = s3_import.value.ingestion_role
      source_engine         = "mysql"
      source_engine_version = s3_import.value.source_engine_version
    }
  }

  dynamic "scaling_configuration" {
    for_each = length(var.scaling_configuration) > 0 && local.is_serverless ? [var.scaling_configuration] : []

    content {
      auto_pause               = try(scaling_configuration.value.auto_pause, null)
      max_capacity             = try(scaling_configuration.value.max_capacity, null)
      min_capacity             = try(scaling_configuration.value.min_capacity, null)
      seconds_until_auto_pause = try(scaling_configuration.value.seconds_until_auto_pause, null)
      seconds_before_timeout   = try(scaling_configuration.value.seconds_before_timeout, null)
      timeout_action           = try(scaling_configuration.value.timeout_action, null)
    }
  }

  dynamic "serverlessv2_scaling_configuration" {
    for_each = length(var.serverlessv2_scaling_configuration) > 0 && var.engine_mode == "provisioned" ? [var.serverlessv2_scaling_configuration] : []

    content {
      max_capacity             = serverlessv2_scaling_configuration.value.max_capacity
      min_capacity             = serverlessv2_scaling_configuration.value.min_capacity
      seconds_until_auto_pause = try(serverlessv2_scaling_configuration.value.seconds_until_auto_pause, null)
    }
  }

  skip_final_snapshot    = var.skip_final_snapshot
  snapshot_identifier    = var.snapshot_identifier
  source_region          = var.source_region
  storage_encrypted      = var.storage_encrypted
  storage_type           = var.storage_type
  tags                   = merge(local.tags, var.cluster_tags)
  vpc_security_group_ids = compact(concat([try(aws_security_group.this.id, "")], var.vpc_security_group_ids))

  timeouts {
    create = try(var.cluster_timeouts.create, null)
    update = try(var.cluster_timeouts.update, null)
    delete = try(var.cluster_timeouts.delete, null)
  }

  lifecycle {
    enabled = local.create
    ignore_changes = [
      # See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster#replication_source_identifier
      # Since this is used either in read-replica clusters or global clusters, this should be acceptable to specify
      replication_source_identifier,
      # See docs here https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_global_cluster#new-global-cluster-from-existing-db-cluster
      global_cluster_identifier,
      snapshot_identifier,
    ]
  }

  depends_on = [aws_cloudwatch_log_group.this]
}

################################################################################
# Cluster Instance(s)
################################################################################

resource "aws_rds_cluster_instance" "this" {
  for_each = { for k, v in var.instances : k => v if local.create && !local.is_serverless }

  apply_immediately                     = try(each.value.apply_immediately, var.apply_immediately)
  auto_minor_version_upgrade            = try(each.value.auto_minor_version_upgrade, var.auto_minor_version_upgrade)
  availability_zone                     = try(each.value.availability_zone, null)
  ca_cert_identifier                    = var.ca_cert_identifier
  cluster_identifier                    = aws_rds_cluster.this.id
  custom_iam_instance_profile           = try(each.value.custom_iam_instance_profile, var.custom_iam_instance_profile)
  copy_tags_to_snapshot                 = try(each.value.copy_tags_to_snapshot, var.copy_tags_to_snapshot)
  db_parameter_group_name               = var.create_db_parameter_group ? aws_db_parameter_group.this.id : try(each.value.db_parameter_group_name, var.db_parameter_group_name)
  db_subnet_group_name                  = local.db_subnet_group_name
  engine                                = var.engine
  engine_version                        = var.engine_version
  force_destroy                         = try(each.value.force_destroy, var.instance_force_destroy)
  identifier                            = var.instances_use_identifier_prefix ? null : try(each.value.identifier, "${var.name}-${each.key}")
  identifier_prefix                     = var.instances_use_identifier_prefix ? try(each.value.identifier_prefix, "${var.name}-${each.key}-") : null
  instance_class                        = try(each.value.instance_class, var.instance_class)
  monitoring_interval                   = var.cluster_monitoring_interval > 0 ? var.cluster_monitoring_interval : try(each.value.monitoring_interval, var.monitoring_interval)
  monitoring_role_arn                   = var.create_monitoring_role ? try(aws_iam_role.rds_enhanced_monitoring.arn, null) : var.monitoring_role_arn
  performance_insights_enabled          = try(each.value.performance_insights_enabled, var.performance_insights_enabled)
  performance_insights_kms_key_id       = try(each.value.performance_insights_kms_key_id, var.performance_insights_kms_key_id)
  performance_insights_retention_period = try(each.value.performance_insights_retention_period, var.performance_insights_retention_period)
  # preferred_backup_window - is set at the cluster level and will error if provided here
  preferred_maintenance_window = try(each.value.preferred_maintenance_window, var.preferred_maintenance_window)
  promotion_tier               = try(each.value.promotion_tier, null)
  publicly_accessible          = try(each.value.publicly_accessible, var.publicly_accessible)
  tags                         = merge(local.tags, try(each.value.tags, {}))

  timeouts {
    create = try(var.instance_timeouts.create, null)
    update = try(var.instance_timeouts.update, null)
    delete = try(var.instance_timeouts.delete, null)
  }
}

################################################################################
# Cluster Endpoint(s)
################################################################################

resource "aws_rds_cluster_endpoint" "this" {
  for_each = { for k, v in var.endpoints : k => v if local.create && !local.is_serverless }

  cluster_endpoint_identifier = each.value.identifier
  cluster_identifier          = aws_rds_cluster.this.id
  custom_endpoint_type        = each.value.type
  excluded_members            = try(each.value.excluded_members, null)
  static_members              = try(each.value.static_members, null)
  tags                        = merge(local.tags, try(each.value.tags, {}))

  depends_on = [
    aws_rds_cluster_instance.this
  ]
}

################################################################################
# Cluster IAM Roles
################################################################################

resource "aws_rds_cluster_role_association" "this" {
  for_each = { for k, v in var.iam_roles : k => v if local.create }

  db_cluster_identifier = aws_rds_cluster.this.id
  feature_name          = each.value.feature_name
  role_arn              = each.value.role_arn
}

################################################################################
# Enhanced Monitoring
################################################################################

locals {
  create_monitoring_role = local.create && var.create_monitoring_role && (var.monitoring_interval > 0 || var.cluster_monitoring_interval > 0)
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
# Autoscaling
################################################################################

resource "aws_appautoscaling_target" "this" {
  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "cluster:${aws_rds_cluster.this.cluster_identifier}"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  service_namespace  = "rds"

  tags = local.tags

  lifecycle {
    enabled = local.create && var.autoscaling_enabled && !local.is_serverless
    ignore_changes = [
      tags_all,
    ]
  }
}

resource "aws_appautoscaling_policy" "this" {
  name               = var.autoscaling_policy_name
  policy_type        = "TargetTrackingScaling"
  resource_id        = "cluster:${aws_rds_cluster.this.cluster_identifier}"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  service_namespace  = "rds"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = var.predefined_metric_type
    }

    scale_in_cooldown  = var.autoscaling_scale_in_cooldown
    scale_out_cooldown = var.autoscaling_scale_out_cooldown
    target_value       = var.predefined_metric_type == "RDSReaderAverageCPUUtilization" ? var.autoscaling_target_cpu : var.autoscaling_target_connections
  }

  depends_on = [
    aws_appautoscaling_target.this
  ]

  lifecycle {
    enabled = local.create && var.autoscaling_enabled && !local.is_serverless
  }
}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "this" {
  name        = var.security_group_use_name_prefix ? null : local.security_group_name
  name_prefix = var.security_group_use_name_prefix ? "${local.security_group_name}-" : null
  vpc_id      = var.vpc_id
  description = coalesce(var.security_group_description, "Control traffic to/from RDS Aurora ${var.name}")

  tags = merge(local.tags, var.security_group_tags, { Name = local.security_group_name })

  lifecycle {
    enabled               = local.create && var.create_security_group
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = { for k, v in var.security_group_rules : k => v if local.create && var.create_security_group && try(v.type, "ingress") == "ingress" }

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
  for_each = { for k, v in var.security_group_rules : k => v if local.create && var.create_security_group && try(v.type, "ingress") == "egress" }

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
# Cluster Parameter Group
################################################################################

resource "aws_rds_cluster_parameter_group" "this" {
  name        = var.db_cluster_parameter_group_use_name_prefix ? null : local.cluster_parameter_group_name
  name_prefix = var.db_cluster_parameter_group_use_name_prefix ? "${local.cluster_parameter_group_name}-" : null
  description = var.db_cluster_parameter_group_description
  family      = var.db_cluster_parameter_group_family

  dynamic "parameter" {
    for_each = var.db_cluster_parameter_group_parameters

    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = try(parameter.value.apply_method, "immediate")
    }
  }

  lifecycle {
    enabled               = local.create && var.create_db_cluster_parameter_group
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
    enabled               = local.create && var.create_db_parameter_group
    create_before_destroy = true
  }

  tags = local.tags
}

################################################################################
# CloudWatch Log Group
################################################################################

# Log groups will not be created if using a cluster identifier prefix
resource "aws_cloudwatch_log_group" "this" {
  for_each = toset([for log in var.enabled_cloudwatch_logs_exports : log if local.create && var.create_cloudwatch_log_group && !var.cluster_use_name_prefix])

  name              = "/aws/rds/cluster/${var.name}/${each.value}"
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id
  skip_destroy      = var.cloudwatch_log_group_skip_destroy
  log_group_class   = var.cloudwatch_log_group_class

  tags = merge(local.tags, var.cloudwatch_log_group_tags)
}

################################################################################
# Cluster Activity Stream
################################################################################

resource "aws_rds_cluster_activity_stream" "this" {
  resource_arn                        = aws_rds_cluster.this.arn
  mode                                = var.db_cluster_activity_stream_mode
  kms_key_id                          = var.db_cluster_activity_stream_kms_key_id
  engine_native_audit_fields_included = var.engine_native_audit_fields_included

  depends_on = [aws_rds_cluster_instance.this]

  lifecycle {
    enabled = local.create && var.create_db_cluster_activity_stream
  }
}

################################################################################
# Managed Secret Rotation
################################################################################

# There is not currently a way to disable secret rotation on an initial apply.
# In order to use master password secrets management without a rotation, the following workaround can be used:
# `manage_master_user_password_rotation` must be set to true first and applied followed by setting it to false and another apply.
# Note: when setting `manage_master_user_password_rotation` to true, a schedule must also be set using `master_user_password_rotation_schedule_expression` or `master_user_password_rotation_automatically_after_days`.
# To prevent password from being immediately rotated when implementing this workaround, set `master_user_password_rotate_immediately` to false.
# See: https://github.com/hashicorp/terraform-provider-aws/issues/37779
resource "aws_secretsmanager_secret_rotation" "this" {
  secret_id          = aws_rds_cluster.this.master_user_secret[0].secret_arn
  rotate_immediately = var.master_user_password_rotate_immediately

  rotation_rules {
    automatically_after_days = var.master_user_password_rotation_automatically_after_days
    duration                 = var.master_user_password_rotation_duration
    schedule_expression      = var.master_user_password_rotation_schedule_expression
  }

  lifecycle {
    enabled = local.create && var.manage_master_user_password && var.manage_master_user_password_rotation
  }
}

################################################################################
# RDS Shard Group
################################################################################

resource "aws_rds_shard_group" "this" {
  compute_redundancy        = var.compute_redundancy
  db_cluster_identifier     = aws_rds_cluster.this.id
  db_shard_group_identifier = var.db_shard_group_identifier
  max_acu                   = var.max_acu
  min_acu                   = var.min_acu
  publicly_accessible       = var.publicly_accessible
  tags                      = merge(local.tags, var.shard_group_tags)

  timeouts {
    create = try(var.shard_group_timeouts.create, null)
    update = try(var.shard_group_timeouts.update, null)
    delete = try(var.shard_group_timeouts.delete, null)
  }

  lifecycle {
    enabled = local.create && var.create_shard_group
  }
}

################################################################################
# OpenTofu Check Blocks
################################################################################

check "encryption_enabled" {
  assert {
    condition     = !var.enabled || aws_rds_cluster.this.storage_encrypted
    error_message = "RDS cluster must have storage encryption enabled."
  }
}
