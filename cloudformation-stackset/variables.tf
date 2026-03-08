################################################################################
# Module Control
################################################################################

variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

################################################################################
# StackSet Configuration
################################################################################

variable "name" {
  description = "Name of the StackSet"
  type        = string
}

variable "description" {
  description = "Description of the StackSet"
  type        = string
  default     = null
}

variable "permission_model" {
  description = "Permission model: SERVICE_MANAGED (uses AWS Organizations) or SELF_MANAGED"
  type        = string
  default     = "SERVICE_MANAGED"

  validation {
    condition     = contains(["SERVICE_MANAGED", "SELF_MANAGED"], var.permission_model)
    error_message = "Permission model must be SERVICE_MANAGED or SELF_MANAGED."
  }
}

################################################################################
# Template Configuration
################################################################################

variable "template_body" {
  description = "CloudFormation template body (mutually exclusive with template_url)"
  type        = string
  default     = null
}

variable "template_url" {
  description = "S3 URL for CloudFormation template (mutually exclusive with template_body)"
  type        = string
  default     = null
}

variable "parameters" {
  description = "Map of parameters to pass to the CloudFormation template"
  type        = map(string)
  default     = {}
}

variable "capabilities" {
  description = "List of capabilities required by the template"
  type        = list(string)
  default     = ["CAPABILITY_NAMED_IAM"]

  validation {
    condition = alltrue([
      for cap in var.capabilities : contains([
        "CAPABILITY_IAM",
        "CAPABILITY_NAMED_IAM",
        "CAPABILITY_AUTO_EXPAND"
      ], cap)
    ])
    error_message = "Valid capabilities are: CAPABILITY_IAM, CAPABILITY_NAMED_IAM, CAPABILITY_AUTO_EXPAND."
  }
}

################################################################################
# Auto Deployment (SERVICE_MANAGED only)
################################################################################

variable "auto_deployment_enabled" {
  description = "Enable automatic deployment to new accounts in target OUs"
  type        = bool
  default     = true
}

variable "retain_stacks_on_account_removal" {
  description = "Retain stacks when an account is removed from the organization"
  type        = bool
  default     = false
}

################################################################################
# Self-Managed Permissions (SELF_MANAGED only)
################################################################################

variable "administration_role_arn" {
  description = "ARN of the IAM role in the administrator account (SELF_MANAGED only)"
  type        = string
  default     = null
}

variable "execution_role_name" {
  description = "Name of the IAM role in target accounts (SELF_MANAGED only)"
  type        = string
  default     = "AWSCloudFormationStackSetExecutionRole"
}

################################################################################
# Deployment Targets
################################################################################

variable "deployments" {
  description = <<-EOT
    List of deployment configurations. For SERVICE_MANAGED:
    - organizational_unit_ids: List of OU IDs to deploy to
    - account_filter_type: DIFFERENCE, INTERSECTION, UNION, or NONE
    - accounts: Account IDs for filtering
    - accounts_url: S3 URL of the file containing the list of accounts
    - region: AWS region for deployment

    For SELF_MANAGED:
    - account_id: Target account ID
    - region: AWS region for deployment

    Optional:
    - parameter_overrides: Map of parameter key-value pairs to override StackSet-level parameters for this instance
    - retain_stack: If true, retains the stack when the instance is removed (default false)
  EOT
  type = list(object({
    region                  = string
    organizational_unit_ids = optional(list(string), [])
    account_filter_type     = optional(string, "NONE")
    accounts                = optional(list(string), [])
    accounts_url            = optional(string)
    account_id              = optional(string)
    parameter_overrides     = optional(map(string))
    retain_stack            = optional(bool, false)
  }))
  default = []

  validation {
    condition = alltrue([
      for d in var.deployments : contains(["NONE", "DIFFERENCE", "INTERSECTION", "UNION"], d.account_filter_type)
    ])
    error_message = "account_filter_type must be NONE, DIFFERENCE, INTERSECTION, or UNION."
  }
}

################################################################################
# Operation Preferences
################################################################################

variable "operation_preferences" {
  description = "Preferences for how AWS CloudFormation performs stack operations"
  type = object({
    failure_tolerance_count      = optional(number)
    failure_tolerance_percentage = optional(number)
    max_concurrent_count         = optional(number)
    max_concurrent_percentage    = optional(number)
    concurrency_mode             = optional(string)
    region_concurrency_type      = optional(string, "PARALLEL")
    region_order                 = optional(list(string), [])
  })
  default = {
    failure_tolerance_percentage = 10
    max_concurrent_percentage    = 25
    region_concurrency_type      = "PARALLEL"
    region_order                 = []
  }

  validation {
    condition     = var.operation_preferences == null || try(var.operation_preferences.concurrency_mode, null) == null || contains(["STRICT_FAILURE_TOLERANCE", "SOFT_FAILURE_TOLERANCE"], var.operation_preferences.concurrency_mode)
    error_message = "operation_preferences.concurrency_mode must be STRICT_FAILURE_TOLERANCE or SOFT_FAILURE_TOLERANCE."
  }
}

variable "stackset_operation_preferences" {
  description = "Operation preferences to apply to the StackSet itself (not per-instance). Used for managed StackSet operations."
  type = object({
    failure_tolerance_count      = optional(number)
    failure_tolerance_percentage = optional(number)
    max_concurrent_count         = optional(number)
    max_concurrent_percentage    = optional(number)
    region_concurrency_type      = optional(string)
    region_order                 = optional(list(string), [])
  })
  default = null
}

################################################################################
# Advanced Configuration
################################################################################

variable "managed_execution_enabled" {
  description = "Enable managed execution for conflict prevention"
  type        = bool
  default     = false
}

variable "call_as" {
  description = "Whether acting as account admin or delegated admin"
  type        = string
  default     = "SELF"

  validation {
    condition     = contains(["SELF", "DELEGATED_ADMIN"], var.call_as)
    error_message = "call_as must be SELF or DELEGATED_ADMIN."
  }
}

variable "instance_timeouts" {
  description = "Timeout configuration for stack instances"
  type = object({
    create = optional(string, "30m")
    update = optional(string, "30m")
    delete = optional(string, "30m")
  })
  default = {}
}

variable "stackset_update_timeout" {
  description = "Timeout for StackSet update operations (e.g., '30m', '1h')"
  type        = string
  default     = "30m"
}

variable "tags" {
  description = "Tags to apply to the StackSet"
  type        = map(string)
  default     = {}
}

################################################################################
