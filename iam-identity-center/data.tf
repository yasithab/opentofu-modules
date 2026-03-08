# Fetch the SSO Instance ARN and Identity Store ID
data "aws_ssoadmin_instances" "sso_instance" {}

# Fetch the AWS Organization to resolve account names to account IDs
data "aws_organizations_organization" "organization" {}

# Fetch existing SSO groups (externally defined) for group membership assignments
data "aws_identitystore_group" "existing_sso_groups" {
  for_each          = var.existing_sso_groups
  identity_store_id = local.sso_instance_id
  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = each.value.group_name
    }
  }
}

# Fetch existing SSO users (externally defined) for group membership assignments
data "aws_identitystore_user" "existing_sso_users" {
  for_each          = var.existing_sso_users
  identity_store_id = local.sso_instance_id

  alternate_identifier {
    unique_attribute {
      attribute_path  = "UserName"
      attribute_value = each.value.user_name
    }
  }
}

# Fetch existing Google SSO users (synced via SCIM) for group membership assignments
data "aws_identitystore_user" "existing_google_sso_users" {
  for_each          = var.existing_google_sso_users
  identity_store_id = local.sso_instance_id

  alternate_identifier {
    unique_attribute {
      attribute_path  = "UserName"
      attribute_value = each.value.user_name
    }
  }
}

# Fetch existing permission sets (externally defined) for account assignments
data "aws_ssoadmin_permission_set" "existing_permission_sets" {
  for_each     = var.existing_permission_sets
  instance_arn = local.ssoadmin_instance_arn
  name         = each.value.permission_set_name
}
