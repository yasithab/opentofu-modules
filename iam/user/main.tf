locals {
  enabled = var.enabled
  tags    = merge(var.tags, { ManagedBy = "opentofu" })
}

# -----------------------------------------------------------------------------
# IAM User
# -----------------------------------------------------------------------------

resource "aws_iam_user" "this" {
  name                 = var.name
  path                 = var.path
  permissions_boundary = var.permissions_boundary
  force_destroy        = var.force_destroy
  tags                 = local.tags

  lifecycle {
    enabled = local.enabled
  }
}

# -----------------------------------------------------------------------------
# Login Profile (Console Access)
# -----------------------------------------------------------------------------

resource "aws_iam_user_login_profile" "this" {
  user                    = aws_iam_user.this.name
  password_length         = var.password_length
  password_reset_required = var.password_reset_required
  pgp_key                 = var.pgp_key

  lifecycle {
    enabled = local.enabled && var.create_login_profile
  }
}

# -----------------------------------------------------------------------------
# Access Key (Programmatic Access)
# -----------------------------------------------------------------------------

resource "aws_iam_access_key" "this" {
  user    = aws_iam_user.this.name
  pgp_key = var.pgp_key
  status  = var.access_key_status

  lifecycle {
    enabled = local.enabled && var.create_access_key
  }
}

# -----------------------------------------------------------------------------
# Managed Policy Attachments
# -----------------------------------------------------------------------------

resource "aws_iam_user_policy_attachment" "this" {
  for_each   = local.enabled ? var.managed_policy_arns : []
  user       = aws_iam_user.this.name
  policy_arn = each.key
}

# -----------------------------------------------------------------------------
# Inline Policies
# -----------------------------------------------------------------------------

resource "aws_iam_user_policy" "this" {
  for_each = local.enabled ? var.inline_policies : {}
  name     = each.key
  user     = aws_iam_user.this.name
  policy   = each.value
}

# -----------------------------------------------------------------------------
# Group Membership
# -----------------------------------------------------------------------------

resource "aws_iam_user_group_membership" "this" {
  user   = aws_iam_user.this.name
  groups = var.groups

  lifecycle {
    enabled = local.enabled && length(var.groups) > 0
  }
}

# -----------------------------------------------------------------------------
# SSH Public Key (CodeCommit)
# -----------------------------------------------------------------------------

resource "aws_iam_user_ssh_key" "this" {
  username   = aws_iam_user.this.name
  encoding   = var.ssh_key_encoding
  public_key = try(var.ssh_public_key, "")
  status     = var.ssh_key_status

  lifecycle {
    enabled = local.enabled && var.ssh_public_key != null
  }
}

# -----------------------------------------------------------------------------
# Virtual MFA Device
# -----------------------------------------------------------------------------

resource "aws_iam_virtual_mfa_device" "this" {
  virtual_mfa_device_name = var.name
  path                    = var.virtual_mfa_device_path
  tags                    = local.tags

  lifecycle {
    enabled = local.enabled && var.create_virtual_mfa_device
  }
}
