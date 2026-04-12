locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

#####################################################################################
# GitHub OIDC
#####################################################################################

data "aws_iam_openid_connect_provider" "github_oidc" {
  count = var.github_oidc_arn != null ? 1 : 0
  arn   = var.github_oidc_arn
}

#####################################################################################
# GitHub Actions Role Based Access
#####################################################################################

# GitHub role
data "aws_iam_policy_document" "github_actions_oid_assume_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type        = "Federated"
      identifiers = [try(data.aws_iam_openid_connect_provider.github_oidc[0].arn, var.github_oidc_arn)]
    }
    condition {
      test     = length(var.repo_names) == 1 ? "StringLike" : "ForAnyValue:StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for item in var.repo_names : "repo:${var.github_organization_name}/${item}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name                  = var.iam_role_name
  description           = var.iam_role_description
  path                  = var.iam_role_path
  assume_role_policy    = data.aws_iam_policy_document.github_actions_oid_assume_role_policy.json
  max_session_duration  = var.iam_role_max_session_duration
  permissions_boundary  = var.iam_role_permissions_boundary
  force_detach_policies = var.iam_role_force_detach_policies

  tags = merge(local.tags, {
    Name        = var.iam_role_name
    Environment = terraform.workspace
  })

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_iam_role_policy_attachments_exclusive" "github_actions" {
  role_name   = aws_iam_role.github_actions.name
  policy_arns = [aws_iam_policy.github_actions.arn]

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_iam_policy" "github_actions" {
  name                              = var.iam_policy_name != null ? var.iam_policy_name : var.iam_role_name
  path                              = var.iam_policy_path
  description                       = var.iam_policy_description
  policy                            = var.iam_policy_document
  delay_after_policy_creation_in_ms = var.iam_policy_delay_after_creation_in_ms

  tags = merge(local.tags, { Name = var.iam_policy_name != null ? var.iam_policy_name : var.iam_role_name })

  lifecycle {
    enabled = local.enabled
  }
}

#####################################################################################
