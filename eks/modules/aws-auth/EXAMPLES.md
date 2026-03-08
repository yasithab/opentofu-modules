# EKS aws-auth Module - Examples

## Basic Usage

Manage the `aws-auth` ConfigMap to grant IAM roles access to an EKS cluster.

```hcl
module "aws_auth" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/aws-auth?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/aws-auth?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/aws-auth?depth=1&ref=v2.0.0"

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
    {
      account = "987654321098"
    }
  ]
}
```
