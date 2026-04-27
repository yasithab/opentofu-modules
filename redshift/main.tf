locals {
  enabled = var.enabled
  port    = var.port

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

###############################################################################################################
# Base configurations
###############################################################################################################

data "aws_partition" "current" {}

resource "random_password" "master_password" {
  length           = var.random_password_length
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"

  lifecycle {
    enabled = local.enabled && var.create_random_password
  }
}

################################################################################
# Cluster
################################################################################

locals {
  subnet_group_name    = local.enabled && var.create_subnet_group ? aws_redshift_subnet_group.this.name : var.subnet_group_name
  parameter_group_name = local.enabled && var.create_parameter_group ? aws_redshift_parameter_group.this.id : var.parameter_group_name

  master_password = local.enabled && var.create_random_password ? random_password.master_password.result : var.master_password
}

resource "aws_redshift_cluster" "this" {
  allow_version_upgrade                = var.allow_version_upgrade
  apply_immediately                    = var.apply_immediately
  aqua_configuration_status            = var.aqua_configuration_status
  automated_snapshot_retention_period  = var.automated_snapshot_retention_period
  availability_zone                    = var.availability_zone
  availability_zone_relocation_enabled = var.availability_zone_relocation_enabled
  cluster_identifier                   = var.cluster_identifier
  cluster_parameter_group_name         = local.parameter_group_name
  cluster_subnet_group_name            = local.subnet_group_name
  cluster_type                         = var.number_of_nodes > 1 ? "multi-node" : "single-node"
  cluster_version                      = var.cluster_version
  database_name                        = var.database_name
  elastic_ip                           = var.elastic_ip
  encrypted                            = var.encrypted
  enhanced_vpc_routing                 = var.enhanced_vpc_routing
  final_snapshot_identifier            = var.skip_final_snapshot ? null : var.final_snapshot_identifier
  kms_key_id                           = var.kms_key_arn

  # iam_roles and default_iam_roles are managed in the aws_redshift_cluster_iam_roles resource below

  maintenance_track_name            = var.maintenance_track_name
  manual_snapshot_retention_period  = var.manual_snapshot_retention_period
  manage_master_password            = var.manage_master_password ? var.manage_master_password : null
  master_password                   = var.snapshot_identifier == null && !var.manage_master_password && !var.use_master_password_wo ? local.master_password : null
  master_password_wo                = var.snapshot_identifier == null && !var.manage_master_password && var.use_master_password_wo ? local.master_password : null
  master_password_wo_version        = var.snapshot_identifier == null && !var.manage_master_password && var.use_master_password_wo ? var.master_password_wo_version : null
  master_password_secret_kms_key_id = var.master_password_secret_kms_key_id
  master_username                   = var.master_username
  multi_az                          = var.multi_az
  node_type                         = var.node_type
  number_of_nodes                   = var.number_of_nodes
  owner_account                     = var.owner_account
  port                              = var.port
  preferred_maintenance_window      = var.preferred_maintenance_window
  publicly_accessible               = var.publicly_accessible
  skip_final_snapshot               = var.skip_final_snapshot
  snapshot_arn                      = var.snapshot_arn
  snapshot_cluster_identifier       = var.snapshot_cluster_identifier

  snapshot_identifier    = var.snapshot_identifier
  vpc_security_group_ids = concat([aws_security_group.this.id], var.vpc_security_group_ids)

  tags = local.tags

  timeouts {
    create = try(var.cluster_timeouts.create, null)
    update = try(var.cluster_timeouts.update, null)
    delete = try(var.cluster_timeouts.delete, null)
  }

  lifecycle {
    enabled        = local.enabled
    ignore_changes = [master_password]
  }

  depends_on = [aws_cloudwatch_log_group.this]
}

################################################################################
# IAM Roles
################################################################################

resource "aws_redshift_cluster_iam_roles" "this" {
  cluster_identifier   = aws_redshift_cluster.this.id
  iam_role_arns        = var.iam_role_arns
  default_iam_role_arn = var.default_iam_role_arn

  lifecycle {
    enabled = local.enabled && length(var.iam_role_arns) > 0
  }
}

################################################################################
# Parameter Group
################################################################################

resource "aws_redshift_parameter_group" "this" {
  name        = coalesce(var.parameter_group_name, replace(var.cluster_identifier, ".", "-"))
  description = var.parameter_group_description
  family      = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.parameter_group_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(local.tags, var.parameter_group_tags)

  lifecycle {
    enabled = local.enabled && var.create_parameter_group
  }
}

################################################################################
# Subnet Group
################################################################################

resource "aws_redshift_subnet_group" "this" {
  name        = coalesce(var.subnet_group_name, var.cluster_identifier)
  description = var.subnet_group_description
  subnet_ids  = var.subnet_ids

  tags = merge(local.tags, var.subnet_group_tags)

  lifecycle {
    enabled = local.enabled && var.create_subnet_group
  }
}

################################################################################
# Snapshot Schedule
################################################################################

resource "aws_redshift_snapshot_schedule" "this" {
  identifier        = var.use_snapshot_identifier_prefix ? null : var.snapshot_schedule_identifier
  identifier_prefix = var.use_snapshot_identifier_prefix ? "${var.snapshot_schedule_identifier}-" : null
  description       = var.snapshot_schedule_description
  definitions       = var.snapshot_schedule_definitions
  force_destroy     = var.snapshot_schedule_force_destroy

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_snapshot_schedule
  }
}

resource "aws_redshift_snapshot_schedule_association" "this" {
  cluster_identifier  = aws_redshift_cluster.this.id
  schedule_identifier = aws_redshift_snapshot_schedule.this.id

  lifecycle {
    enabled = local.enabled && var.create_snapshot_schedule
  }
}

################################################################################
# Scheduled Action
################################################################################

locals {
  iam_role_name = coalesce(var.iam_role_name, "${var.cluster_identifier}-scheduled-action")
}

resource "aws_redshift_scheduled_action" "this" {
  for_each = { for k, v in var.scheduled_actions : k => v if local.enabled }

  name        = each.value.name
  description = try(each.value.description, null)
  enable      = try(each.value.enable, null)
  start_time  = try(each.value.start_time, null)
  end_time    = try(each.value.end_time, null)
  schedule    = each.value.schedule
  iam_role    = var.create_scheduled_action_iam_role ? aws_iam_role.scheduled_action.arn : each.value.iam_role

  target_action {
    dynamic "pause_cluster" {
      for_each = try([each.value.pause_cluster], [])

      content {
        cluster_identifier = aws_redshift_cluster.this.id
      }
    }

    dynamic "resize_cluster" {
      for_each = try([each.value.resize_cluster], [])

      content {
        classic            = try(resize_cluster.value.classic, null)
        cluster_identifier = aws_redshift_cluster.this.id
        cluster_type       = try(resize_cluster.value.cluster_type, null)
        node_type          = try(resize_cluster.value.node_type, null)
        number_of_nodes    = try(resize_cluster.value.number_of_nodes, null)
      }
    }

    dynamic "resume_cluster" {
      for_each = try([each.value.resume_cluster], [])

      content {
        cluster_identifier = aws_redshift_cluster.this.id
      }
    }
  }
}

data "aws_iam_policy_document" "scheduled_action_assume" {
  count = local.enabled && var.create_scheduled_action_iam_role ? 1 : 0

  statement {
    sid     = "ScheduleActionAssume"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.redshift.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

resource "aws_iam_role" "scheduled_action" {
  name        = var.iam_role_use_name_prefix ? null : local.iam_role_name
  name_prefix = var.iam_role_use_name_prefix ? "${local.iam_role_name}-" : null
  path        = var.iam_role_path
  description = var.iam_role_description

  permissions_boundary  = var.iam_role_permissions_boundary
  force_detach_policies = true
  assume_role_policy    = data.aws_iam_policy_document.scheduled_action_assume[0].json

  tags = merge(local.tags, var.iam_role_tags)

  lifecycle {
    enabled = local.enabled && var.create_scheduled_action_iam_role
  }
}

data "aws_iam_policy_document" "scheduled_action" {
  count = local.enabled && var.create_scheduled_action_iam_role ? 1 : 0

  statement {
    sid = "ModifyCluster"

    actions = [
      "redshift:PauseCluster",
      "redshift:ResumeCluster",
      "redshift:ResizeCluster",
    ]

    resources = [
      aws_redshift_cluster.this.arn
    ]
  }
}

resource "aws_iam_role_policy" "scheduled_action" {
  name   = var.iam_role_name
  role   = aws_iam_role.scheduled_action.name
  policy = data.aws_iam_policy_document.scheduled_action[0].json

  lifecycle {
    enabled = local.enabled && var.create_scheduled_action_iam_role
  }
}

################################################################################
# Endpoint Access
################################################################################

resource "aws_redshift_endpoint_access" "this" {
  cluster_identifier = aws_redshift_cluster.this.id

  endpoint_name          = var.endpoint_name
  resource_owner         = var.endpoint_resource_owner
  subnet_group_name      = coalesce(var.endpoint_subnet_group_name, local.subnet_group_name)
  vpc_security_group_ids = try([aws_security_group.this.id], var.endpoint_vpc_security_group_ids)

  lifecycle {
    enabled = local.enabled && var.create_endpoint_access
  }
}

################################################################################
# Usage Limit
################################################################################

resource "aws_redshift_usage_limit" "this" {
  for_each = { for k, v in var.usage_limits : k => v if local.enabled }

  cluster_identifier = aws_redshift_cluster.this.id

  amount        = each.value.amount
  breach_action = try(each.value.breach_action, null)
  feature_type  = each.value.feature_type
  limit_type    = each.value.limit_type
  period        = try(each.value.period, null)

  tags = merge(local.tags, try(each.value.tags, {}))
}

################################################################################
# Authentication Profile
################################################################################

resource "aws_redshift_authentication_profile" "this" {
  for_each = { for k, v in var.authentication_profiles : k => v if local.enabled }

  authentication_profile_name    = try(each.value.name, each.key)
  authentication_profile_content = jsonencode(each.value.content)
}

################################################################################
# Logging
################################################################################

resource "aws_redshift_logging" "this" {
  cluster_identifier   = aws_redshift_cluster.this.id
  bucket_name          = try(var.logging.bucket_name, null)
  log_destination_type = try(var.logging.log_destination_type, null)
  log_exports          = try(var.logging.log_exports, null)
  s3_key_prefix        = try(var.logging.s3_key_prefix, null)

  lifecycle {
    enabled = local.enabled && length(var.logging) > 0
  }
}

################################################################################
# Snapshot Copy
################################################################################

resource "aws_redshift_snapshot_copy" "this" {
  cluster_identifier               = aws_redshift_cluster.this.id
  destination_region               = var.snapshot_copy.destination_region
  manual_snapshot_retention_period = try(var.snapshot_copy.manual_snapshot_retention_period, null)
  retention_period                 = try(var.snapshot_copy.retention_period, null)
  snapshot_copy_grant_name         = try(var.snapshot_copy.grant_name, null)

  lifecycle {
    enabled = local.enabled && length(var.snapshot_copy) > 0
  }
}

################################################################################
# CloudWatch Log Group
################################################################################

resource "aws_cloudwatch_log_group" "this" {
  for_each = toset([for log in try(var.logging.log_exports, []) : log if local.enabled && var.create_cloudwatch_log_group])

  name              = "/aws/redshift/cluster/${var.cluster_identifier}/${each.value}"
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
  secret_id          = aws_redshift_cluster.this.master_password_secret_arn
  rotate_immediately = var.master_password_rotate_immediately

  rotation_rules {
    automatically_after_days = var.master_password_rotation_automatically_after_days
    duration                 = var.master_password_rotation_duration
    schedule_expression      = var.master_password_rotation_schedule_expression
  }

  lifecycle {
    enabled = local.enabled && var.manage_master_password && var.manage_master_password_rotation
  }
}

################################################################################
# Security Group
################################################################################

locals {
  create_security_group = local.enabled && var.create_security_group
  security_group_name   = try(coalesce(var.security_group_name, var.name), "")
}

resource "aws_security_group" "this" {
  name        = var.security_group_use_name_prefix ? null : local.security_group_name
  name_prefix = var.security_group_use_name_prefix ? "${local.security_group_name}-" : null
  description = var.security_group_description
  vpc_id      = var.vpc_id

  tags = merge(local.tags, var.security_group_tags)

  lifecycle {
    enabled               = local.create_security_group
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = { for k, v in var.security_group_rules : k => v if local.create_security_group && try(v.type, "ingress") == "ingress" }

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
  for_each = { for k, v in var.security_group_rules : k => v if local.create_security_group && try(v.type, "ingress") == "egress" }

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
# OpenTofu Check Blocks
################################################################################

check "encryption_enabled" {
  assert {
    condition     = !var.enabled || aws_redshift_cluster.this.encrypted
    error_message = "Redshift cluster must have encryption at rest enabled."
  }
}

check "logging_enabled" {
  assert {
    condition     = !var.enabled || length(var.logging) > 0
    error_message = "Redshift cluster should have audit logging enabled."
  }
}

################################################################################
