# Cognito

AWS Cognito User Pool module for OIDC/OAuth2 authentication. General-purpose - works with any application that supports OIDC.

## Features

- **User Pool** with configurable password policy, MFA (TOTP), and account recovery
- **Multiple OAuth/OIDC clients** - one pool can serve multiple applications
- **External IdP federation** - optionally federate with Google, Okta, SAML, etc.
- **Hosted UI domain** - prefix domain (free) or custom domain (ACM cert)
- **Resource servers** - define custom OAuth scopes for machine-to-machine APIs
- **User groups** - group users with precedence and optional IAM role mapping
- **Deletion protection** enabled by default

## Usage

```hcl
module "cognito" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cognito?depth=1&ref=master"

  name   = "mycompany-auth"
  domain = "mycompany-auth"

  clients = {
    my-app = {
      callback_urls = ["https://app.example.com/auth/callback"]
      logout_urls   = ["https://app.example.com/logout"]
    }
  }
}
```

### OIDC integration

Use the outputs to configure any OIDC-compatible application:

```hcl
# OIDC issuer URL
module.cognito.oidc_issuer
# -> https://cognito-idp.us-east-1.amazonaws.com/us-east-1_xxxxxxxx

# Client credentials
module.cognito.client_ids["my-app"]
module.cognito.client_secrets["my-app"]  # sensitive
```

### Managing users

```bash
# Create a user
aws cognito-idp admin-create-user \
  --user-pool-id <pool-id> \
  --username user@example.com \
  --user-attributes Name=email,Value=user@example.com

# Disable a user
aws cognito-idp admin-disable-user \
  --user-pool-id <pool-id> \
  --username user@example.com

# List users
aws cognito-idp list-users --user-pool-id <pool-id>
```

## Examples

## Basic - single client

```hcl
module "cognito" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cognito?depth=1&ref=master"

  name   = "mycompany-auth"
  domain = "mycompany-auth"

  clients = {
    my-app = {
      callback_urls = ["https://app.example.com/auth/callback"]
      logout_urls   = ["https://app.example.com/logout"]
    }
  }
}
```

## With MFA required

```hcl
module "cognito" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cognito?depth=1&ref=master"

  name              = "mycompany-auth"
  domain            = "mycompany-auth"
  mfa_configuration = "ON"

  clients = {
    my-app = {
      callback_urls = ["https://app.example.com/auth/callback"]
    }
  }
}
```

## With custom domain

```hcl
module "cognito" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cognito?depth=1&ref=master"

  name                          = "mycompany-auth"
  custom_domain                 = "auth.example.com"
  custom_domain_certificate_arn = aws_acm_certificate.auth.arn  # Must be in us-east-1

  clients = {
    my-app = {
      callback_urls = ["https://app.example.com/auth/callback"]
    }
  }
}
```

## Multiple clients

```hcl
module "cognito" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cognito?depth=1&ref=master"

  name   = "mycompany-auth"
  domain = "mycompany-auth"

  clients = {
    web-app = {
      callback_urls = ["https://app.example.com/auth/callback"]
      logout_urls   = ["https://app.example.com/logout"]
    }
    headscale = {
      callback_urls = ["https://headscale.example.com/oidc/callback"]
    }
    admin-tool = {
      callback_urls   = ["https://admin.example.com/auth/callback"]
      logout_urls     = ["https://admin.example.com/logout"]
      token_validity  = {
        access_token_hours = 8
        refresh_token_days = 90
      }
    }
  }
}

# Access individual client credentials
output "web_app_client_id" {
  value = module.cognito.client_ids["web-app"]
}

output "headscale_client_id" {
  value = module.cognito.client_ids["headscale"]
}
```

## Federated with Google

Users log in via Google - same credentials they use for Google Workspace.

```hcl
module "cognito" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cognito?depth=1&ref=master"

  name   = "mycompany-auth"
  domain = "mycompany-auth"

  identity_providers = {
    Google = {
      provider_type = "Google"
      provider_details = {
        client_id        = var.google_client_id
        client_secret    = var.google_client_secret
        authorize_scopes = "openid email profile"
      }
      attribute_mapping = {
        email    = "email"
        username = "sub"
        name     = "name"
      }
    }
  }

  clients = {
    my-app = {
      callback_urls = ["https://app.example.com/auth/callback"]
    }
  }
}
```

## Stricter password policy

```hcl
module "cognito" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cognito?depth=1&ref=master"

  name              = "mycompany-auth"
  domain            = "mycompany-auth"
  mfa_configuration = "ON"

  password_policy = {
    minimum_length                   = 16
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 1
  }

  clients = {
    my-app = {
      callback_urls = ["https://app.example.com/auth/callback"]
    }
  }
}
```

## Using OIDC outputs with any application

```hcl
module "cognito" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cognito?depth=1&ref=master"

  name   = "mycompany-auth"
  domain = "mycompany-auth"

  clients = {
    my-app = {
      callback_urls = ["https://app.example.com/auth/callback"]
    }
  }
}

# These outputs work with any OIDC-compatible application
output "oidc_issuer" {
  value = module.cognito.oidc_issuer
  # -> https://cognito-idp.us-east-1.amazonaws.com/us-east-1_xxxxxxxx
}

output "client_id" {
  value = module.cognito.client_ids["my-app"]
}

output "client_secret" {
  value     = module.cognito.client_secrets["my-app"]
  sensitive = true
}

output "hosted_ui_url" {
  value = module.cognito.hosted_ui_url
  # -> https://mycompany-auth.auth.us-east-1.amazoncognito.com
}
```

## Managing users

After deployment, manage users via AWS CLI:

```bash
# Create a user (receives email with temporary password)
aws cognito-idp admin-create-user \
  --user-pool-id <pool-id> \
  --username user@example.com \
  --user-attributes Name=email,Value=user@example.com \
  --temporary-password "TempPass123!"

# List users
aws cognito-idp list-users --user-pool-id <pool-id>

# Disable a user (revokes access immediately)
aws cognito-idp admin-disable-user \
  --user-pool-id <pool-id> \
  --username user@example.com

# Re-enable a user
aws cognito-idp admin-enable-user \
  --user-pool-id <pool-id> \
  --username user@example.com

# Delete a user
aws cognito-idp admin-delete-user \
  --user-pool-id <pool-id> \
  --username user@example.com
```

## Resource server with machine-to-machine client

Define custom OAuth scopes on a resource server and grant them to a client using the `client_credentials` flow - the standard machine-to-machine pattern.

```hcl
module "cognito" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cognito?depth=1&ref=master"

  name   = "platform-auth"
  domain = "mycompany-auth"

  resource_servers = {
    orders-api = {
      identifier = "https://orders.example.com"
      scopes = [
        {
          scope_name        = "read"
          scope_description = "Read access to the orders API"
        },
        {
          scope_name        = "write"
          scope_description = "Write access to the orders API"
        },
      ]
    }
  }

  clients = {
    orders-worker = {
      callback_urls       = ["https://localhost"] # unused for client_credentials
      allowed_oauth_flows = ["client_credentials"]
      # Custom scopes are referenced as <identifier>/<scope_name>
      allowed_oauth_scopes = [
        "https://orders.example.com/read",
        "https://orders.example.com/write",
      ]
      explicit_auth_flows = ["ALLOW_REFRESH_TOKEN_AUTH"]
    }
  }

  tags = {
    Environment = "production"
  }
}

# Full scope identifiers, e.g. ["https://orders.example.com/read", ...]
output "orders_scopes" {
  value = module.cognito.resource_server_scope_identifiers["orders-api"]
}
```

## User groups

Group users for authorization decisions. Group membership is included in the `cognito:groups` token claim; when multiple groups set `role_arn`, the lowest `precedence` wins for the `cognito:preferred_role` claim.

```hcl
module "cognito" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cognito?depth=1&ref=master"

  name   = "platform-auth"
  domain = "mycompany-auth"

  clients = {
    web-app = {
      callback_urls = ["https://app.example.com/callback"]
    }
  }

  user_groups = {
    admins = {
      description = "Administrators with full access"
      precedence  = 1
    }
    operators = {
      description = "Operations staff"
      precedence  = 5
    }
    readers = {
      description = "Read-only users"
      precedence  = 10
    }
  }

  tags = {
    Environment = "production"
  }
}
```

```bash
# Add a user to a group
aws cognito-idp admin-add-user-to-group \
  --user-pool-id <pool-id> \
  --username alice@example.com \
  --group-name admins
```

## Security Notes

### Advanced security mode (cost)

The User Pool is created with `advanced_security_mode = "AUDIT"` by default, which enables
Cognito advanced security features (threat protection): risk event logging, compromised
credentials detection data, and adaptive authentication telemetry. Set to `"ENFORCED"` to also
block or challenge risky sign-ins, or `"OFF"` to disable.

**Cost note:** AUDIT and ENFORCED enable the Cognito advanced security feature tier, which is
billed per monthly active user *in addition* to standard Cognito pricing. Review
[Amazon Cognito pricing](https://aws.amazon.com/cognito/pricing/) before enabling on pools with
a large user base.

### MFA

`mfa_configuration` defaults to `"OPTIONAL"`: TOTP (authenticator app) MFA is available but
users are not forced to enroll. For workloads handling sensitive data, set
`mfa_configuration = "ON"` to require MFA for all users. Note that switching an existing pool
from `OFF` is only possible to `OPTIONAL` first; users must enroll before you can move to `ON`.

### Identity provider secrets

`identity_providers` is marked `sensitive` because `provider_details` typically carries the
external IdP's client secret. These values are stored in the OpenTofu state - protect state
access accordingly. As a consequence of the sensitive marking, plan output for values derived
from this variable is redacted.

## Reference

<details>
<summary>Requirements, providers, inputs and outputs (generated by terraform-docs)</summary>

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
| account\_recovery | Account recovery mechanism. | `string` | `"verified_email"` | no |
| advanced\_security\_mode | Advanced security mode for the User Pool: 'OFF', 'AUDIT', or 'ENFORCED'. AUDIT logs risk events; ENFORCED additionally blocks/challenges risky sign-ins. Note: AUDIT and ENFORCED enable Cognito advanced security features, which incur additional cost per monthly active user. | `string` | `"AUDIT"` | no |
| auto\_verified\_attributes | Attributes to auto-verify (e.g., 'email', 'phone\_number'). | `list(string)` | <pre>[<br/>  "email"<br/>]</pre> | no |
| clients | Map of OAuth/OIDC client applications to create. Each client gets its own client ID and secret. `supported_identity_providers` defaults to COGNITO plus every provider in `identity_providers` when not set. | <pre>map(object({<br/>    callback_urls                        = list(string)<br/>    logout_urls                          = optional(list(string), [])<br/>    generate_secret                      = optional(bool, true)<br/>    allowed_oauth_flows                  = optional(list(string), ["code"])<br/>    allowed_oauth_scopes                 = optional(list(string), ["openid", "email", "profile"])<br/>    allowed_oauth_flows_user_pool_client = optional(bool, true)<br/>    explicit_auth_flows                  = optional(list(string), ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH"])<br/>    supported_identity_providers         = optional(list(string))<br/>    token_validity = optional(object({<br/>      access_token_hours = optional(number, 1)<br/>      id_token_hours     = optional(number, 1)<br/>      refresh_token_days = optional(number, 30)<br/>    }), {})<br/>  }))</pre> | `{}` | no |
| custom\_domain | Custom domain for Cognito hosted UI (e.g., 'auth.example.com'). Requires ACM certificate. Takes precedence over domain. | `string` | `""` | no |
| custom\_domain\_certificate\_arn | ACM certificate ARN for the custom domain. Must be in us-east-1. | `string` | `""` | no |
| deletion\_protection | Protect the User Pool from accidental deletion. | `bool` | `true` | no |
| domain | Cognito hosted UI domain prefix (e.g., 'mycompany-auth'). Creates <domain>.auth.<region>.amazoncognito.com. Leave empty to skip. | `string` | `""` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| identity\_providers | Map of external identity providers to federate with. Supports Google, Facebook, Amazon, Apple, SAML, and OIDC. Marked sensitive because `provider_details` carries IdP client secrets - these values are also stored in the OpenTofu state. | <pre>map(object({<br/>    provider_type    = string # Google, Facebook, LoginWithAmazon, SignInWithApple, SAML, OIDC<br/>    provider_details = map(string)<br/>    attribute_mapping = optional(map(string), {<br/>      email    = "email"<br/>      username = "sub"<br/>    })<br/>  }))</pre> | `{}` | no |
| mfa\_configuration | MFA configuration: 'OFF', 'ON' (required), or 'OPTIONAL'. | `string` | `"OPTIONAL"` | no |
| name | Name for the Cognito User Pool and related resources. | `string` | n/a | yes |
| password\_policy | Password policy for the User Pool. | <pre>object({<br/>    minimum_length                   = optional(number, 12)<br/>    require_lowercase                = optional(bool, true)<br/>    require_uppercase                = optional(bool, true)<br/>    require_numbers                  = optional(bool, true)<br/>    require_symbols                  = optional(bool, true)<br/>    temporary_password_validity_days = optional(number, 7)<br/>  })</pre> | `{}` | no |
| resource\_servers | Map of resource servers defining custom OAuth scopes (e.g., for machine-to-machine APIs). `name` defaults to the map key. Clients reference scopes as <identifier>/<scope\_name> in allowed\_oauth\_scopes. | <pre>map(object({<br/>    name       = optional(string)<br/>    identifier = string<br/>    scopes = optional(list(object({<br/>      scope_name        = string<br/>      scope_description = string<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| user\_groups | Map of user groups to create in the User Pool. Each key is the group name. Lower `precedence` values take priority when a user belongs to multiple groups; `role_arn` sets the IAM role claimed in the cognito:preferred\_role token claim. | <pre>map(object({<br/>    description = optional(string)<br/>    precedence  = optional(number)<br/>    role_arn    = optional(string)<br/>  }))</pre> | `{}` | no |
| username\_attributes | Attributes that can be used as usernames. Set to ['email'] to use email as username, or [] for plain usernames with separate email. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| client\_ids | Map of client name to client ID |
| client\_secrets | Map of client name to client secret (sensitive) |
| domain | Cognito hosted UI domain |
| hosted\_ui\_url | Cognito hosted UI base URL for login |
| oidc\_config | Ready-to-use OIDC configuration for the first client. Contains issuer and client\_id. Store client\_secret in Secrets Manager separately for production use. |
| oidc\_config\_with\_secret | OIDC configuration including client\_secret for the first client. Use for development only - for production, store the secret in Secrets Manager instead. |
| oidc\_issuer | OIDC issuer URL for this User Pool. Use this as the issuer in any OIDC-compatible application. |
| resource\_server\_identifiers | Map of resource server keys to their identifiers |
| resource\_server\_scope\_identifiers | Map of resource server keys to the list of full scope identifiers (<identifier>/<scope\_name>) for use in client allowed\_oauth\_scopes |
| user\_group\_names | Map of user group keys to their names |
| user\_group\_precedences | Map of user group keys to their precedence values |
| user\_pool\_arn | Cognito User Pool ARN |
| user\_pool\_endpoint | Cognito User Pool endpoint (use as OIDC issuer URL) |
| user\_pool\_id | Cognito User Pool ID |
<!-- END_TF_DOCS -->

</details>
