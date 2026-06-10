variable "defaults" {
  description = "Map of default values which will be used for each item."
  type        = any
  default     = {}
}

variable "items" {
  description = "Maps of items to create a wrapper from. Values are passed through to the module. Marked sensitive because items can carry `secret_string`/`secret_binary` values."
  type        = any
  default     = {}
  sensitive   = true
}
