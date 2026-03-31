<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.11.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.37.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.37.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_assignments"></a> [account\_assignments](#input\_account\_assignments) | Map of account assignment configurations. Each entry maps a principal (user or group) to permission sets and account IDs. | <pre>map(object({<br/>    principal_name  = string<br/>    principal_type  = string<br/>    principal_idp   = string # INTERNAL or EXTERNAL<br/>    permission_sets = list(string)<br/>    account_ids     = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_existing_google_sso_users"></a> [existing\_google\_sso\_users](#input\_existing\_google\_sso\_users) | Map of existing Google SSO users to reference from IAM Identity Center. Keys are logical names. | <pre>map(object({<br/>    user_name        = string<br/>    group_membership = optional(list(string), null)<br/>  }))</pre> | `{}` | no |
| <a name="input_existing_permission_sets"></a> [existing\_permission\_sets](#input\_existing\_permission\_sets) | Map of existing permission sets to reference from IAM Identity Center. Keys are logical names. | <pre>map(object({<br/>    permission_set_name = string<br/>  }))</pre> | `{}` | no |
| <a name="input_existing_sso_groups"></a> [existing\_sso\_groups](#input\_existing\_sso\_groups) | Map of existing groups to reference from IAM Identity Center. Keys are logical names. | <pre>map(object({<br/>    group_name = string<br/>  }))</pre> | `{}` | no |
| <a name="input_existing_sso_users"></a> [existing\_sso\_users](#input\_existing\_sso\_users) | Map of existing users to reference from IAM Identity Center. Keys are logical names. | <pre>map(object({<br/>    user_name        = string<br/>    group_membership = optional(list(string), null)<br/>  }))</pre> | `{}` | no |
| <a name="input_permission_sets"></a> [permission\_sets](#input\_permission\_sets) | Map of permission sets to create in IAM Identity Center. Keys are permission set names. Values support: description, relay\_state, session\_duration, tags, aws\_managed\_policies, customer\_managed\_policies, inline\_policy, permissions\_boundary. | `any` | `{}` | no |
| <a name="input_sso_applications"></a> [sso\_applications](#input\_sso\_applications) | Map of SSO applications to create in IAM Identity Center. Keys are logical names. | <pre>map(object({<br/>    name                     = string<br/>    application_provider_arn = string<br/>    description              = optional(string)<br/>    portal_options = optional(object({<br/>      sign_in_options = optional(object({<br/>        application_url = optional(string)<br/>        origin          = string<br/>      }))<br/>      visibility = optional(string)<br/>    }))<br/>    status              = string # ENABLED or DISABLED<br/>    client_token        = optional(string)<br/>    tags                = optional(map(string))<br/>    assignment_required = bool<br/>    assignments_access_scope = optional(list(object({<br/>      authorized_targets = optional(list(string))<br/>      scope              = string<br/>    })))<br/>    group_assignments = optional(list(string))<br/>    user_assignments  = optional(list(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_sso_groups"></a> [sso\_groups](#input\_sso\_groups) | Map of groups to create in IAM Identity Center. Keys are logical names. | <pre>map(object({<br/>    group_name        = string<br/>    group_description = optional(string, null)<br/>  }))</pre> | `{}` | no |
| <a name="input_sso_instance_access_control_attributes"></a> [sso\_instance\_access\_control\_attributes](#input\_sso\_instance\_access\_control\_attributes) | List of access control attributes for the SSO instance. Each entry requires attribute\_name and source. | <pre>list(object({<br/>    attribute_name = string<br/>    source         = set(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_sso_users"></a> [sso\_users](#input\_sso\_users) | Map of users to create in IAM Identity Center. Keys are logical names. | <pre>map(object({<br/>    display_name     = optional(string)<br/>    user_name        = string<br/>    group_membership = list(string)<br/>    # Name<br/>    given_name       = string<br/>    middle_name      = optional(string, null)<br/>    family_name      = string<br/>    name_formatted   = optional(string)<br/>    honorific_prefix = optional(string, null)<br/>    honorific_suffix = optional(string, null)<br/>    # Email<br/>    email            = string<br/>    email_type       = optional(string, null)<br/>    is_primary_email = optional(bool, true)<br/>    # Phone Number<br/>    phone_number            = optional(string, null)<br/>    phone_number_type       = optional(string, null)<br/>    is_primary_phone_number = optional(bool, true)<br/>    # Address<br/>    country            = optional(string, " ")<br/>    locality           = optional(string, " ")<br/>    address_formatted  = optional(string)<br/>    postal_code        = optional(string, " ")<br/>    is_primary_address = optional(bool, true)<br/>    region             = optional(string, " ")<br/>    street_address     = optional(string, " ")<br/>    address_type       = optional(string, null)<br/>    # Additional<br/>    user_type          = optional(string, null)<br/>    title              = optional(string, null)<br/>    locale             = optional(string, null)<br/>    nickname           = optional(string, null)<br/>    preferred_language = optional(string, null)<br/>    profile_url        = optional(string, null)<br/>    timezone           = optional(string, null)<br/>  }))</pre> | `{}` | no |
| <a name="input_trusted_token_issuers"></a> [trusted\_token\_issuers](#input\_trusted\_token\_issuers) | Map of trusted token issuers to create in IAM Identity Center. Keys are logical names. | <pre>map(object({<br/>    name                      = string<br/>    trusted_token_issuer_type = string # e.g. OIDC_JWT<br/>    oidc_jwt_configuration = optional(object({<br/>      claim_attribute_path          = string<br/>      identity_store_attribute_path = string<br/>      issuer_url                    = string<br/>      jwks_retrieval_option         = string # OPEN_ID_DISCOVERY or JWKS_ENDPOINT<br/>    }))<br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_assignment_data"></a> [account\_assignment\_data](#output\_account\_assignment\_data) | Tuple containing account assignment data |
| <a name="output_principals_and_assignments"></a> [principals\_and\_assignments](#output\_principals\_and\_assignments) | Map containing account assignment data |
| <a name="output_sso_applications_arns"></a> [sso\_applications\_arns](#output\_sso\_applications\_arns) | A map of SSO Applications ARNs created by this module |
| <a name="output_sso_applications_group_assignments"></a> [sso\_applications\_group\_assignments](#output\_sso\_applications\_group\_assignments) | A map of SSO Applications assignments with groups created by this module |
| <a name="output_sso_applications_user_assignments"></a> [sso\_applications\_user\_assignments](#output\_sso\_applications\_user\_assignments) | A map of SSO Applications assignments with users created by this module |
| <a name="output_sso_groups_ids"></a> [sso\_groups\_ids](#output\_sso\_groups\_ids) | A map of SSO groups ids created by this module |
| <a name="output_trusted_token_issuer_arns"></a> [trusted\_token\_issuer\_arns](#output\_trusted\_token\_issuer\_arns) | A map of trusted token issuer ARNs created by this module |
<!-- END_TF_DOCS -->