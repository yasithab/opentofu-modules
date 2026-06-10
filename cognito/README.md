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
