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

variable "parameter_read" {
  type        = list(string)
  description = "List of parameters to read from SSM. These must already exist otherwise an error is returned. Can be used with `parameter_write` as long as the parameters are different."
  default     = []
}

variable "parameter_write" {
  type        = list(map(string))
  description = "List of maps with the parameter values to write to SSM Parameter Store"
  default     = []
}

variable "kms_arn" {
  type        = string
  default     = null
  description = "The ARN of a KMS key used to encrypt and decrypt SecretString values"
}

variable "parameter_write_defaults" {
  type        = map(any)
  description = "Parameter write default settings"
  default = {
    description     = null
    type            = "SecureString"
    tier            = "Standard"
    overwrite       = null
    allowed_pattern = null
    data_type       = "text"
  }
}

variable "ignore_value_changes" {
  type        = bool
  description = "Whether to ignore future external changes in paramater values"
  default     = false
}
