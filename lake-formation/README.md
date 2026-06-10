# AWS Lake Formation

OpenTofu module for provisioning and managing AWS Lake Formation with support for data lake settings, resource registration, fine-grained permissions, LF-Tags, and row/cell-level security.

> **Note — data lake settings are opt-in:** `aws_lakeformation_data_lake_settings` is **account/catalog-wide** — applying it overwrites the *entire* settings object, including administrators configured outside this module. The resource is therefore gated behind `manage_data_lake_settings` (default `false`), and when it is `true` the module requires a non-empty `admin_arns`. If you only use this module for permissions/LF-Tags/resource registration, leave the default — account settings stay unmanaged.

> **Note — no `tags` input:** this module is exempt from the repository-wide `tags`/`ManagedBy` convention. Lake Formation settings, permissions, LF-Tags, and data cells filters do not support AWS resource tags (LF-Tags are an access-control construct, not resource tags), so there is nothing to tag.

## Features

- **Data Lake Settings** - Configure Lake Formation administrators, default permissions, and external data filtering controls
- **Resource Registration** - Register S3 data locations with Lake Formation using IAM roles or the service-linked role
- **Database Permissions** - Grant and manage database-level access control for IAM principals
- **Table Permissions** - Grant table-level permissions with optional wildcard support for all tables
- **Column-Level Permissions** - Fine-grained column-level access with inclusion or exclusion lists
- **LF-Tags** - Create and manage tag-based access control keys with allowed value sets
- **LF-Tag Policies** - Define tag-based permission policies for databases and tables
- **Data Cells Filters** - Row and cell-level security filters for granular data access control
- **Resource Tagging** - Associate LF-Tags with databases and tables for tag-based governance
- **Cross-Account** - Support for trusted resource owners and external data filtering allow lists

## Usage

```hcl
module "lake_formation" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lake-formation?depth=1&ref=master"

  manage_data_lake_settings = true
  admin_arns                = ["arn:aws:iam::123456789012:role/DataLakeAdmin"]
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11.0 |
| aws | >= 6.49, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| admin\_arns | List of IAM principal ARNs to grant Lake Formation administrator privileges | `list(string)` | `[]` | no |
| allow\_external\_data\_filtering | Whether to allow external engines to filter data in Amazon S3 locations registered with Lake Formation | `bool` | `false` | no |
| allow\_full\_table\_external\_data\_access | Whether to allow external engines to access full tables registered with Lake Formation | `bool` | `false` | no |
| authorized\_session\_tag\_value\_list | List of allowed session tag values for third-party engines | `list(string)` | `[]` | no |
| catalog\_id | AWS account ID for the Glue Data Catalog. Defaults to the caller's account | `string` | `null` | no |
| create\_database\_default\_permissions | Default permissions for newly created databases. Object with 'permissions' (list) and 'principal' (string) | <pre>object({<br/>    permissions = optional(list(string), ["ALL"])<br/>    principal   = optional(string)<br/>  })</pre> | `null` | no |
| create\_table\_default\_permissions | Default permissions for newly created tables. Object with 'permissions' (list) and 'principal' (string) | <pre>object({<br/>    permissions = optional(list(string), ["ALL"])<br/>    principal   = optional(string)<br/>  })</pre> | `null` | no |
| data\_cells\_filters | Map of data cells filters for row/cell-level security. Key is the filter name. Each value needs 'database\_name', 'table\_name', and either 'column\_names' or 'column\_wildcard', plus optional 'row\_filter' | <pre>map(object({<br/>    database_name = string<br/>    table_name    = string<br/>    column_names  = optional(list(string))<br/>    column_wildcard = optional(object({<br/>      excluded_column_names = optional(list(string))<br/>    }))<br/>    row_filter = optional(string)<br/>    catalog_id = optional(string)<br/>    version_id = optional(string)<br/>  }))</pre> | `{}` | no |
| database\_lf\_tag\_associations | Map of database-level LF-Tag associations. Each value needs 'database\_name' and 'lf\_tags' (list of key/value pairs) | <pre>map(object({<br/>    database_name = string<br/>    catalog_id    = optional(string)<br/>    lf_tags = list(object({<br/>      key        = string<br/>      value      = string<br/>      catalog_id = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| database\_permissions | Map of database-level permissions to grant. Each value needs 'principal', 'permissions', 'database\_name', and optionally 'permissions\_with\_grant\_option' | <pre>map(object({<br/>    principal                     = string<br/>    permissions                   = list(string)<br/>    database_name                 = string<br/>    permissions_with_grant_option = optional(list(string), [])<br/>    catalog_id                    = optional(string)<br/>  }))</pre> | `{}` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| external\_data\_filtering\_allow\_list | List of account IDs allowed to perform external data filtering | `list(string)` | `[]` | no |
| lf\_tag\_permissions | Map of LF-Tag permissions to grant. Each value needs 'principal', 'permissions', 'key', and 'values' | <pre>map(object({<br/>    principal                     = string<br/>    permissions                   = list(string)<br/>    key                           = string<br/>    values                        = list(string)<br/>    permissions_with_grant_option = optional(list(string), [])<br/>    catalog_id                    = optional(string)<br/>  }))</pre> | `{}` | no |
| lf\_tag\_policy\_permissions | Map of LF-Tag policy-based permissions. Each value needs 'principal', 'permissions', 'resource\_type' (DATABASE or TABLE), and 'expression' (list of key/values) | <pre>map(object({<br/>    principal                     = string<br/>    permissions                   = list(string)<br/>    resource_type                 = string<br/>    permissions_with_grant_option = optional(list(string), [])<br/>    catalog_id                    = optional(string)<br/>    expression = list(object({<br/>      key    = string<br/>      values = list(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| lf\_tags | Map of LF-Tags to create. Key is the tag key, value is a list of allowed tag values | `map(list(string))` | `{}` | no |
| manage\_data\_lake\_settings | Whether this module manages the account-level Lake Formation data lake settings (administrators, default permissions, external data filtering). Defaults to `false` because applying these settings overwrites the entire account/catalog configuration, including admins configured elsewhere. | `bool` | `false` | no |
| resources | Map of S3 resources to register with Lake Formation. Each value needs 'arn' and optionally 'role\_arn', 'use\_service\_linked\_role', 'hybrid\_access\_enabled' | <pre>map(object({<br/>    arn                     = string<br/>    role_arn                = optional(string)<br/>    use_service_linked_role = optional(bool)<br/>    hybrid_access_enabled   = optional(bool)<br/>  }))</pre> | `{}` | no |
| table\_lf\_tag\_associations | Map of table-level LF-Tag associations. Each value needs 'database\_name', 'table\_name', and 'lf\_tags' (list of key/value pairs) | <pre>map(object({<br/>    database_name = string<br/>    table_name    = string<br/>    catalog_id    = optional(string)<br/>    lf_tags = list(object({<br/>      key        = string<br/>      value      = string<br/>      catalog_id = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| table\_permissions | Map of table-level permissions to grant. Each value needs 'principal', 'permissions', 'database\_name', and either 'table\_name' or 'wildcard' | <pre>map(object({<br/>    principal                     = string<br/>    permissions                   = list(string)<br/>    database_name                 = string<br/>    table_name                    = optional(string)<br/>    wildcard                      = optional(bool)<br/>    permissions_with_grant_option = optional(list(string), [])<br/>    catalog_id                    = optional(string)<br/>  }))</pre> | `{}` | no |
| table\_with\_columns\_permissions | Map of column-level permissions to grant. Each value needs 'principal', 'permissions', 'database\_name', 'table\_name', and either 'column\_names' or 'wildcard' | <pre>map(object({<br/>    principal                     = string<br/>    permissions                   = list(string)<br/>    database_name                 = string<br/>    table_name                    = string<br/>    column_names                  = optional(list(string))<br/>    excluded_column_names         = optional(list(string))<br/>    wildcard                      = optional(bool)<br/>    permissions_with_grant_option = optional(list(string), [])<br/>    catalog_id                    = optional(string)<br/>  }))</pre> | `{}` | no |
| trusted\_resource\_owners | List of trusted resource owner account IDs to allow cross-account access | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| data\_cells\_filter\_names | Map of data cells filter keys to their names |
| data\_lake\_settings\_admins | List of Lake Formation administrator principal ARNs |
| data\_lake\_settings\_id | ID of the Lake Formation data lake settings (same as catalog ID) |
| database\_permission\_ids | Map of database permission keys to their IDs |
| lf\_tag\_keys | Map of LF-Tag keys to their values |
| resource\_arns | Map of registered resource keys to their ARNs |
| table\_permission\_ids | Map of table permission keys to their IDs |
| table\_with\_columns\_permission\_ids | Map of column-level permission keys to their IDs |
<!-- END_TF_DOCS -->

## Examples

### Basic Data Lake with Admin and S3 Registration

Set up Lake Formation with an admin role and register S3 data locations.

```hcl
module "lake_formation_basic" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lake-formation?depth=1&ref=master"

  enabled = true

  manage_data_lake_settings = true
  admin_arns = [
    "arn:aws:iam::123456789012:role/DataLakeAdmin",
    "arn:aws:iam::123456789012:role/DataEngineer"
  ]

  create_database_default_permissions = {
    permissions = []
  }

  create_table_default_permissions = {
    permissions = []
  }

  resources = {
    raw_data = {
      arn      = "arn:aws:s3:::data-lake-raw"
      role_arn = "arn:aws:iam::123456789012:role/LakeFormationDataAccess"
    }
    processed_data = {
      arn                     = "arn:aws:s3:::data-lake-processed"
      use_service_linked_role = true
    }
  }
}
```

### Tag-Based Access Control (TBAC)

Use LF-Tags to define and enforce fine-grained access policies across databases and tables.

```hcl
module "lake_formation_tbac" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lake-formation?depth=1&ref=master"

  enabled = true

  manage_data_lake_settings = true
  admin_arns                = ["arn:aws:iam::123456789012:role/DataLakeAdmin"]

  lf_tags = {
    environment = ["production", "staging", "development"]
    sensitivity = ["public", "internal", "confidential", "restricted"]
    domain      = ["sales", "engineering", "finance", "hr"]
  }

  database_lf_tag_associations = {
    sales_db = {
      database_name = "sales"
      lf_tags = [
        { key = "domain", value = "sales" },
        { key = "environment", value = "production" }
      ]
    }
  }

  lf_tag_policy_permissions = {
    analysts_sales = {
      principal     = "arn:aws:iam::123456789012:role/SalesAnalyst"
      permissions   = ["SELECT", "DESCRIBE"]
      resource_type = "TABLE"
      expression = [
        { key = "domain", values = ["sales"] },
        { key = "sensitivity", values = ["public", "internal"] }
      ]
    }
  }
}
```

### Row and Cell-Level Security

Apply data cells filters for row-level and column-level security on sensitive tables.

```hcl
module "lake_formation_security" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lake-formation?depth=1&ref=master"

  enabled = true

  manage_data_lake_settings = true
  admin_arns                = ["arn:aws:iam::123456789012:role/DataLakeAdmin"]

  database_permissions = {
    analyst_read = {
      principal     = "arn:aws:iam::123456789012:role/DataAnalyst"
      permissions   = ["DESCRIBE"]
      database_name = "customer_data"
    }
  }

  table_with_columns_permissions = {
    analyst_customer_limited = {
      principal     = "arn:aws:iam::123456789012:role/DataAnalyst"
      permissions   = ["SELECT"]
      database_name = "customer_data"
      table_name    = "customers"
      column_names  = ["customer_id", "name", "region", "signup_date"]
    }
  }

  data_cells_filters = {
    us_customers_only = {
      database_name = "customer_data"
      table_name    = "customers"
      column_names  = ["customer_id", "name", "region", "signup_date"]
      row_filter = {
        filter_expression = "region = 'US'"
      }
    }
    exclude_pii = {
      database_name = "customer_data"
      table_name    = "customers"
      column_wildcard = {
        excluded_column_names = ["ssn", "email", "phone_number"]
      }
      row_filter = {
        all_rows_wildcard = true
      }
    }
  }
}
```
