# Cognito

AWS Cognito User Pool module for OIDC/OAuth2 authentication. General-purpose - works with any application that supports OIDC.

## Features

- **User Pool** with configurable password policy, MFA (TOTP), and account recovery
- **Multiple OAuth/OIDC clients** - one pool can serve multiple applications
- **External IdP federation** - optionally federate with Google, Okta, SAML, etc.
- **Hosted UI domain** - prefix domain (free) or custom domain (ACM cert)
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
