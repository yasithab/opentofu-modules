locals {
  enabled                      = var.enabled
  role_name                    = var.role_name != null ? substr(var.role_name, 0, 64) : null
  role_name_prefix             = var.role_name_prefix != null ? "${coalesce(var.role_name_prefix, "")}-" : null
  policy_name                  = var.policy_name != null ? substr(var.policy_name, 0, 64) : null
  policy_name_prefix           = var.policy_name_prefix != null ? "${coalesce(var.policy_name_prefix, "")}-" : null
  instance_profile_name        = var.instance_profile_name != null ? substr(var.instance_profile_name, 0, 64) : null
  instance_profile_name_prefix = var.instance_profile_name_prefix != null ? "${coalesce(var.instance_profile_name_prefix, "")}-" : null
  tags                         = merge(var.tags, { ManagedBy = "opentofu" })
}

data "aws_iam_policy_document" "assume_role" {
  count = local.enabled ? length(keys(var.principals)) : 0

  statement {
    effect  = "Allow"
    actions = var.assume_role_actions

    principals {
      type        = element(keys(var.principals), count.index)
      identifiers = var.principals[element(keys(var.principals), count.index)]
    }

    dynamic "condition" {
      for_each = var.assume_role_conditions
      content {
        test     = condition.value.test
        variable = condition.value.variable
        values   = condition.value.values
      }
    }
  }
}

data "aws_iam_policy_document" "assume_role_aggregated" {
  count                     = local.enabled ? 1 : 0
  override_policy_documents = data.aws_iam_policy_document.assume_role[*].json
}

resource "aws_iam_role" "default" {
  name                  = local.role_name
  name_prefix           = local.role_name_prefix
  assume_role_policy    = join("", data.aws_iam_policy_document.assume_role_aggregated[*].json)
  description           = var.role_description
  force_detach_policies = var.force_detach_policies
  max_session_duration  = var.max_session_duration
  permissions_boundary  = var.permissions_boundary != null && var.permissions_boundary != "" ? var.permissions_boundary : null
  path                  = var.path
  tags                  = var.tags_enabled ? local.tags : null

  lifecycle {
    enabled = local.enabled
  }
}

data "aws_iam_policy_document" "default" {
  count                     = local.enabled && var.policy_document_count > 0 ? 1 : 0
  override_policy_documents = var.policy_documents
}

resource "aws_iam_policy" "default" {
  name                              = local.policy_name != null ? local.policy_name : local.role_name
  name_prefix                       = local.policy_name_prefix != null ? local.policy_name_prefix : local.role_name_prefix
  description                       = var.policy_description
  policy                            = join("", data.aws_iam_policy_document.default[*].json)
  path                              = var.path
  delay_after_policy_creation_in_ms = var.policy_delay_after_creation_in_ms
  tags                              = var.tags_enabled ? local.tags : null

  lifecycle {
    enabled = local.enabled && var.policy_document_count > 0
  }
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = try(aws_iam_role.default.name, "")
  policy_arn = try(aws_iam_policy.default.arn, "")

  lifecycle {
    enabled = local.enabled && var.policy_document_count > 0
  }
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each   = local.enabled ? var.managed_policy_arns : []
  role       = try(aws_iam_role.default.name, "")
  policy_arn = each.key
}

resource "aws_iam_instance_profile" "default" {
  name        = local.instance_profile_name != null ? local.instance_profile_name : local.role_name
  name_prefix = local.instance_profile_name_prefix != null ? local.instance_profile_name_prefix : local.role_name_prefix
  role        = try(aws_iam_role.default.name, "")

  lifecycle {
    enabled = local.enabled && var.instance_profile_enabled
  }
}
