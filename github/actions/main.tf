locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
    Region    = data.aws_region.current.region
  })

  # Subject claim suffixes. Constrain via github_ref and/or github_environment;
  # when neither is set, any ref/environment of the listed repositories may assume
  # the role (the historical breadth of this module).
  github_sub_suffixes = concat(
    var.github_ref != null ? ["ref:${var.github_ref}"] : [],
    var.github_environment != null ? ["environment:${var.github_environment}"] : [],
  )

  github_sub_values = flatten([
    for repo in var.repo_names : [
      for suffix in coalescelist(local.github_sub_suffixes, ["*"]) :
      "repo:${var.github_organization_name}/${repo}:${suffix}"
    ]
  ])
}

#####################################################################################
# GitHub OIDC
#####################################################################################

data "aws_iam_openid_connect_provider" "github_oidc" {
  count = var.enabled ? 1 : 0
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

    # Require tokens to be issued for STS - without this, any GitHub OIDC token
    # (e.g. issued for a different audience) from a matching repo could assume the role
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # sub is a single-valued claim; plain StringLike is the correct operator
    # (set operators like ForAnyValue:StringLike match differently and can be bypassed
    # on absent claims with some operators)
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.github_sub_values
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
    Name = var.iam_role_name
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

data "aws_region" "current" {}
