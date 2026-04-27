locals {
  enabled = var.enabled
  name    = var.name
  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  create_role = local.enabled && var.create_role
  role_name   = coalesce(var.role_name, local.name)
  role_arn    = local.create_role ? aws_iam_role.this.arn : var.existing_role_arn
}


################################################################################
# IAM Role - EKS Pod Identity Trust Policy
################################################################################

data "aws_iam_policy_document" "trust" {
  statement {
    sid     = "EKSPodIdentityTrust"
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }

  dynamic "statement" {
    for_each = var.additional_trust_policy_statements

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

resource "aws_iam_role" "this" {
  name                 = local.role_name
  path                 = var.role_path
  description          = var.role_description
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  permissions_boundary = var.role_permissions_boundary_arn
  max_session_duration = var.role_max_session_duration

  tags = local.tags

  lifecycle {
    enabled = local.create_role
  }
}

################################################################################
# Managed Policy Attachments
################################################################################

resource "aws_iam_role_policy_attachment" "this" {
  for_each = { for idx, arn in var.managed_policy_arns : idx => arn if local.create_role }

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

################################################################################
# Inline Policies
################################################################################

resource "aws_iam_role_policy" "this" {
  for_each = { for k, v in var.inline_policies : k => v if local.create_role }

  name   = each.key
  role   = aws_iam_role.this.name
  policy = each.value
}

################################################################################
# Pod Identity Association
################################################################################

resource "aws_eks_pod_identity_association" "this" {
  for_each = { for k, v in var.associations : k => v if local.enabled }

  cluster_name    = var.cluster_name
  namespace       = each.value.namespace
  service_account = each.value.service_account
  role_arn        = local.role_arn

  tags = local.tags
}
