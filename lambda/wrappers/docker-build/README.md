# Lambda Docker Build Wrapper

Wrapper module that allows building and pushing multiple Docker images to ECR using a single module block with a `for_each`-driven interface. Each item in the `items` map creates a separate docker-build instance via the `lambda/modules/docker-build` submodule, while shared settings can be defined once in `defaults`.

## Features

- **Bulk image builds** - Build and push multiple Docker images from a single module block using a map of items
- **Shared defaults** - Define common configuration once in the `defaults` variable, with per-item overrides
- **Full feature parity** - Passes through all parameters supported by the docker-build submodule, including ECR repo creation, lifecycle policies, build args, platform targeting, and image tagging

## Usage

```hcl
module "docker_build" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/wrappers/docker-build?depth=1&ref=master"

  defaults = {
    create_ecr_repo = true
    platform        = "linux/amd64"
  }

  items = {
    service_a = {
      ecr_repo    = "service-a"
      source_path = "${path.module}/services/a"
      image_tag   = "v1.0.0"
    }
    service_b = {
      ecr_repo    = "service-b"
      source_path = "${path.module}/services/b"
      image_tag   = "v2.1.0"
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| defaults | Map of default values which will be used for each item | `any` | `{}` | no |
| items | Maps of items to create a wrapper from. Values are passed through to the module | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| wrapper | Map of outputs of the wrapper, keyed by each item's key |


## Examples

The `lambda/wrappers/docker-build` module builds and pushes multiple Lambda container
images in a single call using `items` (per-image configuration) and `defaults` (shared baseline settings).

## Basic Usage

Build two Lambda images from local Dockerfiles and push them to existing ECR repositories.

```hcl
module "lambda_docker_builds" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/wrappers/docker-build?depth=1&ref=master"

  defaults = {
    docker_file_path = "Dockerfile"
    use_image_tag    = true
  }

  items = {
    api_handler = {
      ecr_repo    = "api-handler"
      image_tag   = "1.2.0"
      source_path = "${path.module}/src/api_handler"
    }
    worker = {
      ecr_repo    = "background-worker"
      image_tag   = "1.0.3"
      source_path = "${path.module}/src/worker"
    }
  }
}
```

## Create ECR Repositories and Build Images

Create the ECR repositories automatically and push images with immutable tags.

```hcl
module "lambda_docker_with_repos" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/wrappers/docker-build?depth=1&ref=master"

  defaults = {
    create_ecr_repo      = true
    image_tag_mutability = "IMMUTABLE"
    scan_on_push         = true
    platform             = "linux/arm64"
    ecr_repo_tags = {
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }

  items = {
    inference_api = {
      ecr_repo    = "ml-inference-api"
      image_tag   = "v2.1.0"
      source_path = "${path.module}/src/inference_api"
    }
    feature_store = {
      ecr_repo         = "feature-store-service"
      image_tag        = "v1.0.0"
      source_path      = "${path.module}/src/feature_store"
      docker_file_path = "docker/Dockerfile.prod"
    }
  }
}
```

## Cross-Account ECR with Build Arguments

Push images to a shared ECR registry in a central tooling account, passing build-time arguments.

```hcl
module "lambda_docker_cross_account" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/wrappers/docker-build?depth=1&ref=master"

  defaults = {
    ecr_address      = "987654321098.dkr.ecr.us-east-1.amazonaws.com"
    use_image_tag    = true
    docker_file_path = "Dockerfile"
    build_args = {
      APP_ENV    = "production"
      BUILD_DATE = "2026-03-05"
    }
  }

  items = {
    orders_fn = {
      ecr_repo    = "platform/orders-fn"
      image_tag   = "prod-20260305-001"
      source_path = "${path.module}/src/orders"
    }
    payments_fn = {
      ecr_repo    = "platform/payments-fn"
      image_tag   = "prod-20260305-001"
      source_path = "${path.module}/src/payments"
      build_args = {
        APP_ENV    = "production"
        BUILD_DATE = "2026-03-05"
        PCI_MODE   = "true"
      }
    }
  }
}
```
