locals {
  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# IAM Identity Center Groups
################################################################################

resource "aws_identitystore_group" "sso_groups" {
  for_each          = var.sso_groups == null ? {} : var.sso_groups
  identity_store_id = local.sso_instance_id
  display_name      = each.value.group_name
  description       = each.value.group_description
}

################################################################################
# IAM Identity Center Users
################################################################################

resource "aws_identitystore_user" "sso_users" {
  for_each          = { for key, user in(var.sso_users == null ? {} : var.sso_users) : user.user_name => user }
  identity_store_id = local.sso_instance_id

  # Display name defaults to given_name + family_name when not explicitly set
  display_name = each.value.display_name != null ? each.value.display_name : join(" ", [each.value.given_name, each.value.family_name])

  # Unique identifier for the user (max 128 characters)
  user_name = each.value.user_name

  name {
    given_name       = each.value.given_name
    middle_name      = each.value.middle_name
    family_name      = each.value.family_name
    formatted        = each.value.name_formatted != null ? each.value.name_formatted : join(" ", [each.value.given_name, each.value.family_name])
    honorific_prefix = each.value.honorific_prefix
    honorific_suffix = each.value.honorific_suffix
  }

  # Required: at most 1 email allowed; must be unique across the identity store
  emails {
    value   = each.value.email
    primary = each.value.is_primary_email
    type    = each.value.email_type
  }

  phone_numbers {
    value   = each.value.phone_number
    primary = each.value.is_primary_phone_number
    type    = each.value.phone_number_type
  }

  addresses {
    country        = each.value.country
    locality       = each.value.locality
    formatted      = each.value.address_formatted != null ? each.value.address_formatted : join(" ", [lookup(each.value, "street_address", ""), lookup(each.value, "locality", ""), lookup(each.value, "region", ""), lookup(each.value, "postal_code", ""), lookup(each.value, "country", "")])
    postal_code    = each.value.postal_code
    primary        = each.value.is_primary_address
    region         = each.value.region
    street_address = each.value.street_address
    type           = each.value.address_type
  }

  user_type          = each.value.user_type
  title              = each.value.title
  locale             = each.value.locale
  nickname           = each.value.nickname
  preferred_language = each.value.preferred_language
  profile_url        = each.value.profile_url
  timezone           = each.value.timezone
}

################################################################################
# Group Membership - New Users with New Groups
################################################################################

resource "aws_identitystore_group_membership" "sso_group_membership" {
  for_each          = local.users_and_their_groups
  identity_store_id = local.sso_instance_id

  group_id  = contains(local.this_groups, each.value.group_name) ? aws_identitystore_group.sso_groups[each.value.group_name].group_id : data.aws_identitystore_group.existing_sso_groups[each.value.group_name].group_id
  member_id = contains(local.this_users, each.value.user_name) ? aws_identitystore_user.sso_users[each.value.user_name].user_id : data.aws_identitystore_user.existing_sso_users[each.value.user_name].user_id
}

# Group Membership - Existing Google SSO Users with New Groups
resource "aws_identitystore_group_membership" "sso_group_membership_existing_google_sso_users" {
  for_each          = local.users_and_their_groups_existing_google_sso_users
  identity_store_id = local.sso_instance_id

  group_id  = contains(local.this_groups, each.value.group_name) ? aws_identitystore_group.sso_groups[each.value.group_name].group_id : data.aws_identitystore_group.existing_sso_groups[each.value.group_name].group_id
  member_id = data.aws_identitystore_user.existing_google_sso_users[each.value.user_name].user_id
}

################################################################################
# Permission Sets
################################################################################

resource "aws_ssoadmin_permission_set" "pset" {
  for_each = var.permission_sets
  name     = each.key

  instance_arn     = local.ssoadmin_instance_arn
  description      = lookup(each.value, "description", null)
  relay_state      = lookup(each.value, "relay_state", null)
  session_duration = lookup(each.value, "session_duration", null)
  tags             = lookup(each.value, "tags", {})
}

################################################################################
# Policy Attachments
################################################################################

# AWS Managed Policy Attachment
resource "aws_ssoadmin_managed_policy_attachment" "pset_aws_managed_policy" {
  for_each = { for pset in local.pset_aws_managed_policy_maps : "${pset.pset_name}.${pset.policy_arn}" => pset }

  instance_arn       = local.ssoadmin_instance_arn
  managed_policy_arn = each.value.policy_arn
  permission_set_arn = aws_ssoadmin_permission_set.pset[each.value.pset_name].arn

  depends_on = [aws_ssoadmin_account_assignment.account_assignment]
}

# Customer Managed Policy Attachment
resource "aws_ssoadmin_customer_managed_policy_attachment" "pset_customer_managed_policy" {
  for_each = { for pset in local.pset_customer_managed_policy_maps : "${pset.pset_name}.${pset.policy_name}" => pset }

  instance_arn       = local.ssoadmin_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.pset[each.value.pset_name].arn
  customer_managed_policy_reference {
    name = each.value.policy_name
    path = "/"
  }
}

# Inline Policy
resource "aws_ssoadmin_permission_set_inline_policy" "pset_inline_policy" {
  for_each = { for pset in local.pset_inline_policy_maps : pset.pset_name => pset if can(pset.inline_policy) }

  inline_policy      = each.value.inline_policy
  instance_arn       = local.ssoadmin_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.pset[each.key].arn
}

################################################################################
# Permissions Boundaries
################################################################################

resource "aws_ssoadmin_permissions_boundary_attachment" "pset_permissions_boundary_aws_managed" {
  for_each = { for pset in local.pset_permissions_boundary_aws_managed_maps : pset.pset_name => pset if can(pset.boundary.managed_policy_arn) }

  instance_arn       = local.ssoadmin_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.pset[each.key].arn
  permissions_boundary {
    managed_policy_arn = each.value.boundary.managed_policy_arn
  }
}

resource "aws_ssoadmin_permissions_boundary_attachment" "pset_permissions_boundary_customer_managed" {
  for_each = { for pset in local.pset_permissions_boundary_customer_managed_maps : pset.pset_name => pset if can(pset.boundary.customer_managed_policy_reference) }

  instance_arn       = local.ssoadmin_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.pset[each.key].arn
  permissions_boundary {
    customer_managed_policy_reference {
      name = each.value.boundary.customer_managed_policy_reference.name
      path = can(each.value.boundary.customer_managed_policy_reference.path) ? each.value.boundary.customer_managed_policy_reference.path : "/"
    }
  }
}

################################################################################
# Account Assignments
################################################################################

resource "aws_ssoadmin_account_assignment" "account_assignment" {
  # for_each argument must be a map or set of strings
  for_each = local.principals_and_their_account_assignments

  instance_arn       = local.ssoadmin_instance_arn
  permission_set_arn = contains(local.this_permission_sets, each.value.permission_set) ? aws_ssoadmin_permission_set.pset[each.value.permission_set].arn : data.aws_ssoadmin_permission_set.existing_permission_sets[each.value.permission_set].arn

  principal_type = each.value.principal_type

  # Conditional principal_id based on principal_type and principal_idp:
  # - INTERNAL: principal created by this module
  # - EXTERNAL: principal synced from external IdP (EntraID, Okta, Google, etc.) via SCIM
  principal_id = (
    each.value.principal_type == "GROUP" && each.value.principal_idp == "INTERNAL" ? aws_identitystore_group.sso_groups[each.value.principal_name].group_id :
    each.value.principal_type == "USER" && each.value.principal_idp == "INTERNAL" ? aws_identitystore_user.sso_users[each.value.principal_name].user_id :
    each.value.principal_type == "GROUP" && each.value.principal_idp == "EXTERNAL" ? data.aws_identitystore_group.existing_sso_groups[each.value.principal_name].group_id :
    each.value.principal_type == "USER" && each.value.principal_idp == "EXTERNAL" ? data.aws_identitystore_user.existing_sso_users[each.value.principal_name].user_id :
    each.value.principal_type == "USER" && each.value.principal_idp == "GOOGLE" ? data.aws_identitystore_user.existing_google_sso_users[each.value.principal_name].user_id :
    null
  )

  target_id   = each.value.account_id
  target_type = "AWS_ACCOUNT"
}

################################################################################
# SSO Applications
################################################################################

resource "aws_ssoadmin_application" "sso_apps" {
  for_each                 = var.sso_applications == null ? {} : var.sso_applications
  name                     = each.value.name
  instance_arn             = local.ssoadmin_instance_arn
  application_provider_arn = each.value.application_provider_arn
  client_token             = each.value.client_token
  description              = each.value.description
  status                   = each.value.status
  tags                     = each.value.tags

  dynamic "portal_options" {
    for_each = each.value.portal_options != null ? [each.value.portal_options] : []
    content {
      visibility = portal_options.value.visibility
      dynamic "sign_in_options" {
        for_each = try(portal_options.value.sign_in_options, null) != null ? [portal_options.value.sign_in_options] : []
        content {
          application_url = try(sign_in_options.value.application_url, null)
          origin          = sign_in_options.value.origin
        }
      }
    }
  }
}

# Application Assignment Configuration
resource "aws_ssoadmin_application_assignment_configuration" "sso_apps_assignments_configs" {
  for_each = {
    for idx, assignment_config in local.apps_assignments_configs :
    "${assignment_config.app_name}-assignment-config" => assignment_config
  }
  application_arn     = aws_ssoadmin_application.sso_apps[each.value.app_name].application_arn
  assignment_required = each.value.assignment_required
}

# Application Access Scope
resource "aws_ssoadmin_application_access_scope" "sso_apps_assignments_access_scope" {
  for_each = {
    for idx, app_access_scope in local.apps_assignments_access_scopes :
    "${app_access_scope.app_name}-${app_access_scope.scope}" => app_access_scope
  }
  application_arn = aws_ssoadmin_application.sso_apps[each.value.app_name].application_arn
  authorized_targets = [
    for target in each.value.authorized_targets : aws_ssoadmin_application.sso_apps[target].application_arn
  ]
  scope = each.value.scope
}

# Application Group Assignments
resource "aws_ssoadmin_application_assignment" "sso_apps_groups_assignments" {
  for_each = {
    for idx, assignment in local.apps_groups_assignments :
    "${assignment.app_name}-${assignment.group_name}" => assignment
  }
  application_arn = aws_ssoadmin_application.sso_apps[each.value.app_name].application_arn
  principal_id    = contains(local.this_groups, each.value.group_name) ? aws_identitystore_group.sso_groups[each.value.group_name].group_id : data.aws_identitystore_group.existing_sso_groups[each.value.group_name].group_id
  principal_type  = each.value.principal_type
}

# Application User Assignments
resource "aws_ssoadmin_application_assignment" "sso_apps_users_assignments" {
  for_each = {
    for idx, assignment in local.apps_users_assignments :
    "${assignment.app_name}-${assignment.user_name}" => assignment
  }
  application_arn = aws_ssoadmin_application.sso_apps[each.value.app_name].application_arn
  principal_id    = contains(local.this_users, each.value.user_name) ? aws_identitystore_user.sso_users[each.value.user_name].user_id : data.aws_identitystore_user.existing_sso_users[each.value.user_name].user_id
  principal_type  = each.value.principal_type
}

################################################################################
# Trusted Token Issuers
################################################################################

resource "aws_ssoadmin_trusted_token_issuer" "this" {
  for_each = var.trusted_token_issuers == null ? {} : var.trusted_token_issuers

  name                      = each.value.name
  instance_arn              = local.ssoadmin_instance_arn
  trusted_token_issuer_type = each.value.trusted_token_issuer_type
  tags                      = each.value.tags

  dynamic "trusted_token_issuer_configuration" {
    for_each = each.value.oidc_jwt_configuration != null ? [each.value.oidc_jwt_configuration] : []
    content {
      oidc_jwt_configuration {
        claim_attribute_path          = trusted_token_issuer_configuration.value.claim_attribute_path
        identity_store_attribute_path = trusted_token_issuer_configuration.value.identity_store_attribute_path
        issuer_url                    = trusted_token_issuer_configuration.value.issuer_url
        jwks_retrieval_option         = trusted_token_issuer_configuration.value.jwks_retrieval_option
      }
    }
  }
}

################################################################################
# SSO Instance Access Control Attributes
################################################################################

resource "aws_ssoadmin_instance_access_control_attributes" "sso_access_control_attributes" {
  count        = length(var.sso_instance_access_control_attributes) <= 0 ? 0 : 1
  instance_arn = local.ssoadmin_instance_arn
  dynamic "attribute" {
    for_each = var.sso_instance_access_control_attributes
    content {
      key = attribute.value.attribute_name
      value {
        source = attribute.value.source
      }
    }
  }
}
