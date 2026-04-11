locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# Subnet Group
################################################################################

resource "aws_memorydb_subnet_group" "this" {
  name        = var.subnet_group_name != null ? var.subnet_group_name : var.name
  description = "MemoryDB subnet group for ${var.name}"
  subnet_ids  = var.subnet_ids

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_subnet_group
  }
}

################################################################################
# Parameter Group
################################################################################

resource "aws_memorydb_parameter_group" "this" {
  name        = var.parameter_group_name != null ? var.parameter_group_name : var.name
  description = "MemoryDB parameter group for ${var.name}"
  family      = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.parameters

    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_parameter_group
  }
}

################################################################################
# ACL
################################################################################

resource "aws_memorydb_acl" "this" {
  name       = var.acl_name != null ? var.acl_name : var.name
  user_names = concat(["default"], [for u in aws_memorydb_user.this : u.user_name])

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_acl
  }

  depends_on = [aws_memorydb_user.this]
}

################################################################################
# Users
################################################################################

resource "aws_memorydb_user" "this" {
  for_each = { for k, v in var.users : k => v if local.enabled }

  user_name     = each.value.user_name
  access_string = each.value.access_string

  authentication_mode {
    type      = try(each.value.authentication_mode.type, "password")
    passwords = try(each.value.authentication_mode.passwords, null)
  }

  tags = merge(local.tags, try(each.value.tags, {}))
}

################################################################################
# Cluster
################################################################################

resource "aws_memorydb_cluster" "this" {
  name                   = var.name
  description            = var.description != null ? var.description : "MemoryDB cluster ${var.name}"
  node_type              = var.node_type
  num_shards             = var.num_shards
  num_replicas_per_shard = var.num_replicas_per_shard
  port                   = var.port
  engine                 = var.engine
  engine_version         = var.engine_version

  acl_name                   = var.create_acl ? aws_memorydb_acl.this.name : var.acl_name
  parameter_group_name       = var.create_parameter_group ? aws_memorydb_parameter_group.this.name : var.parameter_group_name
  subnet_group_name          = var.create_subnet_group ? aws_memorydb_subnet_group.this.name : var.subnet_group_name
  security_group_ids         = var.security_group_ids
  maintenance_window         = var.maintenance_window
  snapshot_window            = var.snapshot_window
  snapshot_retention_limit   = var.snapshot_retention_limit
  snapshot_name              = var.snapshot_name
  snapshot_arns              = var.snapshot_arns
  final_snapshot_name        = var.final_snapshot_name
  sns_topic_arn              = var.sns_topic_arn
  kms_key_arn                = var.kms_key_arn
  tls_enabled                = var.tls_enabled
  data_tiering               = var.data_tiering
  auto_minor_version_upgrade = var.auto_minor_version_upgrade


  tags = merge(local.tags, { Name = var.name })

  lifecycle {
    enabled = local.enabled
    ignore_changes = [
      snapshot_name,
      snapshot_arns,
    ]
  }

  depends_on = [
    aws_memorydb_subnet_group.this,
    aws_memorydb_parameter_group.this,
    aws_memorydb_acl.this,
  ]
}
