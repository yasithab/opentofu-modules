locals {
  create      = var.enabled
  role_arn    = local.create && var.create_iam_role ? aws_iam_role.this.arn : var.role_arn
  role_name   = coalesce(var.iam_role_name, var.name)
  policy_name = coalesce(var.iam_policy_name, var.name)

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

data "aws_region" "current" {}
data "aws_partition" "current" {}

################################################################################
# RDS Proxy
################################################################################

resource "aws_db_proxy" "this" {
  dynamic "auth" {
    for_each = var.auth

    content {
      auth_scheme               = try(auth.value.auth_scheme, "SECRETS")
      client_password_auth_type = try(auth.value.client_password_auth_type, null)
      description               = try(auth.value.description, null)
      iam_auth                  = try(auth.value.iam_auth, null)
      secret_arn                = try(auth.value.secret_arn, null)
      username                  = try(auth.value.username, null)
    }
  }

  debug_logging                  = var.debug_logging
  default_auth_scheme            = var.default_auth_scheme
  endpoint_network_type          = var.endpoint_network_type
  engine_family                  = var.engine_family
  idle_client_timeout            = var.idle_client_timeout
  name                           = var.name
  require_tls                    = var.require_tls
  role_arn                       = local.role_arn
  target_connection_network_type = var.target_connection_network_type
  vpc_security_group_ids         = var.vpc_security_group_ids
  vpc_subnet_ids                 = var.vpc_subnet_ids

  tags = merge(local.tags, var.proxy_tags)

  timeouts {
    create = try(var.proxy_timeouts.create, null)
    update = try(var.proxy_timeouts.update, null)
    delete = try(var.proxy_timeouts.delete, null)
  }

  depends_on = [aws_cloudwatch_log_group.this]

  lifecycle {
    enabled = local.create
  }
}

resource "aws_db_proxy_default_target_group" "this" {
  db_proxy_name = aws_db_proxy.this.name

  connection_pool_config {
    connection_borrow_timeout    = var.connection_borrow_timeout
    init_query                   = var.init_query
    max_connections_percent      = var.max_connections_percent
    max_idle_connections_percent = var.max_idle_connections_percent
    session_pinning_filters      = var.session_pinning_filters
  }

  lifecycle {
    enabled = local.create
  }
}

resource "aws_db_proxy_target" "db_instance" {
  db_proxy_name          = aws_db_proxy.this.name
  target_group_name      = aws_db_proxy_default_target_group.this.name
  db_instance_identifier = var.db_instance_identifier

  lifecycle {
    enabled = local.create && var.target_db_instance
  }
}

resource "aws_db_proxy_target" "db_cluster" {
  db_proxy_name         = aws_db_proxy.this.name
  target_group_name     = aws_db_proxy_default_target_group.this.name
  db_cluster_identifier = var.db_cluster_identifier

  lifecycle {
    enabled = local.create && var.target_db_cluster
  }
}

resource "aws_db_proxy_endpoint" "this" {
  for_each = { for k, v in var.endpoints : k => v if local.create }

  db_proxy_name          = aws_db_proxy.this.name
  db_proxy_endpoint_name = each.value.name
  vpc_subnet_ids         = each.value.vpc_subnet_ids
  vpc_security_group_ids = lookup(each.value, "vpc_security_group_ids", null)
  target_role            = lookup(each.value, "target_role", null)

  tags = lookup(each.value, "tags", local.tags)
}

################################################################################
# CloudWatch Logs
################################################################################

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/rds/proxy/${var.name}"
  retention_in_days = var.log_group_retention_in_days
  kms_key_id        = var.log_group_kms_key_id
  skip_destroy      = var.log_group_skip_destroy
  log_group_class   = var.log_group_class

  tags = merge(local.tags, var.log_group_tags)

  lifecycle {
    enabled = local.create && var.manage_log_group
  }
}

################################################################################
# IAM Role
################################################################################

data "aws_iam_policy_document" "assume_role" {
  count = local.create && var.create_iam_role ? 1 : 0

  statement {
    sid     = "RDSAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["rds.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name        = var.use_role_name_prefix ? null : local.role_name
  name_prefix = var.use_role_name_prefix ? "${local.role_name}-" : null
  description = var.iam_role_description
  path        = var.iam_role_path

  assume_role_policy    = data.aws_iam_policy_document.assume_role[0].json
  force_detach_policies = var.iam_role_force_detach_policies
  max_session_duration  = var.iam_role_max_session_duration
  permissions_boundary  = var.iam_role_permissions_boundary

  tags = merge(local.tags, var.iam_role_tags)

  lifecycle {
    enabled = local.create && var.create_iam_role
  }
}

data "aws_iam_policy_document" "this" {
  count = local.create && var.create_iam_role && var.create_iam_policy ? 1 : 0

  statement {
    sid     = "DecryptSecrets"
    effect  = "Allow"
    actions = ["kms:Decrypt"]
    resources = coalescelist(
      var.kms_key_arns,
      ["arn:${data.aws_partition.current.partition}:kms:*:*:key/*"]
    )

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = [
        "secretsmanager.${data.aws_region.current.region}.${data.aws_partition.current.dns_suffix}"
      ]
    }
  }

  statement {
    sid    = "ListSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetRandomPassword",
      "secretsmanager:ListSecrets",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "GetSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
    ]

    resources = distinct([for auth in var.auth : auth.secret_arn])
  }
}

resource "aws_iam_role_policy" "this" {
  name        = var.use_policy_name_prefix ? null : local.policy_name
  name_prefix = var.use_policy_name_prefix ? "${local.policy_name}-" : null
  policy      = data.aws_iam_policy_document.this[0].json
  role        = aws_iam_role.this.id

  lifecycle {
    enabled = local.create && var.create_iam_role && var.create_iam_policy
  }
}
