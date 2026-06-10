# Amazon EKS

OpenTofu module for provisioning and managing Amazon Elastic Kubernetes Service (EKS) clusters with support for managed node groups, self-managed node groups, Fargate profiles, and EKS Auto Mode.

## Features

- **EKS Cluster** - Fully managed Kubernetes control plane with configurable version, logging, encryption, and endpoint access controls
- **EKS Auto Mode** - Support for EKS Auto Mode compute configuration with automated node pool management
- **Managed Node Groups** - EKS managed node groups with customizable instance types, scaling, and launch templates
- **Self-Managed Node Groups** - Self-managed node groups for advanced use cases requiring custom AMIs or configurations
- **Fargate Profiles** - Serverless Kubernetes pods with configurable namespace and label selectors
- **Cluster Addons** - Declarative management of EKS addons (VPC CNI, CoreDNS, kube-proxy, etc.) with before-compute ordering support
- **Access Management** - API-based access entries and policy associations with optional cluster creator admin permissions
- **IRSA** - OpenID Connect (OIDC) provider for IAM Roles for Service Accounts with dual-stack support
- **Encryption** - KMS key creation and management for Kubernetes secrets encryption with configurable key policies
- **Security Groups** - Separate cluster and node security groups with recommended rules and customizable additional rules
- **CloudWatch Logging** - Control plane logging with configurable log group retention, encryption, and deletion protection
- **Identity Providers** - External OIDC identity provider integration for cluster authentication
- **Outpost Support** - Deploy EKS clusters on AWS Outposts for on-premises Kubernetes workloads
- **Provisioned Control Plane** - Configure control plane scaling tier via `control_plane_scaling_config` for dedicated capacity
- **EKS Auto Mode** - Automated node pool management via `cluster_compute_config` with configurable node pools and node role

## Usage

```hcl
module "eks" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks?depth=1&ref=master"

  name            = "my-cluster"
  cluster_version = "1.31"

  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0a1b2c3d", "subnet-4e5f6a7b"]

  eks_managed_node_groups = {
    default = {
      instance_types = ["m6i.large"]
      min_size       = 2
      max_size       = 5
      desired_size   = 3
    }
  }

  tags = {
    Environment = "production"
  }
}
```


## Examples

## Basic Usage

Minimal EKS cluster with private API endpoint and managed node group using EKS Auto Mode defaults.

```hcl
module "eks" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks?depth=1&ref=master"

  enabled         = true
  name            = "my-cluster"
  cluster_version = "1.32"

  vpc_id     = "vpc-0abc123def456789"
  subnet_ids = ["subnet-0aaa111", "subnet-0bbb222", "subnet-0ccc333"]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## With Managed Node Groups

EKS cluster with a dedicated EKS managed node group, KMS encryption, and control plane logging.

```hcl
module "eks" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks?depth=1&ref=master"

  enabled         = true
  name            = "app-cluster"
  cluster_version = "1.32"

  vpc_id                        = "vpc-0abc123def456789"
  subnet_ids                    = ["subnet-0aaa111", "subnet-0bbb222", "subnet-0ccc333"]
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false

  cluster_enabled_log_types               = ["audit", "api", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days  = 90

  create_kms_key             = true
  enable_kms_key_rotation    = true
  cluster_encryption_config  = { resources = ["secrets"] }

  eks_managed_node_groups = {
    general = {
      name           = "general"
      instance_types = ["m6i.large"]
      min_size       = 2
      max_size       = 6
      desired_size   = 2
      ami_type       = "AL2023_x86_64_STANDARD"
    }
  }

  tags = {
    Environment = "production"
    CostCenter  = "platform"
  }
}
```

## With Fargate Profiles and IRSA

EKS cluster using Fargate for serverless node compute with IRSA enabled for pod-level IAM.

```hcl
module "eks" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks?depth=1&ref=master"

  enabled         = true
  name            = "serverless-cluster"
  cluster_version = "1.32"

  vpc_id     = "vpc-0abc123def456789"
  subnet_ids = ["subnet-0aaa111", "subnet-0bbb222"]

  enable_irsa = true

  fargate_profiles = {
    kube_system = {
      name = "kube-system"
      selectors = [
        { namespace = "kube-system" }
      ]
    }
    app = {
      name = "app"
      selectors = [
        { namespace = "app", labels = { fargate = "true" } }
      ]
    }
  }

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  tags = {
    Environment = "staging"
    Team        = "platform"
  }
}
```

## Advanced - Multi-Node-Group with Access Entries and Cluster Upgrade Policy

Production-grade cluster with multiple node groups, access entries for IAM roles, and a configured upgrade policy.

```hcl
module "eks" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks?depth=1&ref=master"

  enabled         = true
  name            = "prod-cluster"
  cluster_version = "1.32"

  vpc_id                        = "vpc-0abc123def456789"
  subnet_ids                    = ["subnet-0aaa111", "subnet-0bbb222", "subnet-0ccc333"]
  control_plane_subnet_ids      = ["subnet-0ddd444", "subnet-0eee555", "subnet-0fff666"]
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false
  cluster_deletion_protection     = true

  authentication_mode = "API_AND_CONFIG_MAP"

  cluster_upgrade_policy = {
    support_type = "STANDARD"
  }

  access_entries = {
    admin_role = {
      principal_arn = "arn:aws:iam::123456789012:role/PlatformAdminRole"
      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }

  eks_managed_node_groups = {
    system = {
      name           = "system"
      instance_types = ["m6i.large"]
      min_size       = 2
      max_size       = 4
      desired_size   = 2
      ami_type       = "AL2023_x86_64_STANDARD"
      labels         = { role = "system" }
    }
    app = {
      name           = "app"
      instance_types = ["m6i.xlarge", "m6a.xlarge"]
      min_size       = 3
      max_size       = 20
      desired_size   = 3
      capacity_type  = "ON_DEMAND"
      ami_type       = "AL2023_x86_64_STANDARD"
      labels         = { role = "app" }
    }
    spot = {
      name           = "spot"
      instance_types = ["m6i.large", "m5.large", "m5a.large"]
      min_size       = 0
      max_size       = 10
      desired_size   = 2
      capacity_type  = "SPOT"
      ami_type       = "AL2023_x86_64_STANDARD"
      labels         = { role = "spot" }
      taints = {
        spot = {
          key    = "spot"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    CostCenter  = "platform"
  }
}
```

## Notes

- **Typed inputs**: all configuration inputs use typed `object()`/`map(object())` schemas with `optional()` attributes — unknown keys are rejected at plan time. Single-block configurations (`cluster_compute_config`, `cluster_upgrade_policy`, `cluster_remote_network_config`, `cluster_zonal_shift_config`, `outpost_config`, `cluster_encryption_config`) are disabled by setting them to `null` (not `{}`).
- **Secret encryption**: `cluster_encryption_config` defaults to encrypting `secrets` with a module-managed KMS key. To disable envelope encryption, set `cluster_encryption_config = null`.
- **Deletion protection**: `cluster_deletion_protection` defaults to `true`. Set it to `false` explicitly before destroying a cluster.
- **Control plane logging**: `cluster_enabled_log_types` defaults to all five log types (`api`, `audit`, `authenticator`, `controllerManager`, `scheduler`). Override the list to reduce CloudWatch costs if needed.
- **Self-managed node group AMI**: the default `ami_type` for self-managed node groups is `AL2023_x86_64_STANDARD` (AL2 reached end of standard support). Set `ami_type` explicitly to keep existing AL2 groups unchanged.
- **Addon version drift**: cluster addons default to `most_recent = true`, which resolves the addon version at plan time. As AWS publishes new addon versions, subsequent plans will show version updates (drift). Pin `addon_version` (or set `most_recent = false`) per addon for fully reproducible plans.
- **IPv6 CNI policy name**: when `create_cni_ipv6_iam_policy = true`, the policy is named `AmazonEKS_CNI_IPv6_Policy` by default. Use `cni_ipv6_iam_policy_name` to avoid name conflicts when multiple clusters in one account create this policy.
