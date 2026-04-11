# Karpenter Module

Configuration in this directory creates the AWS resources required by Karpenter

## Usage

### All Resources (Default)

In the following example, the Karpenter module will create:
- An IAM role for use with Pod Identity and a scoped IAM policy for the Karpenter controller
- A Pod Identity association to grant Karpenter controller access provided by the IAM Role
- A Node IAM role that Karpenter will use to create an Instance Profile for the nodes to receive IAM permissions
- An access entry for the Node IAM role to allow nodes to join the cluster
- SQS queue and EventBridge event rules for Karpenter to utilize for spot termination handling, capacity re-balancing, etc.

```hcl
module "eks" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks?depth=1&ref=master"

  ...
}

module "karpenter" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/karpenter?depth=1&ref=master"

  cluster_name = module.eks.cluster_name

  # Attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
```

### Re-Use Existing Node IAM Role

In the following example, the Karpenter module will create:
- An IAM role for use with Pod Identity and a scoped IAM policy for the Karpenter controller
- SQS queue and EventBridge event rules for Karpenter to utilize for spot termination handling, capacity re-balancing, etc.

In this scenario, Karpenter will re-use an existing Node IAM role from the EKS managed node group which already has the necessary access entry permissions:

```hcl
module "eks" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks?depth=1&ref=master"

  # Shown just for connection between cluster and Karpenter sub-module below
  eks_managed_node_groups = {
    initial = {
      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 1
    }
  }
  ...
}

module "karpenter" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/karpenter?depth=1&ref=master"

  cluster_name = module.eks.cluster_name

  create_node_iam_role = false
  node_iam_role_arn    = module.eks.eks_managed_node_groups["initial"].iam_role_arn

  # Since the node group role will already have an access entry
  create_access_entry = false

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
```


## Examples

## Basic Usage

Create Karpenter IAM role and SQS queue for spot termination handling using Pod Identity.

```hcl
module "karpenter" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/karpenter?depth=1&ref=master"

  create       = true
  cluster_name = "my-cluster"

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## With Pod Identity Association

Karpenter with Pod Identity association and Karpenter v1 permissions enabled.

```hcl
module "karpenter" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/karpenter?depth=1&ref=master"

  create       = true
  cluster_name = "app-cluster"

  enable_pod_identity           = true
  create_pod_identity_association = true
  enable_v1_permissions         = true

  namespace       = "kube-system"
  service_account = "karpenter"

  enable_spot_termination = true

  node_iam_role_name            = "KarpenterNodeRole-app-cluster"
  node_iam_role_use_name_prefix = false
  create_instance_profile       = true

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## With IRSA (Legacy / Non-Pod-Identity Clusters)

Karpenter using IRSA instead of Pod Identity for older EKS clusters.

```hcl
module "karpenter" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/karpenter?depth=1&ref=master"

  create       = true
  cluster_name = "legacy-cluster"

  enable_pod_identity = false
  enable_irsa         = true

  irsa_oidc_provider_arn          = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.ap-southeast-1.amazonaws.com/id/ABCD1234"
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  node_iam_role_name      = "KarpenterNodeRole-legacy-cluster"
  create_instance_profile = true

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Advanced - Cross-Account with Custom SQS and Event Bridge

Karpenter with a custom SQS queue name, KMS encryption, and cross-account role chaining.

```hcl
module "karpenter" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/karpenter?depth=1&ref=master"

  create       = true
  cluster_name = "prod-cluster"

  enable_pod_identity             = true
  create_pod_identity_association = true
  enable_v1_permissions           = true

  iam_role_name            = "KarpenterController-prod"
  iam_role_use_name_prefix = false
  iam_role_description     = "Karpenter controller role for prod-cluster"

  iam_role_permissions_boundary_arn = "arn:aws:iam::123456789012:policy/BoundaryPolicy"

  pod_identity_target_role_arn = "arn:aws:iam::987654321098:role/KarpenterCrossAccountRole"

  enable_spot_termination                    = true
  queue_name                                 = "KarpenterInterruptionQueue-prod"
  queue_managed_sse_enabled                  = false
  queue_kms_master_key_id                    = "arn:aws:kms:ap-southeast-1:123456789012:key/mrk-abc123"
  queue_kms_data_key_reuse_period_seconds    = 300
  queue_visibility_timeout_seconds           = 60

  node_iam_role_name                 = "KarpenterNodeRole-prod"
  node_iam_role_use_name_prefix      = false
  node_iam_role_permissions_boundary = "arn:aws:iam::123456789012:policy/BoundaryPolicy"
  create_instance_profile            = true
  node_iam_role_additional_policies = {
    ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  ami_id_ssm_parameter_arns = [
    "arn:aws:ssm:ap-southeast-1::parameter/aws/service/eks/optimized-ami/*"
  ]

  event_rule_state    = "ENABLED"
  rule_name_prefix    = "Karpenter-prod"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    CostCenter  = "platform"
  }
}
```
