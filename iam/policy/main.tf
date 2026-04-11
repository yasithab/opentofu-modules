locals {
  enabled = var.enabled
  tags    = merge(var.tags, { ManagedBy = "opentofu" })

  # Use the explicit policy JSON if provided; otherwise merge policy_documents
  use_policy_documents = var.policy == null && length(var.policy_documents) > 0
  policy_json          = local.use_policy_documents ? try(data.aws_iam_policy_document.merged[0].json, "") : var.policy
}

data "aws_iam_policy_document" "merged" {
  count                     = local.enabled && local.use_policy_documents ? 1 : 0
  override_policy_documents = var.policy_documents
}

resource "aws_iam_policy" "this" {
  name        = var.name_prefix == null ? var.name : null
  name_prefix = var.name_prefix
  description = var.description
  path        = var.path
  policy      = local.policy_json
  tags        = local.tags

  lifecycle {
    enabled = local.enabled
  }
}
