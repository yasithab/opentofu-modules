# EKS User Data

Internal submodule that generates platform-specific user data for EKS node groups. It renders bootstrap scripts for AL2, AL2023, Bottlerocket, and Windows AMI types, supporting both EKS managed and self-managed node groups.

## Features

- **Multi-platform support** - Automatically selects the correct user data template based on AMI type (AL2, AL2023, Bottlerocket, Windows)
- **Bootstrap configuration** - Injects cluster name, endpoint, and certificate authority into node bootstrap scripts
- **Custom user data hooks** - Supports pre-bootstrap and post-bootstrap user data injection
- **Cloud-init integration** - Renders MIME multi-part archives for EKS managed node groups on AL2 and AL2023
- **Nodeadm support** - Handles AL2023 nodeadm cloud-init configuration with pre and post nodeadm hooks
- **Custom templates** - Allows overriding the default user data template with a custom template path

## Usage

```hcl
module "user_data" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/_user_data?depth=1&ref=master"

  cluster_name         = "my-cluster"
  cluster_endpoint     = "https://ABCDEF.gr7.us-east-1.eks.amazonaws.com"
  cluster_auth_base64  = "base64encodedca..."
  cluster_service_cidr = "172.20.0.0/16"
  ami_type             = "AL2023_x86_64_STANDARD"

  enable_bootstrap_user_data = true
  pre_bootstrap_user_data    = "#!/bin/bash\necho 'before bootstrap'"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enabled | Set to false to prevent the module from creating any resources or generating user data | `bool` | `true` | no |
| platform | Identifies the OS platform as `bottlerocket`, `linux`, `al2023`, or `windows`. Used as a fallback when ami_type cannot be determined | `string` | `null` | no |
| ami_type | Type of Amazon Machine Image (AMI) associated with the EKS Node Group | `string` | `null` | no |
| is_eks_managed_node_group | Determines whether the user data is used on nodes in an EKS managed node group | `bool` | `true` | no |
| cluster_name | Name of the EKS cluster | `string` | `null` | no |
| cluster_endpoint | Endpoint of the EKS cluster | `string` | `null` | no |
| cluster_auth_base64 | Base64 encoded CA of associated EKS cluster | `string` | `null` | no |
| cluster_ip_family | The IP family used to assign Kubernetes pod and service addresses | `string` | `"ipv4"` | no |
| cluster_service_cidr | The CIDR block used to assign Kubernetes pod and service IP addresses | `string` | `null` | no |
| additional_cluster_dns_ips | Additional DNS IP addresses to add to the cluster DNS configuration | `list(string)` | `[]` | no |
| enable_bootstrap_user_data | Determines whether the provided user data will be merged with the EKS bootstrap user data | `bool` | `false` | no |
| pre_bootstrap_user_data | User data injected ahead of the EKS bootstrap script | `string` | `null` | no |
| post_bootstrap_user_data | User data appended after the EKS bootstrap script | `string` | `null` | no |
| bootstrap_extra_args | Additional arguments to pass to the EKS bootstrap script | `string` | `null` | no |
| user_data_template_path | Path to a custom user data template file | `string` | `null` | no |
| cloudinit_pre_nodeadm | Additional cloud-init configuration to merge before nodeadm bootstrap | `list(object)` | `[]` | no |
| cloudinit_post_nodeadm | Additional cloud-init configuration to merge after nodeadm bootstrap | `list(object)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| user_data | Base64 encoded user data rendered for the provided inputs |
| platform | Identifies the OS platform as `bottlerocket`, `linux`, `al2023`, or `windows` |


## Examples

## Basic Usage

Generate default user data for an AL2023 EKS managed node group (bootstrap is handled by EKS; no custom data needed).

```hcl
module "user_data" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/_user_data?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/_user_data?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/_user_data?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/_user_data?depth=1&ref=master"

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
