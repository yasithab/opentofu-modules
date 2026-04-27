variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "dashboard_name" {
  description = "The name of the CloudWatch dashboard."
  type        = string

  validation {
    condition     = length(var.dashboard_name) > 0
    error_message = "dashboard_name must not be empty."
  }
}

variable "dashboard_body" {
  description = "The dashboard body in JSON format. Use jsonencode() with the widget structure or provide a raw JSON string."
  type        = string

  validation {
    condition     = length(var.dashboard_body) > 0
    error_message = "dashboard_body must not be empty."
  }
}
