# Amazon ECR

OpenTofu module for provisioning and managing Amazon Elastic Container Registry (ECR) repositories with support for both private and public registries, lifecycle policies, and cross-region replication.

## Features

- **Private and Public Repositories** - Create and manage both private ECR repositories and public ECR Public Gallery repositories
- **Repository Policies** - Automated IAM policy generation with read-only, read-write, and Lambda access grants, or supply a custom policy
- **Image Scanning** - Scan-on-push enabled by default with optional registry-level enhanced or basic scanning configuration
- **Lifecycle Policies** - Configurable image lifecycle rules for automatic cleanup of untagged or aged images
- **Encryption** - Support for AES256 (default) and KMS encryption with custom key ARN
- **Tag Immutability** - Immutable tags by default with exclusion filter support for flexible tag policies
- **Registry Replication** - Cross-region and cross-account replication configuration with repository filters
- **Pull-Through Cache** - Registry-level pull-through cache rules for upstream registries with optional credential and custom role support
- **Registry Policy** - Attach registry-level IAM policies for cross-account access control

## Usage

```hcl
module "ecr" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecr?depth=1&ref=master"

  name            = "my-app"

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 30
        }
        action = { type = "expire" }
      }
    ]
  })

  tags = {
    Environment = "production"
  }
}
```

## Examples

## Basic Private Repository

A private ECR repository with immutable image tags, scan on push, and a lifecycle policy to retain only the last 30 images.

```hcl
module "ecr_api" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecr?depth=1&ref=master"

  enabled         = true
  name            = "myapp/api"

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Retain last 30 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 30
        }
        action = { type = "expire" }
      }
    ]
  })

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## With KMS Encryption and Cross-Account Read Access

A repository encrypted with a customer-managed KMS key, granting read access to a CI/CD role in another account.

```hcl
module "ecr_backend" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecr?depth=1&ref=master"

  enabled         = true
  name            = "myapp/backend"

  repository_encryption_type = "KMS"
  repository_kms_key         = "arn:aws:kms:ap-southeast-1:123456789012:key/mrk-abc123def456"

  repository_read_access_arns = [
    "arn:aws:iam::987654321098:role/cicd-deploy-role"
  ]

  repository_read_write_access_arns = [
    "arn:aws:iam::123456789012:role/github-actions-ecr-role"
  ]

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than 14 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = { type = "expire" }
      }
    ]
  })

  tags = {
    Environment = "production"
    Team        = "backend"
  }
}
```

## With Registry-Level Pull Through Cache

A repository alongside a pull-through cache rule to mirror public ECR images into the private registry.

```hcl
module "ecr_with_cache" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecr?depth=1&ref=master"

  enabled         = true
  name            = "myapp/frontend"

  registry_pull_through_cache_rules = {
    ecr_public = {
      ecr_repository_prefix = "ecr-public"
      upstream_registry_url = "public.ecr.aws"
    }
    dockerhub = {
      ecr_repository_prefix = "dockerhub"
      upstream_registry_url = "registry-1.docker.io"
      credential_arn        = "arn:aws:secretsmanager:ap-southeast-1:123456789012:secret/dockerhub-creds"
    }
  }

  tags = {
    Environment = "production"
    Team        = "frontend"
  }
}
```

## Public Repository

A public ECR repository for distributing open-source tooling, with catalog metadata.

```hcl
module "ecr_public_tools" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecr?depth=1&ref=master"

  enabled          = true
  repository_type  = "public"
  name             = "myorg/tools"

  public_repository_catalog_data = {
    description       = "Internal CLI tools published for public use"
    architectures     = ["x86-64", "ARM 64"]
    operating_systems = ["Linux"]
    about_text        = "A collection of utilities built by the platform team."
    usage_text        = "Pull with: docker pull public.ecr.aws/myorg/tools:latest"
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Notes

- **Default lifecycle policy**: `create_lifecycle_policy` defaults to `true`. When `repository_lifecycle_policy` is not supplied, the module applies a default policy that expires untagged images after 14 days and keeps only the last 100 tagged images. Supply your own `repository_lifecycle_policy` to override these rules, or set `create_lifecycle_policy = false` to skip lifecycle management entirely (images then accumulate indefinitely).
- **KMS encryption**: when `repository_encryption_type = "KMS"` and `repository_kms_key` is not set, ECR uses the AWS managed key (`aws/ecr`). Supply a customer-managed key ARN via `repository_kms_key` if you need cross-account image pulls, custom key policies, or control over key rotation. The key must exist before the repository is created, and changing the encryption configuration forces repository replacement.

## Reference

<details>
<summary>Requirements, providers, inputs and outputs (generated by terraform-docs)</summary>

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
| attach\_repository\_policy | Determines whether a repository policy will be attached to the repository | `bool` | `true` | no |
| create\_lifecycle\_policy | Determines whether a lifecycle policy will be created | `bool` | `true` | no |
| create\_registry\_policy | Determines whether a registry policy will be created | `bool` | `false` | no |
| create\_registry\_replication\_configuration | Determines whether a registry replication configuration will be created | `bool` | `false` | no |
| create\_repository | Determines whether a repository will be created | `bool` | `true` | no |
| create\_repository\_policy | Determines whether a repository policy will be created | `bool` | `true` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| manage\_registry\_scanning\_configuration | Determines whether the registry scanning configuration will be managed | `bool` | `false` | no |
| name | The name of the repository | `string` | `null` | no |
| public\_repository\_catalog\_data | Catalog data configuration for the repository | `any` | `{}` | no |
| registry\_policy | The policy document. This is a JSON formatted string | `string` | `null` | no |
| registry\_pull\_through\_cache\_rules | Map of pull through cache rules to create. Each key is a unique identifier. Supports: ecr\_repository\_prefix (required), upstream\_registry\_url (required), credential\_arn (optional), custom\_role\_arn (optional), upstream\_repository\_prefix (optional). | `any` | `{}` | no |
| registry\_replication\_rules | The replication rules for a replication configuration. A maximum of 10 are allowed | `any` | `[]` | no |
| registry\_scan\_rules | One or multiple blocks specifying scanning rules to determine which repository filters are used and at what frequency scanning will occur | `any` | `[]` | no |
| registry\_scan\_type | the scanning type to set for the registry. Can be either `ENHANCED` or `BASIC` | `string` | `"ENHANCED"` | no |
| repository\_encryption\_type | The encryption type for the repository. Must be one of: `KMS` or `AES256`. Defaults to `AES256` | `string` | `null` | no |
| repository\_force\_delete | If `true`, will delete the repository even if it contains images. Defaults to `false` | `bool` | `null` | no |
| repository\_image\_scan\_on\_push | Indicates whether images are scanned after being pushed to the repository (`true`) or not scanned (`false`) | `bool` | `true` | no |
| repository\_image\_tag\_mutability | The tag mutability setting for the repository. Must be one of: `MUTABLE`, `IMMUTABLE`, `IMMUTABLE_WITH_EXCLUSION`, or `MUTABLE_WITH_EXCLUSION`. Defaults to `IMMUTABLE` | `string` | `"IMMUTABLE"` | no |
| repository\_image\_tag\_mutability\_exclusion\_filters | List of image tag mutability exclusion filter blocks. Each block requires `filter` (pattern string) and optionally `filter_type` (default: WILDCARD). Only applicable when `repository_image_tag_mutability` is `IMMUTABLE_WITH_EXCLUSION` or `MUTABLE_WITH_EXCLUSION`. | `any` | `[]` | no |
| repository\_kms\_key | The ARN of the KMS key to use when encryption\_type is `KMS`. If not specified, uses the default AWS managed key for ECR | `string` | `null` | no |
| repository\_lambda\_read\_access\_arns | The ARNs of the Lambda service roles that have read access to the repository | `list(string)` | `[]` | no |
| repository\_lifecycle\_policy | The policy document. This is a JSON formatted string. See more details about [Policy Parameters](http://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html#lifecycle_policy_parameters) in the official AWS docs. When `null` (the default) and `create_lifecycle_policy = true`, a default policy is applied that expires untagged images after 14 days and keeps only the last 100 tagged images | `string` | `null` | no |
| repository\_policy | The JSON policy to apply to the repository. If not specified, uses the default policy | `string` | `null` | no |
| repository\_policy\_statements | A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage | `any` | `{}` | no |
| repository\_read\_access\_arns | The ARNs of the IAM users/roles that have read access to the repository | `list(string)` | `[]` | no |
| repository\_read\_write\_access\_arns | The ARNs of the IAM users/roles that have read/write access to the repository | `list(string)` | `[]` | no |
| repository\_type | The type of repository to create. Either `public` or `private` | `string` | `"private"` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| repository\_arn | Full ARN of the repository |
| repository\_name | Name of the repository |
| repository\_registry\_id | The registry ID where the repository was created |
| repository\_url | The URL of the repository |
<!-- END_TF_DOCS -->

</details>
