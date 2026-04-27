variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}


variable "name" {
  description = "Name identifier used for tagging and resource naming within the organization."
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Organization
################################################################################

variable "feature_set" {
  description = "Feature set of the organization. Valid values are ALL or CONSOLIDATED_BILLING."
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "CONSOLIDATED_BILLING"], var.feature_set)
    error_message = "feature_set must be either ALL or CONSOLIDATED_BILLING."
  }
}

variable "aws_service_access_principals" {
  description = "List of AWS service principal names for which you want to enable integration with your organization."
  type        = list(string)
  default     = []
}

variable "enabled_policy_types" {
  description = "List of organization policy types to enable. Valid values: AISERVICES_OPT_OUT_POLICY, BACKUP_POLICY, SERVICE_CONTROL_POLICY, TAG_POLICY."
  type        = list(string)
  default     = ["SERVICE_CONTROL_POLICY"]

  validation {
    condition = alltrue([
      for pt in var.enabled_policy_types : contains([
        "AISERVICES_OPT_OUT_POLICY",
        "BACKUP_POLICY",
        "SERVICE_CONTROL_POLICY",
        "TAG_POLICY",
      ], pt)
    ])
    error_message = "Each enabled_policy_type must be one of: AISERVICES_OPT_OUT_POLICY, BACKUP_POLICY, SERVICE_CONTROL_POLICY, TAG_POLICY."
  }
}

################################################################################
# Organizational Units
################################################################################

variable "organizational_units" {
  description = <<-EOT
    Map of organizational units to create. Each key is a unique identifier and the value is an object with:
    - name: Display name of the OU
    - parent_key: Key of the parent OU (null or omitted for root-level OUs)
    - tags: Optional map of tags for the OU

    Example:
    {
      security = { name = "Security", parent_key = null }
      workloads = { name = "Workloads", parent_key = null }
      prod = { name = "Production", parent_key = "workloads" }
      staging = { name = "Staging", parent_key = "workloads" }
    }
  EOT
  type = map(object({
    name       = string
    parent_key = optional(string, null)
    tags       = optional(map(string), {})
  }))
  default = {}
}

################################################################################
# Accounts
################################################################################

variable "accounts" {
  description = <<-EOT
    Map of AWS accounts to create within the organization. Each key is a unique identifier and the value is an object with:
    - name: Friendly name for the account
    - email: Email address of the account owner (must be unique across all AWS accounts)
    - parent_key: Key of the OU to place this account in (null for organization root)
    - iam_user_access_to_billing: ALLOW or DENY IAM user access to billing. Defaults to ALLOW.
    - role_name: Name of the IAM role created for cross-account access. Defaults to OrganizationAccountAccessRole.
    - close_on_deletion: If true, closes the account on removal instead of just removing from org.
    - tags: Optional map of tags for the account

    Example:
    {
      security = {
        name       = "security-account"
        email      = "aws+security@example.com"
        parent_key = "security"
      }
      prod = {
        name       = "production-account"
        email      = "aws+prod@example.com"
        parent_key = "prod"
      }
    }
  EOT
  type = map(object({
    name                       = string
    email                      = string
    parent_key                 = optional(string, null)
    iam_user_access_to_billing = optional(string, "ALLOW")
    role_name                  = optional(string, "OrganizationAccountAccessRole")
    close_on_deletion          = optional(bool, true)
    tags                       = optional(map(string), {})
  }))
  default = {}
}

################################################################################
# Service Control Policies
################################################################################

variable "policies" {
  description = <<-EOT
    Map of organization policies to create and optionally attach to targets. Each key is a unique identifier and the value is an object with:
    - name: Display name of the policy
    - description: Description of the policy
    - type: Policy type (AISERVICES_OPT_OUT_POLICY, BACKUP_POLICY, SERVICE_CONTROL_POLICY, TAG_POLICY)
    - content: Policy content as a JSON string
    - tags: Optional map of tags for the policy
    - target_keys: List of OU or account keys from organizational_units/accounts to attach this policy to.
                   Use "__root__" to attach to the organization root.

    Example:
    {
      deny_leave_org = {
        name        = "DenyLeaveOrganization"
        description = "Prevents accounts from leaving the organization"
        type        = "SERVICE_CONTROL_POLICY"
        content     = jsonencode({
          Version = "2012-10-17"
          Statement = [{
            Sid       = "DenyLeaveOrg"
            Effect    = "Deny"
            Action    = "organizations:LeaveOrganization"
            Resource  = "*"
          }]
        })
        target_keys = ["__root__"]
      }
    }
  EOT
  type = map(object({
    name        = string
    description = optional(string, "")
    type        = optional(string, "SERVICE_CONTROL_POLICY")
    content     = string
    tags        = optional(map(string), {})
    target_keys = optional(list(string), [])
  }))
  default = {}
}

################################################################################
# Delegated Administrators
################################################################################

variable "delegated_administrators" {
  description = <<-EOT
    Map of delegated administrators to register. Each key is a unique identifier and the value is an object with:
    - account_id: AWS account ID to register as a delegated administrator
    - service_principal: Service principal of the AWS service to delegate

    Example:
    {
      guardduty = {
        account_id        = "123456789012"
        service_principal = "guardduty.amazonaws.com"
      }
    }
  EOT
  type = map(object({
    account_id        = string
    service_principal = string
  }))
  default = {}
}

################################################################################
# Resource Policy
################################################################################

variable "resource_policy" {
  description = "JSON string of the organization-level resource policy. Set to null to skip creation."
  type        = string
  default     = null
}
