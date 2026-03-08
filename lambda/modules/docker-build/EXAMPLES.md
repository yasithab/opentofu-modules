# Lambda Docker Build Module - Examples

## Basic Usage

Build a Docker image from a local Dockerfile and push it to an existing ECR repository.

```hcl
module "lambda_docker_build" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/docker-build?depth=1&ref=v2.0.0"

  source_path     = "${path.module}/src"
  docker_file_path = "Dockerfile"
  ecr_repo        = "my-lambda-image"
  image_tag       = "1.0.0"
}
```

## Create ECR Repository and Build Image

Provision the ECR repository and build the image in a single module call.

```hcl
module "lambda_docker_build_with_repo" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/docker-build?depth=1&ref=v2.0.0"

  create_ecr_repo      = true
  ecr_repo             = "ml-inference-fn"
  image_tag            = "2.1.0"
  image_tag_mutability = "IMMUTABLE"
  scan_on_push         = true

  source_path      = "${path.module}/src/ml_inference"
  docker_file_path = "Dockerfile"
  platform         = "linux/arm64"

  ecr_repo_tags = {
    Environment = "production"
    Team        = "ml-platform"
  }

  tags = {
    ManagedBy = "terraform"
  }
}
```

## Cross-Account ECR Push

Build and push an image to an ECR registry in a different AWS account.

```hcl
module "lambda_docker_cross_account" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/docker-build?depth=1&ref=v2.0.0"

  ecr_address      = "987654321098.dkr.ecr.us-east-1.amazonaws.com"
  ecr_repo         = "shared-lambda-images/api-handler"
  image_tag        = "prod-20260301"
  use_image_tag    = true

  source_path      = "${path.module}/src"
  docker_file_path = "docker/Dockerfile.prod"

  build_args = {
    APP_ENV     = "production"
    BUILD_DATE  = "2026-03-01"
  }
}
```

## With Rebuild Triggers and Lifecycle Policy

Force image rebuild when source files change and apply an ECR lifecycle policy to prune old images.

```hcl
module "lambda_docker_with_triggers" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/docker-build?depth=1&ref=v2.0.0"

  create_ecr_repo = true
  ecr_repo        = "event-processor"
  image_tag       = "latest"
  keep_remotely   = false

  source_path      = "${path.module}/src/event_processor"
  docker_file_path = "Dockerfile"

  triggers = {
    src_hash = sha256(join("", [for f in fileset("${path.module}/src/event_processor", "**") : filesha256("${path.module}/src/event_processor/${f}")]))
  }

  ecr_repo_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only 10 tagged images"
        selection = {
          tagStatus   = "tagged"
          tagPrefixList = ["v"]
          countType   = "imageCountMoreThan"
          countNumber = 10
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
