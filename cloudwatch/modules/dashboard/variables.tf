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

variable "dashboard_name" {
  description = "The name of the CloudWatch dashboard."
  type        = string
}

variable "dashboard_body" {
  description = "The dashboard body in JSON format. Use jsonencode() with the widget structure or provide a raw JSON string."
  type        = string
}
