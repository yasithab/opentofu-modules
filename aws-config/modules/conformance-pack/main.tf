locals {
  create = var.enabled
}

# -- Account-level Conformance Pack -------------------------------------------

resource "aws_config_conformance_pack" "this" {
  lifecycle {
    enabled = local.create && !var.create_organization_conformance_pack
  }

  name                   = var.name
  template_body          = var.template_body
  template_s3_uri        = var.template_s3_uri
  delivery_s3_bucket     = var.delivery_s3_bucket
  delivery_s3_key_prefix = var.delivery_s3_key_prefix

  dynamic "input_parameter" {
    for_each = var.input_parameters
    content {
      parameter_name  = input_parameter.key
      parameter_value = input_parameter.value
    }
  }
}

# -- Organization Conformance Pack --------------------------------------------

resource "aws_config_organization_conformance_pack" "this" {
  lifecycle {
    enabled = local.create && var.create_organization_conformance_pack
  }

  name                   = var.name
  template_body          = var.template_body
  template_s3_uri        = var.template_s3_uri
  delivery_s3_bucket     = var.delivery_s3_bucket
  delivery_s3_key_prefix = var.delivery_s3_key_prefix
  excluded_accounts      = length(var.excluded_account_ids) > 0 ? var.excluded_account_ids : null

  dynamic "input_parameter" {
    for_each = var.input_parameters
    content {
      parameter_name  = input_parameter.key
      parameter_value = input_parameter.value
    }
  }
}
