locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# Database
################################################################################

resource "aws_timestreamwrite_database" "this" {
  database_name = var.name
  kms_key_id    = var.kms_key_id

  tags = merge(local.tags, { Name = var.name })

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# Tables
################################################################################

resource "aws_timestreamwrite_table" "this" {
  for_each = { for k, v in var.tables : k => v if local.enabled }

  database_name = aws_timestreamwrite_database.this.database_name
  table_name    = each.value.table_name

  retention_properties {
    memory_store_retention_period_in_hours  = try(each.value.memory_store_retention_hours, var.default_memory_store_retention_hours)
    magnetic_store_retention_period_in_days = try(each.value.magnetic_store_retention_days, var.default_magnetic_store_retention_days)
  }

  dynamic "magnetic_store_write_properties" {
    for_each = try(each.value.magnetic_store_write_properties, null) != null ? [each.value.magnetic_store_write_properties] : (var.enable_magnetic_store_writes ? [{}] : [])

    content {
      enable_magnetic_store_writes = try(magnetic_store_write_properties.value.enable_magnetic_store_writes, true)

      dynamic "magnetic_store_rejected_data_location" {
        for_each = try([magnetic_store_write_properties.value.magnetic_store_rejected_data_location], [])

        content {
          s3_configuration {
            bucket_name       = try(magnetic_store_rejected_data_location.value.s3_bucket_name, null)
            encryption_option = try(magnetic_store_rejected_data_location.value.s3_encryption_option, null)
            kms_key_id        = try(magnetic_store_rejected_data_location.value.s3_kms_key_id, null)
            object_key_prefix = try(magnetic_store_rejected_data_location.value.s3_object_key_prefix, null)
          }
        }
      }
    }
  }

  dynamic "schema" {
    for_each = try(each.value.schema, null) != null ? [each.value.schema] : []

    content {
      dynamic "composite_partition_key" {
        for_each = try(schema.value.composite_partition_key, null) != null ? [schema.value.composite_partition_key] : []

        content {
          enforcement_in_record = try(composite_partition_key.value.enforcement_in_record, null)
          name                  = try(composite_partition_key.value.name, null)
          type                  = try(composite_partition_key.value.type, "DIMENSION")
        }
      }
    }
  }

  tags = merge(local.tags, try(each.value.tags, {}))
}
