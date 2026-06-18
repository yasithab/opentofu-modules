data "aws_region" "current" {}

locals {
  enabled = var.enabled
  name    = var.name

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
    Region    = data.aws_region.current.region
  })
}

################################################################################
# ssm-document
################################################################################

resource "aws_ssm_document" "this" {
  name            = local.name
  document_type   = var.document_type
  document_format = var.document_format
  content         = var.content
  version_name    = var.version_name
  target_type     = var.target_type
  permissions     = var.permissions

  dynamic "attachments_source" {
    for_each = var.attachments_source
    content {
      key    = attachments_source.value.key
      values = attachments_source.value.values
      name   = attachments_source.value.name
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}
