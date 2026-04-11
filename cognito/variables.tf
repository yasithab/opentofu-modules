variable "enabled" {
  description = "Controls if Cognito resources should be created."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name for the Cognito User Pool and related resources."
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# User Pool
################################################################################

variable "deletion_protection" {
  description = "Protect the User Pool from accidental deletion."
  type        = bool
  default     = true
}

variable "mfa_configuration" {
  description = "MFA configuration: 'OFF', 'ON' (required), or 'OPTIONAL'."
  type        = string
  default     = "OPTIONAL"

  validation {
    condition     = contains(["OFF", "ON", "OPTIONAL"], var.mfa_configuration)
    error_message = "mfa_configuration must be OFF, ON, or OPTIONAL."
  }
}

variable "password_policy" {
  description = "Password policy for the User Pool."
  type = object({
    minimum_length                   = optional(number, 12)
    require_lowercase                = optional(bool, true)
    require_uppercase                = optional(bool, true)
    require_numbers                  = optional(bool, true)
    require_symbols                  = optional(bool, true)
    temporary_password_validity_days = optional(number, 7)
  })
  default = {}
}

variable "auto_verified_attributes" {
  description = "Attributes to auto-verify (e.g., 'email', 'phone_number')."
  type        = list(string)
  default     = ["email"]
}

variable "username_attributes" {
  description = "Attributes that can be used as usernames. Set to ['email'] to use email as username, or [] for plain usernames with separate email."
  type        = list(string)
  default     = []
}

variable "account_recovery" {
  description = "Account recovery mechanism."
  type        = string
  default     = "verified_email"

  validation {
    condition     = contains(["verified_email", "verified_phone_number", "admin_only"], var.account_recovery)
    error_message = "account_recovery must be verified_email, verified_phone_number, or admin_only."
  }
}

################################################################################
# Domain
################################################################################

variable "domain" {
  description = "Cognito hosted UI domain prefix (e.g., 'mycompany-auth'). Creates <domain>.auth.<region>.amazoncognito.com. Leave empty to skip."
  type        = string
  default     = ""
}

variable "custom_domain" {
  description = "Custom domain for Cognito hosted UI (e.g., 'auth.example.com'). Requires ACM certificate. Takes precedence over domain."
  type        = string
  default     = ""
}

variable "custom_domain_certificate_arn" {
  description = "ACM certificate ARN for the custom domain. Must be in us-east-1."
  type        = string
  default     = ""
}

################################################################################
# Clients
################################################################################

variable "clients" {
  description = "Map of OAuth/OIDC client applications to create. Each client gets its own client ID and secret."
  type = map(object({
    callback_urls  = list(string)
    logout_urls    = optional(list(string), [])
    generate_secret = optional(bool, true)
    allowed_oauth_flows = optional(list(string), ["code"])
    allowed_oauth_scopes = optional(list(string), ["openid", "email", "profile"])
    token_validity = optional(object({
      access_token_hours  = optional(number, 1)
      id_token_hours      = optional(number, 1)
      refresh_token_days  = optional(number, 30)
    }), {})
  }))
  default = {}
}

################################################################################
# Identity Providers (federate with external IdPs)
################################################################################

variable "identity_providers" {
  description = "Map of external identity providers to federate with. Supports Google, Facebook, Amazon, Apple, SAML, and OIDC."
  type = map(object({
    provider_type    = string # Google, Facebook, LoginWithAmazon, SignInWithApple, SAML, OIDC
    provider_details = map(string)
    attribute_mapping = optional(map(string), {
      email    = "email"
      username = "sub"
    })
  }))
  default = {}
}

