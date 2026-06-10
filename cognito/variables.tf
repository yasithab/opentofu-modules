variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
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

variable "advanced_security_mode" {
  description = "Advanced security mode for the User Pool: 'OFF', 'AUDIT', or 'ENFORCED'. AUDIT logs risk events; ENFORCED additionally blocks/challenges risky sign-ins. Note: AUDIT and ENFORCED enable Cognito advanced security features, which incur additional cost per monthly active user."
  type        = string
  default     = "AUDIT"

  validation {
    condition     = contains(["OFF", "AUDIT", "ENFORCED"], var.advanced_security_mode)
    error_message = "advanced_security_mode must be OFF, AUDIT, or ENFORCED."
  }
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
  description = "Map of OAuth/OIDC client applications to create. Each client gets its own client ID and secret. `supported_identity_providers` defaults to COGNITO plus every provider in `identity_providers` when not set."
  type = map(object({
    callback_urls                        = list(string)
    logout_urls                          = optional(list(string), [])
    generate_secret                      = optional(bool, true)
    allowed_oauth_flows                  = optional(list(string), ["code"])
    allowed_oauth_scopes                 = optional(list(string), ["openid", "email", "profile"])
    allowed_oauth_flows_user_pool_client = optional(bool, true)
    explicit_auth_flows                  = optional(list(string), ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH"])
    supported_identity_providers         = optional(list(string))
    token_validity = optional(object({
      access_token_hours = optional(number, 1)
      id_token_hours     = optional(number, 1)
      refresh_token_days = optional(number, 30)
    }), {})
  }))
  default = {}
}

################################################################################
# Identity Providers (federate with external IdPs)
################################################################################

variable "identity_providers" {
  description = "Map of external identity providers to federate with. Supports Google, Facebook, Amazon, Apple, SAML, and OIDC. Marked sensitive because `provider_details` carries IdP client secrets - these values are also stored in the OpenTofu state."
  sensitive   = true
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

################################################################################
# Resource Servers (custom OAuth scopes)
################################################################################

variable "resource_servers" {
  description = "Map of resource servers defining custom OAuth scopes (e.g., for machine-to-machine APIs). `name` defaults to the map key. Clients reference scopes as <identifier>/<scope_name> in allowed_oauth_scopes."
  type = map(object({
    name       = optional(string)
    identifier = string
    scopes = optional(list(object({
      scope_name        = string
      scope_description = string
    })), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for v in values(var.resource_servers) : length(v.scopes) <= 100])
    error_message = "Each resource server supports at most 100 scopes."
  }
}

################################################################################
# User Groups
################################################################################

variable "user_groups" {
  description = "Map of user groups to create in the User Pool. Each key is the group name. Lower `precedence` values take priority when a user belongs to multiple groups; `role_arn` sets the IAM role claimed in the cognito:preferred_role token claim."
  type = map(object({
    description = optional(string)
    precedence  = optional(number)
    role_arn    = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for v in values(var.user_groups) : v.role_arn == null || can(regex("^arn:", coalesce(v.role_arn, "_")))])
    error_message = "user_groups role_arn must be a valid IAM role ARN starting with 'arn:'."
  }
}
