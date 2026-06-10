locals {
  enabled = var.enabled

  create_account_pack      = local.enabled && !var.create_organization_conformance_pack
  create_organization_pack = local.enabled && var.create_organization_conformance_pack

  # Exactly one template source must be supplied.
  template_source_valid = (var.template_body != null) != (var.template_s3_uri != null)
}

# -- Account-level Conformance Pack -------------------------------------------

resource "aws_config_conformance_pack" "this" {
  lifecycle {
    enabled = local.create_account_pack

    precondition {
      condition     = !local.create_account_pack || local.template_source_valid
      error_message = "Exactly one of template_body or template_s3_uri must be provided."
    }
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
    enabled = local.create_organization_pack

    precondition {
      condition     = !local.create_organization_pack || local.template_source_valid
      error_message = "Exactly one of template_body or template_s3_uri must be provided."
    }

    precondition {
      condition     = !local.create_organization_pack || var.delivery_s3_bucket != null
      error_message = "delivery_s3_bucket is required for organization conformance packs."
    }
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
