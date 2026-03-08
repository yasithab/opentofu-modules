# IAM Identity Center Module - Examples

## Basic Usage

Create a group, a user, and assign them a permission set on a single AWS account.

```hcl
module "iam_identity_center" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam-identity-center?depth=1&ref=v2.0.0"

  sso_groups = {
    platform_engineers = {
      group_name        = "PlatformEngineers"
      group_description = "Platform engineering team"
    }
  }

  sso_users = {
    alice = {
      user_name        = "alice@example.com"
      given_name       = "Alice"
      family_name      = "Smith"
      email            = "alice@example.com"
      group_membership = ["PlatformEngineers"]
    }
  }

  permission_sets = {
    ReadOnly = {
      description      = "Read-only access"
      session_duration = "PT4H"
      managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }
  }

  account_assignments = {
    platform_engineers_readonly = {
      principal_name  = "PlatformEngineers"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["ReadOnly"]
      account_ids     = ["123456789012"]
    }
  }
}
```

## With Multiple Permission Sets and Accounts

Assign different permission sets to different groups across multiple accounts.

```hcl
module "iam_identity_center_multi" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam-identity-center?depth=1&ref=v2.0.0"

  sso_groups = {
    developers = {
      group_name        = "Developers"
      group_description = "Application developers"
    }
    platform = {
      group_name        = "Platform"
      group_description = "Platform team with admin rights"
    }
  }

  permission_sets = {
    DeveloperAccess = {
      description      = "Developer access to non-prod"
      session_duration = "PT8H"
      managed_policies = ["arn:aws:iam::aws:policy/PowerUserAccess"]
    }
    AdministratorAccess = {
      description      = "Full admin"
      session_duration = "PT1H"
      managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }
  }

  account_assignments = {
    dev_group_dev_account = {
      principal_name  = "Developers"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["DeveloperAccess"]
      account_ids     = ["111111111111", "222222222222"]
    }
    platform_admin = {
      principal_name  = "Platform"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["AdministratorAccess"]
      account_ids     = ["111111111111", "222222222222", "333333333333"]
    }
  }
}
```

## With External IdP Users and Access Control Attributes

Manage externally synced (SCIM) users alongside access control attributes for ABAC.

```hcl
module "iam_identity_center_external" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam-identity-center?depth=1&ref=v2.0.0"

  existing_sso_groups = {
    entra_engineers = { group_name = "EntraEngineers" }
  }

  permission_sets = {
    ReadOnly = {
      description      = "Read-only via external IdP"
      session_duration = "PT4H"
      managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }
  }

  account_assignments = {
    external_readonly = {
      principal_name  = "EntraEngineers"
      principal_type  = "GROUP"
      principal_idp   = "EXTERNAL"
      permission_sets = ["ReadOnly"]
      account_ids     = ["123456789012"]
    }
  }

  sso_instance_access_control_attributes = [
    {
      attribute_name = "Department"
      source         = ["$${path:enterprise.department}"]
    }
  ]
}
```

## With Trusted Token Issuer

Register an OIDC trusted token issuer for workforce identity federation.

```hcl
module "iam_identity_center_token_issuer" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam-identity-center?depth=1&ref=v2.0.0"

  trusted_token_issuers = {
    okta = {
      name                      = "okta-workforce"
      trusted_token_issuer_type = "OIDC_JWT"
      oidc_jwt_configuration = {
        claim_attribute_path          = "email"
        identity_store_attribute_path = "emails.value"
        issuer_url                    = "https://example.okta.com"
        jwks_retrieval_option         = "OPEN_ID_DISCOVERY"
      }
      tags = { Provider = "okta" }
    }
  }
}
```
