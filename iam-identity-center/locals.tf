################################################################################
# Users and Groups
################################################################################

locals {
  # Flatten sso_users into individual user-group membership records
  flatten_user_data = flatten([
    for this_user in keys(var.sso_users) : [
      for group in var.sso_users[this_user].group_membership : {
        user_name  = var.sso_users[this_user].user_name
        group_name = group
      }
    ]
  ])

  users_and_their_groups = {
    for s in local.flatten_user_data : format("%s_%s", s.user_name, s.group_name) => s
  }

  # Flatten existing_google_sso_users into individual user-group membership records
  flatten_user_data_existing_google_sso_users = flatten([
    for this_existing_google_user in keys(var.existing_google_sso_users) : [
      for group in coalesce(var.existing_google_sso_users[this_existing_google_user].group_membership, []) : {
        user_name  = var.existing_google_sso_users[this_existing_google_user].user_name
        group_name = group
      }
    ]
  ])

  users_and_their_groups_existing_google_sso_users = {
    for s in local.flatten_user_data_existing_google_sso_users : format("%s_%s", s.user_name, s.group_name) => s
  }
}

################################################################################
# Permission Sets and Policies
################################################################################

locals {
  # Fetch SSO Instance ARN and Identity Store ID
  ssoadmin_instance_arn = tolist(data.aws_ssoadmin_instances.sso_instance.arns)[0]
  sso_instance_id       = tolist(data.aws_ssoadmin_instances.sso_instance.identity_store_ids)[0]

  # Filter permission sets by attached policy types
  aws_managed_permission_sets                           = { for pset_name, pset_index in var.permission_sets : pset_name => pset_index if can(pset_index.aws_managed_policies) }
  customer_managed_permission_sets                      = { for pset_name, pset_index in var.permission_sets : pset_name => pset_index if can(pset_index.customer_managed_policies) }
  inline_policy_permission_sets                         = { for pset_name, pset_index in var.permission_sets : pset_name => pset_index if can(pset_index.inline_policy) && try(pset_index.inline_policy, "") != "" }
  permissions_boundary_aws_managed_permission_sets      = { for pset_name, pset_index in var.permission_sets : pset_name => pset_index if can(pset_index.permissions_boundary.managed_policy_arn) }
  permissions_boundary_customer_managed_permission_sets = { for pset_name, pset_index in var.permission_sets : pset_name => pset_index if can(pset_index.permissions_boundary.customer_managed_policy_reference) }

  # AWS Managed Policy maps - flat list of pset_name + policy_arn pairs
  pset_aws_managed_policy_maps = flatten([
    for pset_name, pset_index in local.aws_managed_permission_sets : [
      for policy in pset_index.aws_managed_policies : {
        pset_name  = pset_name
        policy_arn = policy
      } if pset_index.aws_managed_policies != null && can(pset_index.aws_managed_policies)
    ]
  ])

  # Customer Managed Policy maps - flat list of pset_name + policy_name pairs
  pset_customer_managed_policy_maps = flatten([
    for pset_name, pset_index in local.customer_managed_permission_sets : [
      for policy in pset_index.customer_managed_policies : {
        pset_name   = pset_name
        policy_name = policy
      } if pset_index.customer_managed_policies != null && can(pset_index.customer_managed_policies)
    ]
  ])

  # Inline Policy maps
  pset_inline_policy_maps = flatten([
    for pset_name, pset_index in local.inline_policy_permission_sets : [
      {
        pset_name     = pset_name
        inline_policy = pset_index.inline_policy
      }
    ]
  ])

  # Permissions Boundary - AWS Managed maps
  pset_permissions_boundary_aws_managed_maps = flatten([
    for pset_name, pset_index in local.permissions_boundary_aws_managed_permission_sets : [
      {
        pset_name = pset_name
        boundary = {
          managed_policy_arn = pset_index.permissions_boundary.managed_policy_arn
        }
      }
    ]
  ])

  # Permissions Boundary - Customer Managed maps
  pset_permissions_boundary_customer_managed_maps = flatten([
    for pset_name, pset_index in local.permissions_boundary_customer_managed_permission_sets : [
      {
        pset_name = pset_name
        boundary = {
          customer_managed_policy_reference = pset_index.permissions_boundary.customer_managed_policy_reference
        }
      }
    ]
  ])
}

################################################################################
# Account Assignments
################################################################################

locals {
  # Map of active account names to account IDs from the organization
  accounts_ids_maps = {
    for idx, account in data.aws_organizations_organization.organization.accounts : account.name => account.id
    if account.status == "ACTIVE" && can(data.aws_organizations_organization.organization.accounts)
  }

  # Flatten account_assignments into individual principal + permission_set + account records
  flatten_account_assignment_data = flatten([
    for this_assignment in keys(var.account_assignments) : [
      for account in var.account_assignments[this_assignment].account_ids : [
        for pset in var.account_assignments[this_assignment].permission_sets : {
          permission_set = pset
          principal_name = var.account_assignments[this_assignment].principal_name
          principal_type = var.account_assignments[this_assignment].principal_type
          principal_idp  = var.account_assignments[this_assignment].principal_idp
          # Support both 12-digit account IDs and account names (resolved via organization)
          account_id = length(regexall("[0-9]{12}", account)) > 0 ? account : lookup(local.accounts_ids_maps, account, null)
        }
      ]
    ]
  ])

  # Convert to map keyed by a unique combination string for for_each
  principals_and_their_account_assignments = {
    for s in local.flatten_account_assignment_data : format("Type:%s__Principal:%s__Permission:%s__Account:%s", s.principal_type, s.principal_name, s.permission_set, s.account_id) => s
  }

  # Lists of names defined in this module (used for conditional resource vs data source references)
  this_permission_sets = keys(var.permission_sets)
  this_groups = [
    for group in var.sso_groups : group.group_name
  ]
  this_users = [
    for user in var.sso_users : user.user_name
  ]
}

################################################################################
# Application Assignments
################################################################################

locals {
  # Flat list of group-application assignment records
  apps_groups_assignments = flatten([
    for app in var.sso_applications : [
      for group in coalesce(app.group_assignments, []) : {
        app_name       = app.name
        group_name     = group
        principal_type = "GROUP"
      }
    ]
  ])

  # Flat list of user-application assignment records
  apps_users_assignments = flatten([
    for app in var.sso_applications : [
      for user in coalesce(app.user_assignments, []) : {
        app_name       = app.name
        user_name      = user
        principal_type = "USER"
      }
    ]
  ])

  # Application assignment configurations
  apps_assignments_configs = flatten([
    for app in var.sso_applications : {
      app_name            = app.name
      assignment_required = app.assignment_required
    }
  ])

  # Application access scope records
  apps_assignments_access_scopes = flatten([
    for app in var.sso_applications : [
      for ass_acc_scope in coalesce(app.assignments_access_scope, []) : {
        app_name           = app.name
        authorized_targets = ass_acc_scope.authorized_targets
        scope              = ass_acc_scope.scope
      }
    ]
  ])
}
