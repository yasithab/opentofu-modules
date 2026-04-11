variable "enabled" {
  description = "Controls if Lake Formation resources are created"
  type        = bool
  default     = true
}

variable "region" {
  description = "AWS region override. If not specified, the provider default region is used"
  type        = string
  default     = null
}

variable "name" {
  description = "Name prefix for Lake Formation resources"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Data Lake Settings
################################################################################

variable "catalog_id" {
  description = "AWS account ID for the Glue Data Catalog. Defaults to the caller's account"
  type        = string
  default     = null
}

variable "admin_arns" {
  description = "List of IAM principal ARNs to grant Lake Formation administrator privileges"
  type        = list(string)
  default     = []
}

variable "allow_external_data_filtering" {
  description = "Whether to allow external engines to filter data in Amazon S3 locations registered with Lake Formation"
  type        = bool
  default     = false
}

variable "allow_full_table_external_data_access" {
  description = "Whether to allow external engines to access full tables registered with Lake Formation"
  type        = bool
  default     = false
}

variable "authorized_session_tag_value_list" {
  description = "List of allowed session tag values for third-party engines"
  type        = list(string)
  default     = []
}

variable "external_data_filtering_allow_list" {
  description = "List of account IDs allowed to perform external data filtering"
  type        = list(string)
  default     = []
}

variable "trusted_resource_owners" {
  description = "List of trusted resource owner account IDs to allow cross-account access"
  type        = list(string)
  default     = []
}

variable "create_database_default_permissions" {
  description = "Default permissions for newly created databases. Object with 'permissions' (list) and 'principal' (string)"
  type = object({
    permissions = optional(list(string), ["ALL"])
    principal   = optional(string)
  })
  default = null
}

variable "create_table_default_permissions" {
  description = "Default permissions for newly created tables. Object with 'permissions' (list) and 'principal' (string)"
  type = object({
    permissions = optional(list(string), ["ALL"])
    principal   = optional(string)
  })
  default = null
}

################################################################################
# Resource Registration
################################################################################

variable "resources" {
  description = "Map of S3 resources to register with Lake Formation. Each value needs 'arn' and optionally 'role_arn', 'use_service_linked_role', 'hybrid_access_enabled'"
  type = map(object({
    arn                     = string
    role_arn                = optional(string)
    use_service_linked_role = optional(bool)
    hybrid_access_enabled   = optional(bool)
  }))
  default = {}
}

################################################################################
# LF-Tags
################################################################################

variable "lf_tags" {
  description = "Map of LF-Tags to create. Key is the tag key, value is a list of allowed tag values"
  type        = map(list(string))
  default     = {}
}

################################################################################
# Database Permissions
################################################################################

variable "database_permissions" {
  description = "Map of database-level permissions to grant. Each value needs 'principal', 'permissions', 'database_name', and optionally 'permissions_with_grant_option'"
  type = map(object({
    principal                     = string
    permissions                   = list(string)
    database_name                 = string
    permissions_with_grant_option = optional(list(string), [])
    catalog_id                    = optional(string)
  }))
  default = {}
}

################################################################################
# Table Permissions
################################################################################

variable "table_permissions" {
  description = "Map of table-level permissions to grant. Each value needs 'principal', 'permissions', 'database_name', and either 'table_name' or 'wildcard'"
  type = map(object({
    principal                     = string
    permissions                   = list(string)
    database_name                 = string
    table_name                    = optional(string)
    wildcard                      = optional(bool)
    permissions_with_grant_option = optional(list(string), [])
    catalog_id                    = optional(string)
  }))
  default = {}
}

################################################################################
# Table with Columns Permissions
################################################################################

variable "table_with_columns_permissions" {
  description = "Map of column-level permissions to grant. Each value needs 'principal', 'permissions', 'database_name', 'table_name', and either 'column_names' or 'wildcard'"
  type = map(object({
    principal                     = string
    permissions                   = list(string)
    database_name                 = string
    table_name                    = string
    column_names                  = optional(list(string))
    excluded_column_names         = optional(list(string))
    wildcard                      = optional(bool)
    permissions_with_grant_option = optional(list(string), [])
    catalog_id                    = optional(string)
  }))
  default = {}
}

################################################################################
# LF-Tag Permissions
################################################################################

variable "lf_tag_permissions" {
  description = "Map of LF-Tag permissions to grant. Each value needs 'principal', 'permissions', 'key', and 'values'"
  type = map(object({
    principal                     = string
    permissions                   = list(string)
    key                           = string
    values                        = list(string)
    permissions_with_grant_option = optional(list(string), [])
    catalog_id                    = optional(string)
  }))
  default = {}
}

################################################################################
# LF-Tag Policy Permissions
################################################################################

variable "lf_tag_policy_permissions" {
  description = "Map of LF-Tag policy-based permissions. Each value needs 'principal', 'permissions', 'resource_type' (DATABASE or TABLE), and 'expression' (list of key/values)"
  type = map(object({
    principal                     = string
    permissions                   = list(string)
    resource_type                 = string
    permissions_with_grant_option = optional(list(string), [])
    catalog_id                    = optional(string)
    expression = list(object({
      key    = string
      values = list(string)
    }))
  }))
  default = {}
}

################################################################################
# Data Cells Filters (Row/Cell-Level Security)
################################################################################

variable "data_cells_filters" {
  description = "Map of data cells filters for row/cell-level security. Key is the filter name. Each value needs 'database_name', 'table_name', and either 'column_names' or 'column_wildcard', plus optional 'row_filter'"
  type = map(object({
    database_name = string
    table_name    = string
    column_names  = optional(list(string))
    column_wildcard = optional(object({
      excluded_column_names = optional(list(string))
    }))
    row_filter = optional(string)
    catalog_id = optional(string)
    version_id = optional(string)
  }))
  default = {}
}

################################################################################
# Resource LF-Tag Associations
################################################################################

variable "database_lf_tag_associations" {
  description = "Map of database-level LF-Tag associations. Each value needs 'database_name' and 'lf_tags' (list of key/value pairs)"
  type = map(object({
    database_name = string
    catalog_id    = optional(string)
    lf_tags = list(object({
      key        = string
      value      = string
      catalog_id = optional(string)
    }))
  }))
  default = {}
}

variable "table_lf_tag_associations" {
  description = "Map of table-level LF-Tag associations. Each value needs 'database_name', 'table_name', and 'lf_tags' (list of key/value pairs)"
  type = map(object({
    database_name = string
    table_name    = string
    catalog_id    = optional(string)
    lf_tags = list(object({
      key        = string
      value      = string
      catalog_id = optional(string)
    }))
  }))
  default = {}
}
