manage_aws_auth_configmap = true

aws_auth_roles = [
  {
    rolearn  = "arn:aws:iam::123456789012:role/terratest-node-role"
    username = "system:node:{{EC2PrivateDNSName}}"
    groups   = ["system:bootstrappers", "system:nodes"]
  },
]

aws_auth_users = [
  {
    userarn  = "arn:aws:iam::123456789012:user/terratest-admin"
    username = "terratest-admin"
    groups   = ["system:masters"]
  },
]

aws_auth_accounts = ["123456789012"]
