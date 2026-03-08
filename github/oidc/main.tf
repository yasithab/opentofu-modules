locals {
  enabled = var.enabled

  # For GitHub Actions OIDC (token.actions.githubusercontent.com), AWS retrieves
  # thumbprints automatically from its trusted CA library, so an empty list is valid.
  # For other providers, if thumbprint_list is empty and the provider is not GitHub,
  # AWS will auto-fetch the top intermediate CA thumbprint on initial creation.
  github_default_thumbprints = []

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

resource "aws_iam_openid_connect_provider" "this" {
  for_each = local.enabled ? var.openid_providers : {}

  url            = each.value.url
  client_id_list = each.value.client_id_list
  # For GitHub Actions OIDC, AWS validates tokens via its own trusted CA library,
  # so thumbprint_list can be empty. For other providers, use caller-supplied thumbprints.
  thumbprint_list = length(each.value.thumbprint_list) > 0 ? each.value.thumbprint_list : (
    can(regex("token\\.actions\\.githubusercontent\\.com", each.value.url)) ? local.github_default_thumbprints : each.value.thumbprint_list
  )

  tags = merge(local.tags, {
    Terraform = "true"
    Provider  = each.key
  }, each.value.tags)
}
