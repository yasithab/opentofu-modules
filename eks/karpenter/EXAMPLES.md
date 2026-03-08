# EKS Karpenter Module - Examples

## Basic Usage

Create Karpenter IAM role and SQS queue for spot termination handling using Pod Identity.

```hcl
module "karpenter" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/karpenter?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/karpenter?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/karpenter?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/karpenter?depth=1&ref=v2.0.0"

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
