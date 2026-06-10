locals {
  enabled                      = var.enabled
  name                         = var.name != null ? substr(var.name, 0, 64) : null
  name_prefix                  = var.name_prefix != null ? "${var.name_prefix}-" : null
  policy_name                  = var.policy_name != null ? substr(var.policy_name, 0, 64) : null
  policy_name_prefix           = var.policy_name_prefix != null ? "${var.policy_name_prefix}-" : null
  instance_profile_name        = var.instance_profile_name != null ? substr(var.instance_profile_name, 0, 64) : null
  instance_profile_name_prefix = var.instance_profile_name_prefix != null ? "${var.instance_profile_name_prefix}-" : null
  tags = merge(var.tags, { ManagedBy = "opentofu"
  Region = data.aws_region.current.region })

  create_policy = local.enabled && length(var.policy_documents) > 0

  # Normalize principals: each entry may be either a plain list of identifiers
  # (legacy shape) or an object with `identifiers` and optional per-principal `conditions`
  principals = {
    for type, principal in var.principals : type => {
      identifiers = try(tolist(principal.identifiers), tolist(principal))
      conditions  = try(tolist(principal.conditions), [])
    }
  }
}

data "aws_iam_policy_document" "assume_role" {
  for_each = { for type, principal in local.principals : type => principal if local.enabled }

  statement {
    effect  = "Allow"
    actions = var.assume_role_actions

    principals {
      type        = each.key
      identifiers = each.value.identifiers
    }

    # Global conditions apply to every principal statement; per-principal
    # conditions apply only to this principal's statement
    dynamic "condition" {
      for_each = concat(var.assume_role_conditions, each.value.conditions)
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
  override_policy_documents = [for doc in data.aws_iam_policy_document.assume_role : doc.json]
}

resource "aws_iam_role" "default" {
  name                  = local.name
  name_prefix           = local.name_prefix
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
  count                     = local.create_policy ? 1 : 0
  override_policy_documents = var.policy_documents
}

resource "aws_iam_policy" "default" {
  name                              = local.policy_name != null ? local.policy_name : local.name
  name_prefix                       = local.policy_name_prefix != null ? local.policy_name_prefix : local.name_prefix
  description                       = var.policy_description
  policy                            = join("", data.aws_iam_policy_document.default[*].json)
  path                              = var.path
  delay_after_policy_creation_in_ms = var.policy_delay_after_creation_in_ms
  tags                              = var.tags_enabled ? local.tags : null

  lifecycle {
    enabled = local.create_policy
  }
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = try(aws_iam_role.default.name, "")
  policy_arn = try(aws_iam_policy.default.arn, "")

  lifecycle {
    enabled = local.create_policy
  }
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each   = local.enabled ? var.managed_policy_arns : []
  role       = try(aws_iam_role.default.name, "")
  policy_arn = each.key
}

resource "aws_iam_instance_profile" "default" {
  name        = local.instance_profile_name != null ? local.instance_profile_name : local.name
  name_prefix = local.instance_profile_name_prefix != null ? local.instance_profile_name_prefix : local.name_prefix
  role        = try(aws_iam_role.default.name, "")

  lifecycle {
    enabled = local.enabled && var.instance_profile_enabled
  }
}

data "aws_region" "current" {}
