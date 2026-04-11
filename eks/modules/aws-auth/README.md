# EKS aws-auth ConfigMap

Submodule for managing the `aws-auth` ConfigMap in an EKS cluster. This ConfigMap controls IAM-to-Kubernetes RBAC mappings, allowing IAM roles, users, and accounts to authenticate with the cluster.

## Features

- **ConfigMap creation** - Optionally creates the `aws-auth` ConfigMap for scenarios where it does not yet exist (e.g., self-managed node groups only)
- **ConfigMap management** - Manages the data within an existing `aws-auth` ConfigMap without recreating it
- **IAM role mapping** - Maps IAM roles to Kubernetes RBAC groups via `mapRoles`
- **IAM user mapping** - Maps IAM users to Kubernetes RBAC groups via `mapUsers`
- **Account mapping** - Maps AWS account IDs to Kubernetes RBAC groups via `mapAccounts`

## Usage

```hcl
module "aws_auth" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/aws-auth?depth=1&ref=master"

  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::123456789012:role/my-node-role"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    },
  ]

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::123456789012:user/admin"
      username = "admin"
      groups   = ["system:masters"]
    },
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enabled | Controls if resources should be created | `bool` | `true` | no |
| create_aws_auth_configmap | Determines whether to create the aws-auth ConfigMap. Only intended for scenarios where it does not exist | `bool` | `false` | no |
| manage_aws_auth_configmap | Determines whether to manage the aws-auth ConfigMap | `bool` | `true` | no |
| aws_auth_roles | List of role maps to add to the aws-auth ConfigMap | `list(any)` | `[]` | no |
| aws_auth_users | List of user maps to add to the aws-auth ConfigMap | `list(any)` | `[]` | no |
| aws_auth_accounts | List of account maps to add to the aws-auth ConfigMap | `list(any)` | `[]` | no |


## Examples

## Basic Usage

Manage the `aws-auth` ConfigMap to grant IAM roles access to an EKS cluster.

```hcl
module "aws_auth" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/aws-auth?depth=1&ref=master"

  enabled                 = true
  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::123456789012:role/NodeGroupRole"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    }
  ]
}
```

## With Admin IAM Roles and Users

Grant cluster-admin access to multiple IAM roles and individual IAM users.

```hcl
module "aws_auth" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/aws-auth?depth=1&ref=master"

  enabled                   = true
  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::123456789012:role/NodeGroupRole"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    },
    {
      rolearn  = "arn:aws:iam::123456789012:role/PlatformAdminRole"
      username = "platform-admin"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::123456789012:role/ReadOnlyRole"
      username = "readonly"
      groups   = ["eks-readonly"]
    }
  ]

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::123456789012:user/jsmith"
      username = "jsmith"
      groups   = ["system:masters"]
    }
  ]
}
```

## Creating the ConfigMap for Self-Managed Node Groups

Create the `aws-auth` ConfigMap from scratch when it does not yet exist (self-managed node groups only scenario).

```hcl
module "aws_auth" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/aws-auth?depth=1&ref=master"

  enabled                    = true
  create_aws_auth_configmap  = true
  manage_aws_auth_configmap  = true

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::123456789012:role/SelfManagedNodeRole"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    },
    {
      rolearn  = "arn:aws:iam::123456789012:role/PlatformAdminRole"
      username = "platform-admin"
      groups   = ["system:masters"]
    }
  ]

  aws_auth_accounts = [
    "987654321098"
  ]
}
```
