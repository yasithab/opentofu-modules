locals {
  enabled = var.enabled
  tags    = merge(var.tags, { ManagedBy = "opentofu" })
}

# -----------------------------------------------------------------------------
# IAM Group
# -----------------------------------------------------------------------------

resource "aws_iam_group" "this" {
  name = var.name
  path = var.path

  lifecycle {
    enabled = local.enabled
  }
}

# -----------------------------------------------------------------------------
# Managed Policy Attachments
# -----------------------------------------------------------------------------

resource "aws_iam_group_policy_attachment" "this" {
  for_each   = local.enabled ? var.managed_policy_arns : []
  group      = aws_iam_group.this.name
  policy_arn = each.key
}

# -----------------------------------------------------------------------------
# Inline Policies
# -----------------------------------------------------------------------------

resource "aws_iam_group_policy" "this" {
  for_each = local.enabled ? var.inline_policies : {}
  name     = each.key
  group    = aws_iam_group.this.name
  policy   = each.value
}

# -----------------------------------------------------------------------------
# Group Membership
# -----------------------------------------------------------------------------

resource "aws_iam_group_membership" "this" {
  name  = "${var.name}-membership"
  group = aws_iam_group.this.name
  users = var.users

  lifecycle {
    enabled = local.enabled && length(var.users) > 0
  }
}
