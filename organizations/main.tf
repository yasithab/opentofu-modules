locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  # Separate root-level OUs from child OUs for ordered creation
  root_ous = {
    for k, v in var.organizational_units : k => v
    if v.parent_key == null && local.enabled
  }

  child_ous = {
    for k, v in var.organizational_units : k => v
    if v.parent_key != null && local.enabled
  }

  # Build a map of OU key -> OU ID for parent resolution (only root OUs, child OUs reference root directly)
  ou_ids = { for k, v in aws_organizations_organizational_unit.root : k => v.id }

  # Build policy attachment flattened map: policy_key/target_key -> { policy_id, target_id }
  policy_attachments = merge([
    for policy_key, policy in var.policies : {
      for target_key in try(policy.target_keys, []) : "${policy_key}/${target_key}" => {
        policy_id = aws_organizations_policy.this[policy_key].id
        target_id = (
          target_key == "__root__"
          ? try(aws_organizations_organization.this.roots[0].id, "")
          : try(
            local.ou_ids[target_key],
            try(aws_organizations_account.this[target_key].id, ""),
          )
        )
      }
    }
  ]...)
}

################################################################################
# Organization
################################################################################

resource "aws_organizations_organization" "this" {
  lifecycle {
    enabled = local.enabled
  }

  feature_set                   = var.feature_set
  aws_service_access_principals = var.aws_service_access_principals
  enabled_policy_types          = var.enabled_policy_types
}

################################################################################
# Organizational Units - Root Level
################################################################################

resource "aws_organizations_organizational_unit" "root" {
  for_each = local.root_ous

  name      = each.value.name
  parent_id = try(aws_organizations_organization.this.roots[0].id, "")

  tags = merge(local.tags, each.value.tags)
}

################################################################################
# Organizational Units - Child Level
################################################################################

resource "aws_organizations_organizational_unit" "child" {
  for_each = local.child_ous

  name      = each.value.name
  parent_id = try(aws_organizations_organizational_unit.root[each.value.parent_key].id, aws_organizations_organization.this.roots[0].id, "")

  tags = merge(local.tags, each.value.tags)

  depends_on = [aws_organizations_organizational_unit.root]
}

################################################################################
# Accounts
################################################################################

resource "aws_organizations_account" "this" {
  for_each = {
    for k, v in var.accounts : k => v
    if local.enabled
  }

  name      = each.value.name
  email     = each.value.email
  parent_id = try(local.ou_ids[each.value.parent_key], aws_organizations_organization.this.roots[0].id, "")

  iam_user_access_to_billing = each.value.iam_user_access_to_billing
  role_name                  = each.value.role_name
  close_on_deletion          = each.value.close_on_deletion

  tags = merge(local.tags, each.value.tags)

  depends_on = [
    aws_organizations_organizational_unit.root,
    aws_organizations_organizational_unit.child,
  ]

  lifecycle {
    ignore_changes = [
      # Email and role_name cannot be changed after account creation
      email,
      role_name,
      iam_user_access_to_billing,
    ]
  }
}

################################################################################
# Policies
################################################################################

resource "aws_organizations_policy" "this" {
  for_each = {
    for k, v in var.policies : k => v
    if local.enabled
  }

  name        = each.value.name
  description = each.value.description
  type        = each.value.type
  content     = each.value.content

  tags = merge(local.tags, each.value.tags)
}

################################################################################
# Policy Attachments
################################################################################

resource "aws_organizations_policy_attachment" "this" {
  for_each = {
    for k, v in local.policy_attachments : k => v
    if local.enabled
  }

  policy_id = each.value.policy_id
  target_id = each.value.target_id
}

################################################################################
# Delegated Administrators
################################################################################

resource "aws_organizations_delegated_administrator" "this" {
  for_each = {
    for k, v in var.delegated_administrators : k => v
    if local.enabled
  }

  account_id        = each.value.account_id
  service_principal = each.value.service_principal

  depends_on = [aws_organizations_organization.this]
}

################################################################################
# Resource Policy
################################################################################

resource "aws_organizations_resource_policy" "this" {
  lifecycle {
    enabled = local.enabled && var.resource_policy != null
  }

  content = try(var.resource_policy, "{}")

  tags = local.tags
}
