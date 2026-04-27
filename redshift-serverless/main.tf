locals {
  enabled            = var.enabled
  is_serverless      = var.engine_mode == "serverless"
  has_policy_arn     = try(nonsensitive(var.policy_arn != null), var.policy_arn != null)
  create_role_policy = nonsensitive(local.enabled && local.is_serverless && var.policy_enabled && var.iam_role_enabled && !local.has_policy_arn)
  attach_role_policy = nonsensitive(local.enabled && local.is_serverless && var.policy_enabled && var.iam_role_enabled && local.has_policy_arn)
  admin_password     = local.enabled && !var.manage_admin_password ? (var.create_random_password ? random_password.master_password.result : var.admin_password) : null
  port               = var.port

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

###############################################################################################################
# Base configurations
###############################################################################################################


resource "random_password" "master_password" {
  length           = var.random_password_length
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"

  lifecycle {
    enabled = local.enabled && !var.manage_admin_password && var.create_random_password
  }
}

###############################################################################################################
# RedShift Serverless
###############################################################################################################

resource "aws_iam_role" "serverless" {
  name = var.iam_role_name
  assume_role_policy = coalesce(var.assume_role_policy, jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "redshift.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  }))

  tags = local.tags

  lifecycle {
    enabled = local.enabled && local.is_serverless && var.iam_role_enabled
  }
}

resource "aws_iam_role_policy" "serverless" {
  name   = var.policy_name != null ? var.policy_name : format("%s-policy", var.iam_role_name)
  role   = aws_iam_role.serverless.id
  policy = coalesce(var.policy, "{}")

  lifecycle {
    enabled = local.create_role_policy
  }
}

resource "aws_iam_role_policy_attachment" "serverless" {
  role       = aws_iam_role.serverless.id
  policy_arn = var.policy_arn

  lifecycle {
    enabled = local.attach_role_policy
  }
}

resource "aws_iam_role_policy_attachment" "serverless_managed" {
  for_each   = toset(var.managed_policy_arns)
  role       = aws_iam_role.serverless.id
  policy_arn = each.value
}

resource "aws_kms_key" "serverless" {
  deletion_window_in_days = 10
  key_usage               = "ENCRYPT_DECRYPT"

  tags = local.tags

  lifecycle {
    enabled = local.enabled && local.is_serverless && var.kms_enabled
  }
}

resource "aws_kms_alias" "serverless" {
  name          = var.kms_alias
  target_key_id = try(aws_kms_key.serverless.key_id, "")

  lifecycle {
    enabled = local.enabled && local.is_serverless && var.kms_enabled
  }
}

resource "aws_redshiftserverless_namespace" "this" {
  namespace_name                   = var.namespace_name
  admin_username                   = var.admin_username
  manage_admin_password            = var.manage_admin_password ? var.manage_admin_password : null
  admin_password_secret_kms_key_id = var.manage_admin_password ? var.admin_password_secret_kms_key_id : null
  admin_user_password              = !var.manage_admin_password && !var.use_admin_password_wo ? local.admin_password : null
  admin_user_password_wo           = !var.manage_admin_password && var.use_admin_password_wo ? local.admin_password : null
  admin_user_password_wo_version   = !var.manage_admin_password && var.use_admin_password_wo ? var.admin_user_password_wo_version : null
  db_name                          = var.db_name
  default_iam_role_arn             = var.iam_role_enabled ? try(aws_iam_role.serverless.arn, "") : ""
  iam_roles                        = var.iam_role_enabled ? [try(aws_iam_role.serverless.arn, "")] : []
  kms_key_id                       = var.kms_enabled == true ? try(aws_kms_key.serverless.arn, "") : var.kms_key_arn
  log_exports                      = var.log_exports

  tags = local.tags

  lifecycle {
    enabled = local.enabled && local.is_serverless
  }
}

resource "aws_redshiftserverless_workgroup" "this" {
  namespace_name       = try(aws_redshiftserverless_namespace.this.id, "")
  workgroup_name       = var.workgroup_name
  base_capacity        = var.workgroup_base_capacity
  max_capacity         = var.workgroup_max_capacity
  enhanced_vpc_routing = var.workgroup_enhanced_vpc_routing
  port                 = var.workgroup_port
  publicly_accessible  = var.publicly_accessible
  security_group_ids   = [aws_security_group.this.id]
  subnet_ids           = var.subnet_ids
  track_name           = var.workgroup_track_name

  dynamic "config_parameter" {
    for_each = length(var.workgroup_config_parameter) > 0 ? var.workgroup_config_parameter : []
    content {
      parameter_key   = config_parameter.value.parameter_key
      parameter_value = config_parameter.value.parameter_value
    }
  }

  dynamic "price_performance_target" {
    for_each = var.workgroup_price_performance_target != null ? [var.workgroup_price_performance_target] : []
    content {
      enabled = try(price_performance_target.value.enabled, false)
      level   = try(price_performance_target.value.level, null)
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled && local.is_serverless
  }
}

resource "aws_redshiftserverless_usage_limit" "this" {
  resource_arn  = try(aws_redshiftserverless_workgroup.this.arn, "")
  usage_type    = var.usage_type
  amount        = var.usage_amount
  breach_action = var.usage_breach_action
  period        = var.usage_period

  lifecycle {
    enabled = local.enabled && local.is_serverless && var.usage_limit_enabled
  }
}

resource "time_sleep" "this" {
  depends_on      = [aws_redshiftserverless_workgroup.this]
  create_duration = "60s"
}

resource "aws_redshiftserverless_endpoint_access" "this" {
  depends_on             = [aws_redshiftserverless_workgroup.this, time_sleep.this]
  endpoint_name          = var.endpoint_name
  owner_account          = var.endpoint_owner_account
  workgroup_name         = try(aws_redshiftserverless_workgroup.this.id, "")
  vpc_security_group_ids = concat([aws_security_group.this.id], var.endpoint_security_group_ids)
  subnet_ids             = var.subnet_ids

  lifecycle {
    enabled = local.enabled && local.is_serverless && var.endpoint_enabled
  }
}

resource "aws_redshiftserverless_snapshot" "this" {
  namespace_name   = try(aws_redshiftserverless_workgroup.this.namespace_name, "")
  snapshot_name    = var.snapshot_name
  retention_period = var.snapshot_retention_period

  lifecycle {
    enabled = local.enabled && local.is_serverless && var.snapshot_enabled
  }
}

resource "aws_redshiftserverless_resource_policy" "this" {
  resource_arn = try(aws_redshiftserverless_snapshot.this.arn, "")
  policy       = var.snapshot_policy

  lifecycle {
    enabled = local.enabled && local.is_serverless && var.snapshot_policy_enabled
  }
}

resource "aws_redshiftserverless_custom_domain_association" "this" {
  depends_on                    = [aws_redshiftserverless_workgroup.this, time_sleep.this]
  workgroup_name                = try(aws_redshiftserverless_workgroup.this.id, "")
  custom_domain_name            = var.custom_domain_name
  custom_domain_certificate_arn = var.custom_domain_certificate_arn

  lifecycle {
    enabled = local.enabled && local.is_serverless && var.custom_domain_enabled
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

check "namespace_encryption_enabled" {
  assert {
    condition     = !var.enabled || try(aws_redshiftserverless_namespace.this.kms_key_id, "") != ""
    error_message = "Redshift Serverless namespace should use a customer-managed KMS key for encryption."
  }
}

################################################################################
