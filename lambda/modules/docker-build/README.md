# Lambda Docker Build

Submodule for building Docker images and pushing them to Amazon ECR for use with container image-based Lambda functions. Optionally creates the ECR repository and manages its lifecycle policies.

## Features

- **Docker image build** - Builds Docker images from a source directory with configurable Dockerfile path, build arguments, and target platform
- **ECR push** - Automatically pushes built images to an Amazon ECR repository
- **ECR repository creation** - Optionally creates an ECR repository with configurable image scanning, tag mutability, and encryption settings
- **Lifecycle policies** - Supports ECR lifecycle policies for automated cleanup of unused images
- **Image tagging** - Uses custom image tags or auto-generates timestamp-based tags; supports tag-less deployment via image digest
- **SAM CLI metadata** - Optionally creates SAM metadata for local testing and debugging of image-based Lambda functions
- **Cross-account support** - Allows specifying a custom ECR address for cross-account image pulling

## Usage

```hcl
module "docker_build" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/docker-build?depth=1&ref=master"

  create_ecr_repo = true
  ecr_repo        = "my-lambda-function"
  source_path     = "${path.module}/src"
  image_tag       = "v1.0.0"
  platform        = "linux/amd64"

  build_args = {
    ENV = "production"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_ecr_repo | Controls whether an ECR repository should be created | `bool` | `false` | no |
| ecr_repo | Name of the ECR repository to use or create | `string` | `null` | no |
| ecr_address | Address of ECR repository for cross-account pulling | `string` | `null` | no |
| source_path | Path to folder containing application code | `string` | `null` | no |
| docker_file_path | Path to Dockerfile in the source package | `string` | `"Dockerfile"` | no |
| image_tag | Image tag to use. Defaults to a timestamp if not specified | `string` | `null` | no |
| use_image_tag | Controls whether to use an image tag or deploy via digest (sha256) | `bool` | `true` | no |
| build_args | A map of Docker build arguments | `map(string)` | `{}` | no |
| platform | The target architecture platform to build the image for | `string` | `null` | no |
| image_tag_mutability | Tag mutability setting for the repository (MUTABLE or IMMUTABLE) | `string` | `"MUTABLE"` | no |
| scan_on_push | Whether images are scanned after being pushed | `bool` | `false` | no |
| ecr_force_delete | If true, deletes the repository even if it contains images | `bool` | `true` | no |
| ecr_repo_lifecycle_policy | A JSON formatted ECR lifecycle policy | `string` | `null` | no |
| keep_remotely | Whether to keep the image in the remote registry on destroy | `bool` | `false` | no |
| force_remove | Whether to remove the image forcibly on destroy | `bool` | `false` | no |
| keep_locally | Whether to keep the Docker image locally on destroy | `bool` | `false` | no |
| triggers | Map of strings that, when changed, force the image to be rebuilt | `map(string)` | `{}` | no |
| create_sam_metadata | Controls whether the SAM metadata null resource should be created | `bool` | `false` | no |
| tags | Map of tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| image_uri | The ECR image URI for deploying the Lambda function |
| image_id | The ID of the Docker image |


## Examples

## Basic Usage

Build a Docker image from a local Dockerfile and push it to an existing ECR repository.

```hcl
module "lambda_docker_build" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/docker-build?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/docker-build?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/docker-build?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/docker-build?depth=1&ref=master"

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
