variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

################################################################################
# Query Definition
################################################################################

variable "name" {
  description = "The name of the CloudWatch Logs Insights query definition."
  type        = string
}

variable "query_string" {
  description = "The query to save as a CloudWatch Logs Insights query definition."
  type        = string
}

variable "log_group_names" {
  description = "Specific log groups to use with the query. If not provided, the query applies to all log groups."
  type        = list(string)
  default     = null
}
