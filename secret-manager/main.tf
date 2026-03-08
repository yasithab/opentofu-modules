locals {
  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# Secret
################################################################################

resource "aws_secretsmanager_secret" "this" {
  description                    = var.description
  force_overwrite_replica_secret = var.force_overwrite_replica_secret
  kms_key_id                     = var.kms_key_id
  name                           = var.name
  name_prefix                    = var.name_prefix
  policy                         = var.secret_resource_policy
  recovery_window_in_days        = var.recovery_window_in_days

  dynamic "replica" {
    for_each = var.replica

    content {
      kms_key_id = try(replica.value.kms_key_id, null)
      region     = try(replica.value.region, replica.key)
    }
  }

  tags = local.tags

  lifecycle {
    enabled = var.enabled
  }
}

################################################################################
# Policy
################################################################################

data "aws_iam_policy_document" "this" {
  count = var.enabled && var.create_policy ? 1 : 0

  source_policy_documents   = var.source_policy_documents
  override_policy_documents = var.override_policy_documents

  dynamic "statement" {
    for_each = var.policy_statements

    content {
      sid           = try(statement.value.sid, null)
      actions       = try(statement.value.actions, null)
      not_actions   = try(statement.value.not_actions, null)
      effect        = try(statement.value.effect, null)
      resources     = try(statement.value.resources, null)
      not_resources = try(statement.value.not_resources, null)

      dynamic "principals" {
        for_each = try(statement.value.principals, [])

        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "not_principals" {
        for_each = try(statement.value.not_principals, [])

        content {
          type        = not_principals.value.type
          identifiers = not_principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = try(statement.value.conditions, [])

        content {
          test     = condition.value.test
          values   = condition.value.values
          variable = condition.value.variable
        }
      }
    }
  }
}

resource "aws_secretsmanager_secret_policy" "this" {
  secret_arn          = aws_secretsmanager_secret.this.arn
  policy              = data.aws_iam_policy_document.this[0].json
  block_public_policy = var.block_public_policy

  lifecycle {
    enabled = var.enabled && var.create_policy
  }
}

################################################################################
# Version
################################################################################

resource "aws_secretsmanager_secret_version" "this" {
  secret_id                = aws_secretsmanager_secret.this.id
  secret_string            = var.create_random_password ? random_password.this.result : var.secret_string
  secret_string_wo         = var.secret_string_wo
  secret_string_wo_version = var.secret_string_wo_version
  secret_binary            = var.secret_binary
  version_stages           = var.version_stages

  lifecycle {
    enabled = var.enabled && !(var.enable_rotation || var.ignore_secret_changes)
  }
}

resource "aws_secretsmanager_secret_version" "ignore_changes" {
  secret_id                = aws_secretsmanager_secret.this.id
  version_stages           = var.version_stages
  secret_binary            = var.secret_binary
  secret_string_wo         = var.secret_string_wo
  secret_string_wo_version = var.secret_string_wo_version
  secret_string = coalesce(
    var.secret_string,
    var.create_random_password ? random_password.this.result : "default"
  )

  lifecycle {
    enabled = var.enabled && (var.enable_rotation || var.ignore_secret_changes)
    ignore_changes = [
      secret_string,
      secret_binary,
      version_stages,
    ]
  }
}

resource "random_password" "this" {
  length           = var.random_password_length
  special          = true
  override_special = var.random_password_override_special

  lifecycle {
    enabled = var.enabled && var.create_random_password
  }
}

################################################################################
# Rotation
################################################################################

resource "aws_secretsmanager_secret_rotation" "this" {
  rotation_lambda_arn = var.rotation_lambda_arn
  rotate_immediately  = var.rotate_immediately

  dynamic "rotation_rules" {
    for_each = [var.rotation_rules]

    content {
      automatically_after_days = try(rotation_rules.value.automatically_after_days, null)
      duration                 = try(rotation_rules.value.duration, null)
      schedule_expression      = try(rotation_rules.value.schedule_expression, null)
    }
  }

  secret_id = aws_secretsmanager_secret.this.id

  lifecycle {
    enabled = var.enabled && var.enable_rotation
  }
}
