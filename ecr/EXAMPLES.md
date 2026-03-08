# ECR Module - Examples

## Basic Private Repository

A private ECR repository with immutable image tags, scan on push, and a lifecycle policy to retain only the last 30 images.

```hcl
module "ecr_api" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecr?depth=1&ref=v2.0.0"

  enabled         = true
  repository_name = "myapp/api"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecr?depth=1&ref=v2.0.0"

  enabled         = true
  repository_name = "myapp/backend"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecr?depth=1&ref=v2.0.0"

  enabled         = true
  repository_name = "myapp/frontend"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecr?depth=1&ref=v2.0.0"

  enabled          = true
  repository_type  = "public"
  repository_name  = "myorg/tools"

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
