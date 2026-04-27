locals {
  enabled = var.enabled
}

################################################################################
# Data Lake Settings
################################################################################

resource "aws_lakeformation_data_lake_settings" "this" {
  admins                                = var.admin_arns
  catalog_id                            = var.catalog_id
  allow_external_data_filtering         = var.allow_external_data_filtering
  allow_full_table_external_data_access = var.allow_full_table_external_data_access
  authorized_session_tag_value_list     = var.authorized_session_tag_value_list
  external_data_filtering_allow_list    = var.external_data_filtering_allow_list
  trusted_resource_owners               = var.trusted_resource_owners

  dynamic "create_database_default_permissions" {
    for_each = var.create_database_default_permissions != null ? [var.create_database_default_permissions] : []

    content {
      permissions = try(create_database_default_permissions.value.permissions, ["ALL"])
      principal   = try(create_database_default_permissions.value.principal, null)
    }
  }

  dynamic "create_table_default_permissions" {
    for_each = var.create_table_default_permissions != null ? [var.create_table_default_permissions] : []

    content {
      permissions = try(create_table_default_permissions.value.permissions, ["ALL"])
      principal   = try(create_table_default_permissions.value.principal, null)
    }
  }

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# Resource Registration (S3 Locations)
################################################################################

resource "aws_lakeformation_resource" "this" {
  for_each = local.enabled ? var.resources : {}

  arn      = each.value.arn
  role_arn = try(each.value.role_arn, null)

  use_service_linked_role = try(each.value.use_service_linked_role, null)
  hybrid_access_enabled   = try(each.value.hybrid_access_enabled, null)
}

################################################################################
# LF-Tags
################################################################################

resource "aws_lakeformation_lf_tag" "this" {
  for_each = local.enabled ? var.lf_tags : {}

  key        = each.key
  values     = each.value
  catalog_id = var.catalog_id
}

################################################################################
# Database Permissions
################################################################################

resource "aws_lakeformation_permissions" "database" {
  for_each = local.enabled ? var.database_permissions : {}

  principal                     = each.value.principal
  permissions                   = each.value.permissions
  permissions_with_grant_option = try(each.value.permissions_with_grant_option, [])
  catalog_id                    = var.catalog_id

  database {
    name       = each.value.database_name
    catalog_id = try(each.value.catalog_id, var.catalog_id)
  }
}

################################################################################
# Table Permissions
################################################################################

resource "aws_lakeformation_permissions" "table" {
  for_each = local.enabled ? var.table_permissions : {}

  principal                     = each.value.principal
  permissions                   = each.value.permissions
  permissions_with_grant_option = try(each.value.permissions_with_grant_option, [])
  catalog_id                    = var.catalog_id

  table {
    database_name = each.value.database_name
    name          = try(each.value.table_name, null)
    wildcard      = try(each.value.wildcard, null)
    catalog_id    = try(each.value.catalog_id, var.catalog_id)
  }
}

################################################################################
# Table with Columns Permissions
################################################################################

resource "aws_lakeformation_permissions" "table_with_columns" {
  for_each = local.enabled ? var.table_with_columns_permissions : {}

  principal                     = each.value.principal
  permissions                   = each.value.permissions
  permissions_with_grant_option = try(each.value.permissions_with_grant_option, [])
  catalog_id                    = var.catalog_id

  table_with_columns {
    database_name         = each.value.database_name
    name                  = each.value.table_name
    column_names          = try(each.value.column_names, null)
    wildcard              = try(each.value.wildcard, null)
    excluded_column_names = try(each.value.excluded_column_names, null)
    catalog_id            = try(each.value.catalog_id, var.catalog_id)
  }
}

################################################################################
# LF-Tag Permissions (Tag-Based Access Control)
################################################################################

resource "aws_lakeformation_permissions" "lf_tag" {
  for_each = local.enabled ? var.lf_tag_permissions : {}

  principal                     = each.value.principal
  permissions                   = each.value.permissions
  permissions_with_grant_option = try(each.value.permissions_with_grant_option, [])
  catalog_id                    = var.catalog_id

  lf_tag {
    key        = each.value.key
    values     = each.value.values
    catalog_id = try(each.value.catalog_id, var.catalog_id)
  }
}

################################################################################
# LF-Tag Policy Permissions
################################################################################

resource "aws_lakeformation_permissions" "lf_tag_policy" {
  for_each = local.enabled ? var.lf_tag_policy_permissions : {}

  principal                     = each.value.principal
  permissions                   = each.value.permissions
  permissions_with_grant_option = try(each.value.permissions_with_grant_option, [])
  catalog_id                    = var.catalog_id

  lf_tag_policy {
    resource_type = each.value.resource_type
    catalog_id    = try(each.value.catalog_id, var.catalog_id)

    dynamic "expression" {
      for_each = each.value.expression

      content {
        key    = expression.value.key
        values = expression.value.values
      }
    }
  }
}

################################################################################
# Data Filter (Row/Cell-Level Security)
################################################################################

resource "aws_lakeformation_data_cells_filter" "this" {
  for_each = local.enabled ? var.data_cells_filters : {}

  table_data {
    database_name    = each.value.database_name
    table_name       = each.value.table_name
    name             = each.key
    table_catalog_id = try(each.value.catalog_id, var.catalog_id)

    dynamic "column_wildcard" {
      for_each = try(each.value.column_wildcard, null) != null ? [each.value.column_wildcard] : []

      content {
        excluded_column_names = try(column_wildcard.value.excluded_column_names, null)
      }
    }

    column_names = try(each.value.column_names, null)
    version_id   = try(each.value.version_id, null)

    dynamic "row_filter" {
      for_each = try(each.value.row_filter, null) != null ? [each.value.row_filter] : []

      content {
        filter_expression = try(row_filter.value.filter_expression, null)

        dynamic "all_rows_wildcard" {
          for_each = try(row_filter.value.all_rows_wildcard, false) ? [1] : []
          content {}
        }
      }
    }
  }
}

################################################################################
# Resource LF-Tag Associations
################################################################################

resource "aws_lakeformation_resource_lf_tag" "database" {
  for_each = local.enabled ? var.database_lf_tag_associations : {}

  database {
    name       = each.value.database_name
    catalog_id = try(each.value.catalog_id, var.catalog_id)
  }

  dynamic "lf_tag" {
    for_each = each.value.lf_tags

    content {
      key        = lf_tag.value.key
      value      = lf_tag.value.value
      catalog_id = try(lf_tag.value.catalog_id, var.catalog_id)
    }
  }
}

resource "aws_lakeformation_resource_lf_tag" "table" {
  for_each = local.enabled ? var.table_lf_tag_associations : {}

  table {
    database_name = each.value.database_name
    name          = each.value.table_name
    catalog_id    = try(each.value.catalog_id, var.catalog_id)
  }

  dynamic "lf_tag" {
    for_each = each.value.lf_tags

    content {
      key        = lf_tag.value.key
      value      = lf_tag.value.value
      catalog_id = try(lf_tag.value.catalog_id, var.catalog_id)
    }
  }
}
