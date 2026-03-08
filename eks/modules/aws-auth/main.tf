
################################################################################
# aws-auth configmap
################################################################################

locals {
  aws_auth_configmap_data = {
    mapRoles    = yamlencode(var.aws_auth_roles)
    mapUsers    = yamlencode(var.aws_auth_users)
    mapAccounts = yamlencode(var.aws_auth_accounts)
  }
}

moved {
  from = kubernetes_config_map.aws_auth
  to   = kubernetes_config_map_v1.aws_auth
}

resource "kubernetes_config_map_v1" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = local.aws_auth_configmap_data

  lifecycle {
    enabled = var.enabled && var.create_aws_auth_configmap
    # We are ignoring the data here since we will manage it with the resource below
    # This is only intended to be used in scenarios where the configmap does not exist
    ignore_changes = [data, metadata[0].labels, metadata[0].annotations]
  }
}

resource "kubernetes_config_map_v1_data" "aws_auth" {
  force = true

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = local.aws_auth_configmap_data

  depends_on = [
    # Required for instances where the configmap does not exist yet to avoid race condition
    kubernetes_config_map_v1.aws_auth,
  ]

  lifecycle {
    enabled = var.enabled && var.manage_aws_auth_configmap
  }
}
