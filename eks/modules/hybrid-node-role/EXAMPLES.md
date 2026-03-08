# EKS Hybrid Node Role Module - Examples

## Basic Usage

Create the IAM role for EKS Hybrid Nodes connecting on-premises servers to an EKS cluster.

```hcl
module "hybrid_node_role" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/hybrid-node-role?depth=1&ref=v2.0.0"

  enabled = true
  name    = "EKSHybridNodeRole"

  cluster_arns = ["arn:aws:eks:ap-southeast-1:123456789012:cluster/prod-cluster"]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## With IAM Roles Anywhere for On-Premises Auth

Hybrid node role using IAM Roles Anywhere with an ACM Private CA trust anchor.

```hcl
module "hybrid_node_role" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/hybrid-node-role?depth=1&ref=v2.0.0"

  enabled     = true
  name        = "EKSHybridNodeRole-prod"
  description = "EKS Hybrid Node IAM role for on-premises datacenter"

  cluster_arns        = ["arn:aws:eks:ap-southeast-1:123456789012:cluster/prod-cluster"]
  enable_pod_identity = true

  enable_ira = true

  ira_trust_anchor_name        = "on-prem-ca-trust-anchor"
  ira_trust_anchor_enabled     = true
  ira_trust_anchor_source_type = "AWS_ACM_PCA"
  ira_trust_anchor_acm_pca_arn = "arn:aws:acm-pca:ap-southeast-1:123456789012:certificate-authority/abc12345-1234-1234-1234-abc123456789"

  ira_profile_name    = "EKSHybridNodeProfile"
  ira_profile_enabled = true

  tags = {
    Environment = "production"
    UseCase     = "hybrid-nodes"
  }
}
```

## With IAM Roles Anywhere and X.509 Certificate

Hybrid node role using a self-signed or external X.509 trust anchor certificate.

```hcl
module "hybrid_node_role" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/hybrid-node-role?depth=1&ref=v2.0.0"

  enabled     = true
  name        = "EKSHybridNodeRole-dc1"
  description = "EKS Hybrid Node IAM role for dc1 datacenter"

  cluster_arns = ["arn:aws:eks:ap-southeast-1:123456789012:cluster/prod-cluster"]

  enable_ira = true

  ira_trust_anchor_name             = "dc1-ca-trust-anchor"
  ira_trust_anchor_enabled          = true
  ira_trust_anchor_source_type      = "CERTIFICATE_BUNDLE"
  ira_trust_anchor_x509_certificate_data = <<-EOT
    -----BEGIN CERTIFICATE-----
    MIIDXTCCAkWgAwIBAgIJAMNKnzQPT6NEMA0GCSqGSIb3DQEBBQUAMF0xCzAJBgNV
    ...
    -----END CERTIFICATE-----
  EOT

  ira_profile_name                  = "dc1-hybrid-profile"
  ira_profile_enabled               = true
  ira_profile_duration_seconds      = 3600
  ira_profile_managed_policy_arns   = []

  intermediate_role_name        = "EKSHybridIntermediateRole-dc1"
  intermediate_role_description = "Intermediate role for dc1 Hybrid Node IAM Roles Anywhere"

  tags = {
    Environment = "production"
    Datacenter  = "dc1"
  }
}
```
