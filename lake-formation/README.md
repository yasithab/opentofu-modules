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
