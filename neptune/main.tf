locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  port = 8182
}

################################################################################
# Subnet Group
################################################################################

resource "aws_neptune_subnet_group" "this" {
  name        = var.subnet_group_name != null ? var.subnet_group_name : var.name
  description = "Neptune subnet group for ${var.name}"
  subnet_ids  = var.subnet_ids

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_subnet_group
  }
}

################################################################################
# Cluster Parameter Group
################################################################################

resource "aws_neptune_cluster_parameter_group" "this" {
  name        = var.cluster_parameter_group_name != null ? var.cluster_parameter_group_name : "${var.name}-cluster"
  description = "Neptune cluster parameter group for ${var.name}"
  family      = var.cluster_parameter_group_family

  dynamic "parameter" {
    for_each = var.cluster_parameters

    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = try(parameter.value.apply_method, "immediate")
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_cluster_parameter_group
  }
}

################################################################################
# Instance Parameter Group
################################################################################

resource "aws_neptune_parameter_group" "this" {
  name        = var.instance_parameter_group_name != null ? var.instance_parameter_group_name : "${var.name}-instance"
  description = "Neptune instance parameter group for ${var.name}"
  family      = var.instance_parameter_group_family

  dynamic "parameter" {
    for_each = var.instance_parameters

    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = try(parameter.value.apply_method, "immediate")
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_instance_parameter_group
  }
}

################################################################################
# Cluster
################################################################################

resource "aws_neptune_cluster" "this" {
  cluster_identifier                   = var.name
  engine                               = var.engine
  engine_version                       = var.engine_version
  port                                 = local.port
  neptune_subnet_group_name            = var.create_subnet_group ? aws_neptune_subnet_group.this.name : var.subnet_group_name
  neptune_cluster_parameter_group_name = var.create_cluster_parameter_group ? aws_neptune_cluster_parameter_group.this.name : var.cluster_parameter_group_name
  vpc_security_group_ids               = var.vpc_security_group_ids
  storage_encrypted                    = var.storage_encrypted
  kms_key_arn                          = var.kms_key_arn
  iam_database_authentication_enabled  = var.iam_database_authentication_enabled
  iam_roles                            = var.iam_roles
  backup_retention_period              = var.backup_retention_period
  preferred_backup_window              = var.preferred_backup_window
  preferred_maintenance_window         = var.preferred_maintenance_window
  skip_final_snapshot                  = var.skip_final_snapshot
  final_snapshot_identifier            = var.final_snapshot_identifier
  snapshot_identifier                  = var.snapshot_identifier
  apply_immediately                    = var.apply_immediately
  deletion_protection                  = var.deletion_protection
  enable_cloudwatch_logs_exports       = var.enable_cloudwatch_logs_exports
  storage_type                         = var.storage_type
  allow_major_version_upgrade          = var.allow_major_version_upgrade
  copy_tags_to_snapshot                = var.copy_tags_to_snapshot

  dynamic "serverless_v2_scaling_configuration" {
    for_each = length(var.serverless_v2_scaling_configuration) > 0 ? [var.serverless_v2_scaling_configuration] : []

    content {
      min_capacity = serverless_v2_scaling_configuration.value.min_capacity
      max_capacity = serverless_v2_scaling_configuration.value.max_capacity
    }
  }

  tags = merge(local.tags, { Name = var.name })

  lifecycle {
    enabled = local.enabled
    ignore_changes = [
      snapshot_identifier,
    ]
  }

  depends_on = [
    aws_neptune_subnet_group.this,
    aws_neptune_cluster_parameter_group.this,
  ]
}

################################################################################
# Cluster Instances
################################################################################

resource "aws_neptune_cluster_instance" "this" {
  for_each = { for k, v in var.instances : k => v if local.enabled }

  identifier                   = try(each.value.identifier, "${var.name}-${each.key}")
  cluster_identifier           = aws_neptune_cluster.this.id
  instance_class               = try(each.value.instance_class, var.instance_class)
  neptune_parameter_group_name = var.create_instance_parameter_group ? aws_neptune_parameter_group.this.name : try(each.value.neptune_parameter_group_name, var.instance_parameter_group_name)
  apply_immediately            = try(each.value.apply_immediately, var.apply_immediately)
  auto_minor_version_upgrade   = try(each.value.auto_minor_version_upgrade, var.auto_minor_version_upgrade)
  availability_zone            = try(each.value.availability_zone, null)
  preferred_maintenance_window = try(each.value.preferred_maintenance_window, var.preferred_maintenance_window)
  promotion_tier               = try(each.value.promotion_tier, null)
  publicly_accessible          = try(each.value.publicly_accessible, false)

  tags = merge(local.tags, try(each.value.tags, {}))
}
