variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}


variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "ignore_value_changes" {
  description = "Whether to create SSM Parameter and ignore changes in value"
  type        = bool
  default     = false
}

variable "secure_type" {
  description = "Whether the type of the value should be considered as secure or not?"
  type        = bool
  default     = false
}

################################################################################
# SSM Parameter
################################################################################

variable "parameter_name" {
  description = "Name of SSM parameter"
  type        = string
  default     = null
}

variable "parameter_value" {
  description = "Value of the parameter"
  type        = string
  default     = null
  sensitive   = true
}

variable "parameter_values" {
  description = "List of values of the parameter (will be jsonencoded to store as string natively in SSM)"
  type        = list(string)
  default     = []
}

variable "parameter_description" {
  description = "Description of the parameter"
  type        = string
  default     = null
}

variable "type" {
  description = "Type of the parameter. Valid types are String, StringList and SecureString."
  type        = string
  default     = null

  validation {
    condition     = var.type == null || contains(["String", "StringList", "SecureString"], var.type)
    error_message = "The type must be 'String', 'StringList', or 'SecureString'."
  }
}

variable "tier" {
  description = "Parameter tier to assign to the parameter. If not specified, will use the default parameter tier for the region. Valid tiers are Standard, Advanced, and Intelligent-Tiering. Downgrading an Advanced tier parameter to Standard will recreate the resource."
  type        = string
  default     = null

  validation {
    condition     = var.tier == null || contains(["Standard", "Advanced", "Intelligent-Tiering"], var.tier)
    error_message = "The tier must be 'Standard', 'Advanced', or 'Intelligent-Tiering'."
  }
}

variable "key_id" {
  description = "KMS key ID or ARN for encrypting a parameter (when type is SecureString)"
  type        = string
  default     = null
}

variable "value_wo" {
  description = "Write-only value of the parameter. Never stored to state. Requires value_wo_version to trigger updates. Use instead of parameter_value for SecureString parameters to keep values out of state."
  type        = string
  default     = null
  ephemeral   = true
}

variable "value_wo_version" {
  description = "Increment this number to trigger an update when using value_wo. Required when value_wo is set."
  type        = number
  default     = null
}

variable "allowed_pattern" {
  description = "Regular expression used to validate the parameter value."
  type        = string
  default     = null
}

variable "data_type" {
  description = "Data type of the parameter. Valid values: text, aws:ssm:integration and aws:ec2:image for AMI format."
  type        = string
  default     = null

  validation {
    condition     = var.data_type == null || contains(["text", "aws:ssm:integration", "aws:ec2:image"], var.data_type)
    error_message = "The data_type must be 'text', 'aws:ssm:integration', or 'aws:ec2:image'."
  }
}
