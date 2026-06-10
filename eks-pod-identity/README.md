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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11.0 |
| aws | >= 6.49, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| additional\_trust\_policy\_statements | Additional IAM policy statements to add to the trust policy | `list(any)` | `[]` | no |
| associations | Map of pod identity associations to create. Each association maps a service account to the IAM role.<br/>Key is used as an identifier. Value object:<br/>  - namespace       : Kubernetes namespace<br/>  - service\_account : Kubernetes service account name | <pre>map(object({<br/>    namespace       = string<br/>    service_account = string<br/>  }))</pre> | `{}` | no |
| cluster\_name | Name of the EKS cluster | `string` | n/a | yes |
| create\_role | Whether to create the IAM role for pod identity | `bool` | `true` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| existing\_role\_arn | ARN of an existing IAM role to use instead of creating one. When set, `create_role` is ignored for the association. | `string` | `null` | no |
| inline\_policies | Map of inline policy names to policy JSON documents to attach to the role | `map(string)` | `{}` | no |
| managed\_policy\_arns | List of IAM managed policy ARNs to attach to the role | `list(string)` | `[]` | no |
| name | Name prefix used for IAM role and related resources | `string` | n/a | yes |
| role\_description | Description of the IAM role | `string` | `null` | no |
| role\_max\_session\_duration | Maximum session duration (in seconds) for the IAM role. Value can be between 3600 and 43200. | `number` | `3600` | no |
| role\_name | Name of the IAM role. If null, uses `var.name`. | `string` | `null` | no |
| role\_path | Path for the IAM role | `string` | `"/"` | no |
| role\_permissions\_boundary\_arn | ARN of the permissions boundary policy to attach to the IAM role | `string` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| associations | Map of pod identity association attributes |
| role\_arn | ARN of the IAM role |
| role\_create\_date | Creation date of the IAM role |
| role\_id | ID of the IAM role |
| role\_name | Name of the IAM role |
| role\_path | Path of the IAM role |
| role\_unique\_id | Unique ID of the IAM role |
<!-- END_TF_DOCS -->

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

## Notes

- Managed policy attachments are keyed by policy ARN, so reordering or removing entries in
  `managed_policy_arns` never churns unrelated attachments.
