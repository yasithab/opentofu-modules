# App Runner Module - Examples

## Basic Usage (Public ECR Image)

Deploys an App Runner service from a public container image. No access IAM role is needed for public images. An instance IAM role and X-Ray observability configuration are created automatically.

```hcl
module "app_runner" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//app-runner?depth=1&ref=v2.0.0"

  enabled = true

  service_name = "hello-world"

  source_configuration = {
    auto_deployments_enabled = false
    image_repository = {
      image_identifier      = "public.ecr.aws/nginx/nginx:1.25"
      image_repository_type = "ECR_PUBLIC"
      image_configuration = {
        port = "80"
      }
    }
  }

  instance_configuration = {
    cpu    = "1024"
    memory = "2048"
  }

  tags = {
    Environment = "staging"
    Team        = "platform"
  }
}
```

## With Private ECR Image and Access IAM Role

Pulls from a private ECR repository. The module creates an access IAM role with the required ECR permissions attached automatically when `private_ecr_arn` is set.

```hcl
module "app_runner_private_ecr" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//app-runner?depth=1&ref=v2.0.0"

  enabled = true

  service_name = "api-service"

  create_access_iam_role = true
  private_ecr_arn        = "arn:aws:ecr:us-east-1:123456789012:repository/api-service"

  source_configuration = {
    auto_deployments_enabled = true
    image_repository = {
      image_identifier      = "123456789012.dkr.ecr.us-east-1.amazonaws.com/api-service:latest"
      image_repository_type = "ECR"
      image_configuration = {
        port          = "8080"
        start_command = "/app/start.sh"
        runtime_environment_variables = {
          APP_ENV = "production"
          LOG_LEVEL = "info"
        }
        runtime_environment_secrets = {
          DB_PASSWORD = "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/api/db-password-AbCdEf"
        }
      }
    }
  }

  instance_configuration = {
    cpu    = "2048"
    memory = "4096"
  }

  health_check_configuration = {
    protocol            = "HTTP"
    path                = "/healthz"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  enable_observability_configuration = true

  tags = {
    Environment = "production"
    Team        = "backend"
  }
}
```

## With VPC Connector for Private Network Access

Attaches the App Runner service to a VPC via a VPC connector, allowing it to reach private resources like RDS or ElastiCache. Ingress is limited to traffic arriving through a VPC endpoint.

```hcl
module "app_runner_vpc" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//app-runner?depth=1&ref=v2.0.0"

  enabled = true

  service_name = "internal-api"

  create_access_iam_role = true
  private_ecr_arn        = "arn:aws:ecr:us-east-1:123456789012:repository/internal-api"

  # VPC Connector - routes outbound traffic into the VPC
  create_vpc_connector          = true
  vpc_connector_subnets         = ["subnet-0abc123def456gh01", "subnet-0abc123def456gh02"]
  vpc_connector_security_groups = ["sg-0a1b2c3d4e5f67890"]

  # VPC Ingress - restricts inbound traffic to a VPC endpoint
  create_ingress_vpc_connection = true
  ingress_vpc_id                = "vpc-0abc123def456gh01"
  ingress_vpc_endpoint_id       = "vpce-0abc1234def567890"

  source_configuration = {
    auto_deployments_enabled = true
    image_repository = {
      image_identifier      = "123456789012.dkr.ecr.us-east-1.amazonaws.com/internal-api:latest"
      image_repository_type = "ECR"
      image_configuration = {
        port = "3000"
        runtime_environment_variables = {
          DB_HOST = "db.internal.example.com"
        }
      }
    }
  }

  instance_configuration = {
    cpu    = "2048"
    memory = "4096"
  }

  tags = {
    Environment = "production"
    Team        = "platform"
    Visibility  = "internal"
  }
}
```

## With Custom Domain and Auto-Scaling

Associates a custom domain and configures a dedicated auto-scaling profile with tuned concurrency and instance counts.

```hcl
module "app_runner_custom_domain" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//app-runner?depth=1&ref=v2.0.0"

  enabled = true

  service_name = "storefront"

  create_access_iam_role = true
  private_ecr_arn        = "arn:aws:ecr:us-east-1:123456789012:repository/storefront"

  source_configuration = {
    auto_deployments_enabled = true
    image_repository = {
      image_identifier      = "123456789012.dkr.ecr.us-east-1.amazonaws.com/storefront:stable"
      image_repository_type = "ECR"
      image_configuration = {
        port = "8080"
      }
    }
  }

  # Create and immediately attach a custom auto-scaling configuration
  auto_scaling_configurations = {
    production = {
      name            = "storefront-prod"
      max_concurrency = 100
      max_size        = 10
      min_size        = 2
    }
  }

  # Custom domain association with Route53 validation records
  create_custom_domain_association = true
  domain_name                      = "storefront.example.com"
  enable_www_subdomain             = false
  hosted_zone_id                   = "Z0123456789ABCDEFGHIJ"

  tags = {
    Environment = "production"
    Team        = "ecommerce"
  }
}
```
