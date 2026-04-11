################################################################################
# Groups
################################################################################

variable "sso_groups" {
  description = "Map of groups to create in IAM Identity Center. Keys are logical names."
  type = map(object({
    group_name        = string
    group_description = optional(string, null)
  }))
  default = {}
}

variable "existing_sso_groups" {
  description = "Map of existing groups to reference from IAM Identity Center. Keys are logical names."
  type = map(object({
    group_name = string
  }))
  default = {}
}

################################################################################
# Users
################################################################################

variable "sso_users" {
  description = "Map of users to create in IAM Identity Center. Keys are logical names."
  type = map(object({
    display_name     = optional(string)
    user_name        = string
    group_membership = list(string)
    # Name
    given_name       = string
    middle_name      = optional(string, null)
    family_name      = string
    name_formatted   = optional(string)
    honorific_prefix = optional(string, null)
    honorific_suffix = optional(string, null)
    # Email
    email            = string
    email_type       = optional(string, null)
    is_primary_email = optional(bool, true)
    # Phone Number
    phone_number            = optional(string, null)
    phone_number_type       = optional(string, null)
    is_primary_phone_number = optional(bool, true)
    # Address
    country            = optional(string, " ")
    locality           = optional(string, " ")
    address_formatted  = optional(string)
    postal_code        = optional(string, " ")
    is_primary_address = optional(bool, true)
    region             = optional(string, " ")
    street_address     = optional(string, " ")
    address_type       = optional(string, null)
    # Additional
    user_type          = optional(string, null)
    title              = optional(string, null)
    locale             = optional(string, null)
    nickname           = optional(string, null)
    preferred_language = optional(string, null)
    profile_url        = optional(string, null)
    timezone           = optional(string, null)
  }))
  default = {}

  validation {
    condition     = alltrue([for user in values(var.sso_users) : length(user.user_name) > 1 && length(user.user_name) <= 128])
    error_message = "All user_names must be between 2 and 128 characters."
  }
}

variable "existing_sso_users" {
  description = "Map of existing users to reference from IAM Identity Center. Keys are logical names."
  type = map(object({
    user_name        = string
    group_membership = optional(list(string), null)
  }))
  default = {}
}

variable "existing_google_sso_users" {
  description = "Map of existing Google SSO users to reference from IAM Identity Center. Keys are logical names."
  type = map(object({
    user_name        = string
    group_membership = optional(list(string), null)
  }))
  default = {}
}

################################################################################
# Permission Sets
################################################################################

variable "permission_sets" {
  description = "Map of permission sets to create in IAM Identity Center. Keys are permission set names. Values support: description, relay_state, session_duration, tags, aws_managed_policies, customer_managed_policies, inline_policy, permissions_boundary."
  type        = any
  default     = {}
}

variable "existing_permission_sets" {
  description = "Map of existing permission sets to reference from IAM Identity Center. Keys are logical names."
  type = map(object({
    permission_set_name = string
  }))
  default = {}
}

################################################################################
# Account Assignments
################################################################################

variable "account_assignments" {
  description = "Map of account assignment configurations. Each entry maps a principal (user or group) to permission sets and account IDs."
  type = map(object({
    principal_name  = string
    principal_type  = string
    principal_idp   = string # INTERNAL or EXTERNAL
    permission_sets = list(string)
    account_ids     = list(string)
  }))
  default = {}
}

################################################################################
# Applications
################################################################################

variable "sso_applications" {
  description = "Map of SSO applications to create in IAM Identity Center. Keys are logical names."
  type = map(object({
    name                     = string
    application_provider_arn = string
    description              = optional(string)
    portal_options = optional(object({
      sign_in_options = optional(object({
        application_url = optional(string)
        origin          = string
      }))
      visibility = optional(string)
    }))
    status              = string # ENABLED or DISABLED
    client_token        = optional(string)
    tags                = optional(map(string))
    assignment_required = bool
    assignments_access_scope = optional(list(object({
      authorized_targets = optional(list(string))
      scope              = string
    })))
    group_assignments = optional(list(string))
    user_assignments  = optional(list(string))
  }))
  default = {}
  validation {
    condition = alltrue([
      for app in values(var.sso_applications) :
      app.application_provider_arn != null &&
      app.application_provider_arn != ""
    ])
    error_message = "The application_provider_arn field is mandatory for all applications."
  }
}

################################################################################
# Trusted Token Issuers
################################################################################

variable "trusted_token_issuers" {
  description = "Map of trusted token issuers to create in IAM Identity Center. Keys are logical names."
  type = map(object({
    name                      = string
    trusted_token_issuer_type = string # e.g. OIDC_JWT
    oidc_jwt_configuration = optional(object({
      claim_attribute_path          = string
      identity_store_attribute_path = string
      issuer_url                    = string
      jwks_retrieval_option         = string # OPEN_ID_DISCOVERY or JWKS_ENDPOINT
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

################################################################################
# Access Control Attributes
################################################################################

variable "sso_instance_access_control_attributes" {
  description = "List of access control attributes for the SSO instance. Each entry requires attribute_name and source."
  type = list(object({
    attribute_name = string
    source         = set(string)
  }))
  default = []
  validation {
    condition = alltrue([
      for attr in var.sso_instance_access_control_attributes :
      attr.attribute_name != null &&
      attr.attribute_name != ""
    ])
    error_message = "The attribute_name field is mandatory for all attributes."
  }
  validation {
    condition = alltrue([
      for attr in var.sso_instance_access_control_attributes :
      attr.source != null &&
      length(attr.source) > 0 &&
      alltrue([for s in attr.source : s != ""])
    ])
    error_message = "The attribute source is mandatory and must contain non-empty strings."
  }
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
