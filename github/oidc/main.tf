locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

resource "aws_iam_openid_connect_provider" "this" {
  for_each = local.enabled ? var.openid_providers : {}

  url            = each.value.url
  client_id_list = each.value.client_id_list
  # An empty thumbprint_list is valid: for GitHub Actions OIDC
  # (token.actions.githubusercontent.com) AWS validates tokens via its own trusted
  # CA library, and for other providers AWS auto-fetches the top intermediate CA
  # thumbprint on initial creation.
  thumbprint_list = each.value.thumbprint_list

  tags = merge(local.tags, {
    Provider = each.key
  }, each.value.tags)
}
