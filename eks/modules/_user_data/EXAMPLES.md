# EKS _user_data Module - Examples

## Basic Usage

Generate default user data for an AL2023 EKS managed node group (bootstrap is handled by EKS; no custom data needed).

```hcl
module "user_data" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/_user_data?depth=1&ref=v2.0.0"

  enabled      = true
  cluster_name = "my-cluster"
  ami_type     = "AL2023_x86_64_STANDARD"

  is_eks_managed_node_group = true
}
```

## With Custom Bootstrap for Self-Managed Nodes

Inject pre- and post-bootstrap scripts into user data for AL2 (Amazon Linux 2) self-managed nodes.

```hcl
module "user_data" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/_user_data?depth=1&ref=v2.0.0"

  enabled      = true
  platform     = "linux"
  ami_type     = "AL2_x86_64"

  cluster_name        = "my-cluster"
  cluster_endpoint    = "https://ABCDEF1234567890.gr7.ap-southeast-1.eks.amazonaws.com"
  cluster_auth_base64 = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t..."
  cluster_service_cidr = "172.20.0.0/16"

  is_eks_managed_node_group    = false
  enable_bootstrap_user_data   = true

  pre_bootstrap_user_data = <<-EOT
    #!/bin/bash
    yum install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
  EOT

  bootstrap_extra_args = "--use-max-pods false --kubelet-extra-args '--max-pods=110'"
}
```

## With Bottlerocket AMI

Generate user data for Bottlerocket OS nodes with additional TOML settings.

```hcl
module "user_data" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/_user_data?depth=1&ref=v2.0.0"

  enabled      = true
  ami_type     = "BOTTLEROCKET_x86_64"

  cluster_name        = "my-cluster"
  cluster_endpoint    = "https://ABCDEF1234567890.gr7.ap-southeast-1.eks.amazonaws.com"
  cluster_auth_base64 = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t..."
  cluster_service_cidr = "172.20.0.0/16"

  is_eks_managed_node_group  = false
  enable_bootstrap_user_data = true

  bootstrap_extra_args = <<-EOT
    [settings.host-containers.admin]
    enabled = true
    [settings.kernel.sysctl]
    "vm.max_map_count" = "262144"
  EOT
}
```

## With cloud-init Parts for AL2023 nodeadm

Inject cloud-init documents before and after the AL2023 nodeadm bootstrap step.

```hcl
module "user_data" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/_user_data?depth=1&ref=v2.0.0"

  enabled      = true
  ami_type     = "AL2023_x86_64_STANDARD"

  cluster_name        = "my-cluster"
  cluster_endpoint    = "https://ABCDEF1234567890.gr7.ap-southeast-1.eks.amazonaws.com"
  cluster_auth_base64 = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t..."
  cluster_service_cidr = "172.20.0.0/16"

  is_eks_managed_node_group  = false
  enable_bootstrap_user_data = true

  cloudinit_pre_nodeadm = [
    {
      content_type = "text/x-shellscript"
      content      = <<-EOT
        #!/bin/bash
        echo "Pre-bootstrap setup"
        mkdir -p /etc/containerd
      EOT
    }
  ]

  cloudinit_post_nodeadm = [
    {
      content_type = "text/x-shellscript"
      content      = <<-EOT
        #!/bin/bash
        echo "Post-bootstrap setup"
        systemctl restart containerd
      EOT
    }
  ]
}
```
