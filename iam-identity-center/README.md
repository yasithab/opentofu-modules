# IAM Identity Center

Comprehensive AWS IAM Identity Center (successor to AWS SSO) module for managing users, groups, permission sets, account assignments, SSO applications, and trusted token issuers from a single configuration.

## Features

- **Group Management** - Create new groups or reference existing groups (including those synced from external identity providers)
- **User Management** - Provision users with full profile support (name, email, phone, address, locale, timezone) or reference existing users from SCIM-synced providers like Google, Okta, or Entra ID
- **Permission Sets** - Define permission sets with AWS managed policies, customer managed policies, inline policies, and permissions boundaries
- **Account Assignments** - Map principals (users or groups) to permission sets across multiple AWS accounts, supporting INTERNAL, EXTERNAL, and GOOGLE identity provider sources
- **SSO Applications** - Register and configure SSO applications with portal options, access scopes, and assignment configurations for groups and users
- **Trusted Token Issuers** - Set up OIDC JWT trusted token issuers for token exchange scenarios
- **Access Control Attributes** - Configure instance-level access control attributes (ABAC) for attribute-based authorization

## Usage

```hcl
module "identity_center" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam-identity-center?depth=1&ref=master"

  sso_groups = {
    admins = {
      group_name        = "Admins"
      group_description = "Organization administrators"
    }
  }

  permission_sets = {
    AdministratorAccess = {
      description        = "Full administrator access"
      session_duration   = "PT4H"
      aws_managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }
  }

  account_assignments = {
    admin_assignment = {
      principal_name  = "Admins"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["AdministratorAccess"]
      account_ids     = ["123456789012", "210987654321"]
    }
  }
}
```


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11.0 |
| aws | >= 6.49, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| account\_assignments | Map of account assignment configurations. Each entry maps a principal (user or group) to permission sets and account IDs. | <pre>map(object({<br/>    principal_name  = string<br/>    principal_type  = string<br/>    principal_idp   = string # INTERNAL or EXTERNAL<br/>    permission_sets = list(string)<br/>    account_ids     = list(string)<br/>  }))</pre> | `{}` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| existing\_google\_sso\_users | Map of existing Google SSO users to reference from IAM Identity Center. Keys are logical names. | <pre>map(object({<br/>    user_name        = string<br/>    group_membership = optional(list(string), null)<br/>  }))</pre> | `{}` | no |
| existing\_permission\_sets | Map of existing permission sets to reference from IAM Identity Center. Keys are logical names. | <pre>map(object({<br/>    permission_set_name = string<br/>  }))</pre> | `{}` | no |
| existing\_sso\_groups | Map of existing groups to reference from IAM Identity Center. Keys are logical names. | <pre>map(object({<br/>    group_name = string<br/>  }))</pre> | `{}` | no |
| existing\_sso\_users | Map of existing users to reference from IAM Identity Center. Keys are logical names. | <pre>map(object({<br/>    user_name        = string<br/>    group_membership = optional(list(string), null)<br/>  }))</pre> | `{}` | no |
| permission\_sets | Map of permission sets to create in IAM Identity Center. Keys are permission set names. Unknown attributes are rejected (previously silently dropped). | <pre>map(object({<br/>    description               = optional(string)<br/>    relay_state               = optional(string)<br/>    session_duration          = optional(string)<br/>    tags                      = optional(map(string), {})<br/>    aws_managed_policies      = optional(list(string), [])<br/>    customer_managed_policies = optional(list(string), [])<br/>    inline_policy             = optional(string)<br/>    permissions_boundary = optional(object({<br/>      managed_policy_arn = optional(string)<br/>      customer_managed_policy_reference = optional(object({<br/>        name = string<br/>        path = optional(string, "/")<br/>      }))<br/>    }))<br/>  }))</pre> | `{}` | no |
| sso\_applications | Map of SSO applications to create in IAM Identity Center. Keys are logical names. | <pre>map(object({<br/>    name                     = string<br/>    application_provider_arn = string<br/>    description              = optional(string)<br/>    portal_options = optional(object({<br/>      sign_in_options = optional(object({<br/>        application_url = optional(string)<br/>        origin          = string<br/>      }))<br/>      visibility = optional(string)<br/>    }))<br/>    status              = string # ENABLED or DISABLED<br/>    client_token        = optional(string)<br/>    tags                = optional(map(string))<br/>    assignment_required = bool<br/>    assignments_access_scope = optional(list(object({<br/>      authorized_targets = optional(list(string))<br/>      scope              = string<br/>    })))<br/>    group_assignments = optional(list(string))<br/>    user_assignments  = optional(list(string))<br/>  }))</pre> | `{}` | no |
| sso\_groups | Map of groups to create in IAM Identity Center. Keys are logical names. | <pre>map(object({<br/>    group_name        = string<br/>    group_description = optional(string, null)<br/>  }))</pre> | `{}` | no |
| sso\_instance\_access\_control\_attributes | List of access control attributes for the SSO instance. Each entry requires attribute\_name and source. | <pre>list(object({<br/>    attribute_name = string<br/>    source         = set(string)<br/>  }))</pre> | `[]` | no |
| sso\_users | Map of users to create in IAM Identity Center. Keys are logical names. | <pre>map(object({<br/>    display_name     = optional(string)<br/>    user_name        = string<br/>    group_membership = list(string)<br/>    # Name<br/>    given_name       = string<br/>    middle_name      = optional(string, null)<br/>    family_name      = string<br/>    name_formatted   = optional(string)<br/>    honorific_prefix = optional(string, null)<br/>    honorific_suffix = optional(string, null)<br/>    # Email<br/>    email            = string<br/>    email_type       = optional(string, null)<br/>    is_primary_email = optional(bool, true)<br/>    # Phone Number<br/>    phone_number            = optional(string, null)<br/>    phone_number_type       = optional(string, null)<br/>    is_primary_phone_number = optional(bool, true)<br/>    # Address<br/>    country            = optional(string)<br/>    locality           = optional(string)<br/>    address_formatted  = optional(string)<br/>    postal_code        = optional(string)<br/>    is_primary_address = optional(bool, true)<br/>    region             = optional(string)<br/>    street_address     = optional(string)<br/>    address_type       = optional(string, null)<br/>    # Additional<br/>    user_type          = optional(string, null)<br/>    title              = optional(string, null)<br/>    locale             = optional(string, null)<br/>    nickname           = optional(string, null)<br/>    preferred_language = optional(string, null)<br/>    profile_url        = optional(string, null)<br/>    timezone           = optional(string, null)<br/>  }))</pre> | `{}` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| trusted\_token\_issuers | Map of trusted token issuers to create in IAM Identity Center. Keys are logical names. | <pre>map(object({<br/>    name                      = string<br/>    trusted_token_issuer_type = string # e.g. OIDC_JWT<br/>    oidc_jwt_configuration = optional(object({<br/>      claim_attribute_path          = string<br/>      identity_store_attribute_path = string<br/>      issuer_url                    = string<br/>      jwks_retrieval_option         = string # OPEN_ID_DISCOVERY or JWKS_ENDPOINT<br/>    }))<br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| account\_assignment\_data | Tuple containing account assignment data |
| permission\_sets\_arns | A map of permission set ARNs created by this module, keyed by permission set name |
| principals\_and\_assignments | Map containing account assignment data |
| sso\_applications\_arns | A map of SSO Applications ARNs created by this module |
| sso\_applications\_group\_assignments | A map of SSO Applications assignments with groups created by this module |
| sso\_applications\_user\_assignments | A map of SSO Applications assignments with users created by this module |
| sso\_groups\_ids | A map of SSO groups ids created by this module |
| trusted\_token\_issuer\_arns | A map of trusted token issuer ARNs created by this module |
<!-- END_TF_DOCS -->

## Examples

## Basic Usage

Create a group, a user, and assign them a permission set on a single AWS account.

```hcl
module "iam_identity_center" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam-identity-center?depth=1&ref=master"

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
      aws_managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
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
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam-identity-center?depth=1&ref=master"

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
      aws_managed_policies = ["arn:aws:iam::aws:policy/PowerUserAccess"]
    }
    AdministratorAccess = {
      description      = "Full admin"
      session_duration = "PT1H"
      aws_managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
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
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam-identity-center?depth=1&ref=master"

  existing_sso_groups = {
    entra_engineers = { group_name = "EntraEngineers" }
  }

  permission_sets = {
    ReadOnly = {
      description      = "Read-only via external IdP"
      session_duration = "PT4H"
      aws_managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
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
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam-identity-center?depth=1&ref=master"

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

## Notes

### `permission_sets` is strictly typed

`permission_sets` is a typed `map(object)` with optional attributes: `description`,
`relay_state`, `session_duration`, `tags`, `aws_managed_policies`,
`customer_managed_policies`, `inline_policy`, `permissions_boundary`. Unknown attribute
names fail at plan time instead of being silently dropped.

### Account name resolution

`account_assignments.account_ids` entries must be either 12-digit account IDs
(`^[0-9]{12}$`) or names of ACTIVE accounts in the organization. Unresolvable names fail
the plan with a precondition error.
