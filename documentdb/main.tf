locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  port = 27017
}

################################################################################
# Subnet Group
################################################################################

resource "aws_docdb_subnet_group" "this" {
  name        = var.subnet_group_name != null ? var.subnet_group_name : var.name
  description = "DocumentDB subnet group for ${var.name}"
  subnet_ids  = var.subnet_ids

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_subnet_group
  }
}

################################################################################
# Cluster Parameter Group
################################################################################

resource "aws_docdb_cluster_parameter_group" "this" {
  name        = var.cluster_parameter_group_name != null ? var.cluster_parameter_group_name : "${var.name}-cluster"
  description = "DocumentDB cluster parameter group for ${var.name}"
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
# Security Group
################################################################################

resource "aws_security_group" "this" {
  name        = "${var.name}-docdb"
  vpc_id      = var.vpc_id
  description = "Security group for DocumentDB cluster ${var.name}"

  tags = merge(local.tags, { Name = "${var.name}-docdb" })

  lifecycle {
    enabled               = local.enabled && var.create_security_group
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = { for k, v in var.security_group_rules : k => v if local.enabled && var.create_security_group && try(v.type, "ingress") == "ingress" }

  security_group_id            = aws_security_group.this.id
  ip_protocol                  = try(each.value.ip_protocol, "tcp")
  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  cidr_ipv6                    = lookup(each.value, "cidr_ipv6", null)
  description                  = try(each.value.description, null)
  from_port                    = try(each.value.from_port, local.port)
  prefix_list_id               = lookup(each.value, "prefix_list_id", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
  to_port                      = try(each.value.to_port, local.port)

  tags = merge(local.tags, try(each.value.tags, {}))
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = { for k, v in var.security_group_rules : k => v if local.enabled && var.create_security_group && try(v.type, "ingress") == "egress" }

  security_group_id            = aws_security_group.this.id
  ip_protocol                  = try(each.value.ip_protocol, "tcp")
  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  cidr_ipv6                    = lookup(each.value, "cidr_ipv6", null)
  description                  = try(each.value.description, null)
  from_port                    = try(each.value.from_port, null)
  prefix_list_id               = lookup(each.value, "prefix_list_id", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
  to_port                      = try(each.value.to_port, null)

  tags = merge(local.tags, try(each.value.tags, {}))
}

################################################################################
# Cluster
################################################################################

resource "aws_docdb_cluster" "this" {
  cluster_identifier              = var.name
  engine                          = "docdb"
  engine_version                  = var.engine_version
  port                            = local.port
  master_username                 = var.master_username
  master_password_wo              = var.master_password_wo
  master_password_wo_version      = var.master_password_wo_version
  db_subnet_group_name            = var.create_subnet_group ? aws_docdb_subnet_group.this.name : var.subnet_group_name
  db_cluster_parameter_group_name = var.create_cluster_parameter_group ? aws_docdb_cluster_parameter_group.this.name : var.cluster_parameter_group_name
  vpc_security_group_ids          = compact(concat([try(aws_security_group.this.id, "")], var.vpc_security_group_ids))
  storage_encrypted               = var.storage_encrypted
  kms_key_id                      = var.kms_key_id
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = var.final_snapshot_identifier
  snapshot_identifier             = var.snapshot_identifier
  apply_immediately               = var.apply_immediately
  deletion_protection             = var.deletion_protection
  storage_type                    = var.storage_type
  allow_major_version_upgrade     = var.allow_major_version_upgrade
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  tags = merge(local.tags, { Name = var.name })

  lifecycle {
    enabled = local.enabled
    ignore_changes = [
      snapshot_identifier,
    ]
  }

  depends_on = [
    aws_docdb_subnet_group.this,
    aws_docdb_cluster_parameter_group.this,
    aws_cloudwatch_log_group.this,
  ]
}

################################################################################
# Cluster Instances
################################################################################

resource "aws_docdb_cluster_instance" "this" {
  for_each = { for k, v in var.instances : k => v if local.enabled }

  identifier                      = try(each.value.identifier, "${var.name}-${each.key}")
  cluster_identifier              = aws_docdb_cluster.this.id
  instance_class                  = try(each.value.instance_class, var.instance_class)
  apply_immediately               = try(each.value.apply_immediately, var.apply_immediately)
  auto_minor_version_upgrade      = try(each.value.auto_minor_version_upgrade, var.auto_minor_version_upgrade)
  availability_zone               = try(each.value.availability_zone, null)
  ca_cert_identifier              = try(each.value.ca_cert_identifier, var.ca_cert_identifier)
  enable_performance_insights     = try(each.value.enable_performance_insights, var.enable_performance_insights)
  performance_insights_kms_key_id = try(each.value.performance_insights_kms_key_id, var.performance_insights_kms_key_id)
  preferred_maintenance_window    = try(each.value.preferred_maintenance_window, var.preferred_maintenance_window)
  promotion_tier                  = try(each.value.promotion_tier, null)

  tags = merge(local.tags, try(each.value.tags, {}))
}

################################################################################
# CloudWatch Log Group
################################################################################

resource "aws_cloudwatch_log_group" "this" {
  for_each = toset([for log in var.enabled_cloudwatch_logs_exports : log if local.enabled && var.create_cloudwatch_log_group])

  name              = "/aws/docdb/${var.name}/${each.value}"
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id
  skip_destroy      = var.cloudwatch_log_group_skip_destroy
  log_group_class   = var.cloudwatch_log_group_class

  tags = merge(local.tags, var.cloudwatch_log_group_tags)
}

################################################################################
# OpenTofu Check Blocks
################################################################################

check "encryption_enabled" {
  assert {
    condition     = !var.enabled || aws_docdb_cluster.this.storage_encrypted
    error_message = "DocumentDB cluster must have storage encryption enabled."
  }
}

check "deletion_protection_enabled" {
  assert {
    condition     = !var.enabled || aws_docdb_cluster.this.deletion_protection
    error_message = "DocumentDB cluster should have deletion protection enabled for production use."
  }
}
