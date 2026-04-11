# EKS Pod Identity

OpenTofu module for managing EKS Pod Identity associations with dedicated IAM roles using the `pods.eks.amazonaws.com` trust policy.

## Features

- **IAM Role with Pod Identity Trust Policy** - Creates an IAM role pre-configured with the EKS Pod Identity service principal (`pods.eks.amazonaws.com`)
- **Managed Policy Attachments** - Attach any number of AWS managed or customer-managed IAM policies to the role
- **Inline Policies** - Define inline IAM policies directly on the role for fine-grained access control
- **Multiple Associations** - Map multiple Kubernetes service accounts to the same IAM role across namespaces
- **Existing Role Support** - Optionally use an existing IAM role ARN instead of creating a new one
- **Additional Trust Statements** - Extend the trust policy with custom statements for cross-account or conditional access
- **Permissions Boundary** - Support for IAM permissions boundary policies

## Usage

```hcl
module "eks_pod_identity" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks-pod-identity?depth=1&ref=master"

  name         = "my-app"
  cluster_name = "my-cluster"

  associations = {
    default = {
      namespace       = "default"
      service_account = "my-app-sa"
    }
  }

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]

  tags = {
    Environment = "production"
  }
}
```

## Examples

## Basic Pod Identity for S3 Access

A single pod identity association granting read-only S3 access to a service account.

```hcl
module "pod_identity_s3" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks-pod-identity?depth=1&ref=master"

  name         = "s3-reader"
  cluster_name = "production-cluster"

  associations = {
    app = {
      namespace       = "application"
      service_account = "s3-reader-sa"
    }
  }

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Pod Identity with Multiple Policies

An association with both managed and inline policies for granular access to DynamoDB and SQS.

```hcl
module "pod_identity_multi_policy" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks-pod-identity?depth=1&ref=master"

  name         = "order-processor"
  cluster_name = "production-cluster"

  associations = {
    processor = {
      namespace       = "orders"
      service_account = "order-processor-sa"
    }
  }

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
  ]

  inline_policies = {
    sqs-access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage",
            "sqs:GetQueueAttributes"
          ]
          Resource = "arn:aws:sqs:ap-southeast-1:123456789012:orders-queue"
        }
      ]
    })
  }

  tags = {
    Environment = "production"
    Team        = "orders"
  }
}
```

## Pod Identity for Cross-Account Access

A pod identity with an additional trust statement enabling a role in another account to assume the pod identity role.

```hcl
module "pod_identity_cross_account" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks-pod-identity?depth=1&ref=master"

  name         = "cross-account-reader"
  cluster_name = "production-cluster"

  associations = {
    reader = {
      namespace       = "data-pipeline"
      service_account = "cross-account-reader-sa"
    }
  }

  additional_trust_policy_statements = [
    {
      sid     = "CrossAccountAccess"
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::987654321098:root"]
        }
      ]
    }
  ]

  inline_policies = {
    s3-cross-account = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["s3:GetObject", "s3:ListBucket"]
          Resource = [
            "arn:aws:s3:::shared-data-bucket-987654321098",
            "arn:aws:s3:::shared-data-bucket-987654321098/*"
          ]
        }
      ]
    })
  }

  tags = {
    Environment = "production"
    Team        = "data"
  }
}
```

## Multiple Service Accounts in Same Namespace

Multiple service accounts in the same namespace sharing a single IAM role for microservices that need identical permissions.

```hcl
module "pod_identity_multi_sa" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks-pod-identity?depth=1&ref=master"

  name         = "backend-services"
  cluster_name = "production-cluster"

  associations = {
    api = {
      namespace       = "backend"
      service_account = "api-sa"
    }
    worker = {
      namespace       = "backend"
      service_account = "worker-sa"
    }
    scheduler = {
      namespace       = "backend"
      service_account = "scheduler-sa"
    }
  }

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  ]

  inline_policies = {
    secrets-access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["secretsmanager:GetSecretValue"]
          Resource = "arn:aws:secretsmanager:ap-southeast-1:123456789012:secret:backend/*"
        }
      ]
    })
  }

  role_permissions_boundary_arn = "arn:aws:iam::123456789012:policy/ServiceBoundary"

  tags = {
    Environment = "production"
    Team        = "backend"
  }
}
```
