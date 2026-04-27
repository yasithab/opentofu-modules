data "aws_region" "current" {}

locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

}

################################################################################
# User Pool
################################################################################

resource "aws_cognito_user_pool" "this" {
  name                = var.name
  deletion_protection = var.deletion_protection ? "ACTIVE" : "INACTIVE"
  mfa_configuration   = var.mfa_configuration

  username_attributes      = var.username_attributes
  auto_verified_attributes = var.auto_verified_attributes

  password_policy {
    minimum_length                   = var.password_policy.minimum_length
    require_lowercase                = var.password_policy.require_lowercase
    require_uppercase                = var.password_policy.require_uppercase
    require_numbers                  = var.password_policy.require_numbers
    require_symbols                  = var.password_policy.require_symbols
    temporary_password_validity_days = var.password_policy.temporary_password_validity_days
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = var.account_recovery
      priority = 1
    }
  }

  # MFA with TOTP (authenticator app)
  dynamic "software_token_mfa_configuration" {
    for_each = var.mfa_configuration != "OFF" ? [1] : []

    content {
      enabled = true
    }
  }

  # Email configuration (Cognito default)
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Schema - email is always required
  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# Domain (hosted UI)
################################################################################

resource "aws_cognito_user_pool_domain" "prefix" {
  domain       = var.domain
  user_pool_id = aws_cognito_user_pool.this.id

  lifecycle {
    enabled = local.enabled && var.domain != "" && var.custom_domain == ""
  }
}

resource "aws_cognito_user_pool_domain" "custom" {
  domain          = var.custom_domain
  user_pool_id    = aws_cognito_user_pool.this.id
  certificate_arn = var.custom_domain_certificate_arn

  lifecycle {
    enabled = local.enabled && var.custom_domain != ""
  }
}

################################################################################
# Identity Providers (external federation)
################################################################################

resource "aws_cognito_identity_provider" "this" {
  for_each = { for k, v in var.identity_providers : k => v if local.enabled }

  user_pool_id  = aws_cognito_user_pool.this.id
  provider_name = each.key
  provider_type = each.value.provider_type

  provider_details  = each.value.provider_details
  attribute_mapping = each.value.attribute_mapping
}

################################################################################
# Clients (OAuth/OIDC applications)
################################################################################

resource "aws_cognito_user_pool_client" "this" {
  for_each = { for k, v in var.clients : k => v if local.enabled }

  name         = each.key
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret                      = each.value.generate_secret
  allowed_oauth_flows                  = each.value.allowed_oauth_flows
  allowed_oauth_scopes                 = each.value.allowed_oauth_scopes
  allowed_oauth_flows_user_pool_client = true
  callback_urls                        = each.value.callback_urls
  logout_urls                          = each.value.logout_urls

  supported_identity_providers = concat(
    ["COGNITO"],
    [for k, v in var.identity_providers : k]
  )

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  access_token_validity  = each.value.token_validity.access_token_hours
  id_token_validity      = each.value.token_validity.id_token_hours
  refresh_token_validity = each.value.token_validity.refresh_token_days

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
  ]

  depends_on = [aws_cognito_identity_provider.this]
}
