# AWS App Runner

Deploys an AWS App Runner service with full lifecycle management including IAM roles, VPC networking, custom domains, auto-scaling, observability, and source configuration for both image and code repositories.

## Features

- **Image and Code Sources** - Deploy from ECR images or source code repositories with auto-deployments
- **IAM Role Management** - Automatic creation of access and instance IAM roles with configurable policies and permissions boundaries
- **VPC Networking** - Built-in VPC connector and VPC ingress connection support for private workloads
- **Custom Domains** - Automatic custom domain association with Route 53 DNS validation records, keyed by DNS record name
- **Auto-Scaling** - Create and associate auto-scaling configurations with concurrency and size limits
- **Observability** - AWS X-Ray tracing integration via observability configuration
- **Private ECR Access** - Automatic IAM policy generation for pulling images from private ECR repositories
- **Encryption at Rest** - Optional KMS encryption configuration for service data via `encryption_configuration`
- **Connections** - Support for App Runner connections (e.g. GitHub) for source code-based deployments

## Usage

```hcl
module "app_runner" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//app-runner?depth=1&ref=master"

  name                   = "my-service"
  create_access_iam_role = true
  private_ecr_arn        = "arn:aws:ecr:us-east-1:123456789012:repository/my-app"

  source_configuration = {
    auto_deployments_enabled = true
    image_repository = {
      image_identifier      = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:latest"
      image_repository_type = "ECR"
      image_configuration = {
        port = "8080"
      }
    }
  }

  instance_configuration = {
    cpu    = "1024"
    memory = "2048"
  }

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
| access\_iam\_role\_description | Description of the role | `string` | `null` | no |
| access\_iam\_role\_inline\_policies | Map of inline IAM policies to attach to the access IAM role. Keys are policy names; values are JSON policy documents. | `map(string)` | `{}` | no |
| access\_iam\_role\_managed\_policy\_arns | Set of IAM managed policy ARNs to attach to the access IAM role. | `set(string)` | `null` | no |
| access\_iam\_role\_max\_session\_duration | Maximum session duration (in seconds) for the access IAM role. Valid values are between 3600 and 43200. | `number` | `null` | no |
| access\_iam\_role\_name | Name to use on IAM role created | `string` | `null` | no |
| access\_iam\_role\_path | IAM role path | `string` | `null` | no |
| access\_iam\_role\_permissions\_boundary | ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| access\_iam\_role\_policies | IAM policies to attach to the IAM role | `map(string)` | `{}` | no |
| access\_iam\_role\_use\_name\_prefix | Determines whether the IAM role name (`iam_role_name`) is used as a prefix | `bool` | `true` | no |
| auto\_scaling\_configuration\_arn | ARN of an App Runner automatic scaling configuration resource that you want to associate with your service. If not provided, App Runner associates the latest revision of a default auto scaling configuration | `string` | `null` | no |
| auto\_scaling\_configurations | Map of auto-scaling configuration definitions to create | <pre>map(object({<br/>    name            = optional(string)<br/>    max_concurrency = optional(number)<br/>    max_size        = optional(number)<br/>    min_size        = optional(number)<br/>    tags            = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| connections | Map of connection definitions to create | <pre>map(object({<br/>    name          = optional(string)<br/>    provider_type = optional(string, "GITHUB")<br/>    tags          = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| create\_access\_iam\_role | Determines whether an IAM role is created or to use an existing IAM role | `bool` | `false` | no |
| create\_custom\_domain\_association | Determines whether a Custom Domain Association will be created | `bool` | `false` | no |
| create\_ingress\_vpc\_connection | Determines whether a VPC ingress configuration will be created | `bool` | `false` | no |
| create\_instance\_iam\_role | Determines whether an IAM role is created or to use an existing IAM role | `bool` | `true` | no |
| create\_service | Determines whether the service will be created | `bool` | `true` | no |
| create\_vpc\_connector | Determines whether a VPC Connector will be created | `bool` | `false` | no |
| domain\_name | The custom domain endpoint to association. Specify a base domain e.g., `example.com` or a subdomain e.g., `subdomain.example.com` | `string` | `null` | no |
| enable\_observability\_configuration | Determines whether an X-Ray Observability Configuration will be created and assigned to the service | `bool` | `true` | no |
| enable\_www\_subdomain | Whether to associate the subdomain with the App Runner service in addition to the base domain. Defaults to `true` | `bool` | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| encryption\_configuration | The encryption configuration for the service | <pre>object({<br/>    kms_key = string<br/>  })</pre> | `null` | no |
| health\_check\_configuration | The health check configuration for the service | <pre>object({<br/>    healthy_threshold   = optional(number)<br/>    interval            = optional(number)<br/>    path                = optional(string)<br/>    protocol            = optional(string)<br/>    timeout             = optional(number)<br/>    unhealthy_threshold = optional(number)<br/>  })</pre> | `null` | no |
| hosted\_zone\_id | The ID of the Route53 hosted zone that contains the domain for the `domain_name` | `string` | `null` | no |
| iam\_policy\_delay\_after\_creation\_ms | Milliseconds to wait after IAM policy creation before use. Helps avoid eventual-consistency race conditions. Applies to both access and instance IAM policies. | `number` | `null` | no |
| ingress\_vpc\_endpoint\_id | The ID of the VPC endpoint that is used for the VPC ingress configuration | `string` | `null` | no |
| ingress\_vpc\_id | The ID of the VPC that is used for the VPC ingress configuration | `string` | `null` | no |
| instance\_configuration | The instance configuration for the service | <pre>object({<br/>    cpu               = optional(string)<br/>    memory            = optional(string)<br/>    instance_role_arn = optional(string)<br/>  })</pre> | `null` | no |
| instance\_iam\_role\_description | Description of the role | `string` | `null` | no |
| instance\_iam\_role\_inline\_policies | Map of inline IAM policies to attach to the instance IAM role. Keys are policy names; values are JSON policy documents. | `map(string)` | `{}` | no |
| instance\_iam\_role\_managed\_policy\_arns | Set of IAM managed policy ARNs to attach to the instance IAM role. | `set(string)` | `null` | no |
| instance\_iam\_role\_max\_session\_duration | Maximum session duration (in seconds) for the instance IAM role. Valid values are between 3600 and 43200. | `number` | `null` | no |
| instance\_iam\_role\_name | Name to use on IAM role created | `string` | `null` | no |
| instance\_iam\_role\_path | IAM role path | `string` | `null` | no |
| instance\_iam\_role\_permissions\_boundary | ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| instance\_iam\_role\_policies | IAM policies to attach to the IAM role | `map(string)` | `{}` | no |
| instance\_iam\_role\_use\_name\_prefix | Determines whether the IAM role name (`iam_role_name`) is used as a prefix | `bool` | `true` | no |
| instance\_policy\_statements | A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage | <pre>map(object({<br/>    sid           = optional(string)<br/>    actions       = optional(list(string))<br/>    not_actions   = optional(list(string))<br/>    effect        = optional(string)<br/>    resources     = optional(list(string))<br/>    not_resources = optional(list(string))<br/>    principals = optional(list(object({<br/>      type        = string<br/>      identifiers = list(string)<br/>    })), [])<br/>    not_principals = optional(list(object({<br/>      type        = string<br/>      identifiers = list(string)<br/>    })), [])<br/>    conditions = optional(list(object({<br/>      test     = string<br/>      values   = list(string)<br/>      variable = string<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| name | The name of the service | `string` | `null` | no |
| network\_configuration | The network configuration for the service | <pre>object({<br/>    ip_address_type = optional(string)<br/>    ingress_configuration = optional(object({<br/>      is_publicly_accessible = optional(bool)<br/>    }))<br/>    egress_configuration = optional(object({<br/>      egress_type       = optional(string, "VPC")<br/>      vpc_connector_arn = optional(string)<br/>    }))<br/>  })</pre> | `null` | no |
| observability\_trace\_vendor | The implementation provider chosen for tracing App Runner services. Valid values: AWSXRAY. Defaults to AWSXRAY when enable\_observability\_configuration is true. | `string` | `"AWSXRAY"` | no |
| private\_ecr\_arn | The ARN of the private ECR repository that contains the service image to launch | `string` | `null` | no |
| source\_configuration | The source configuration for the service | <pre>object({<br/>    auto_deployments_enabled = optional(bool, false)<br/>    authentication_configuration = optional(object({<br/>      access_role_arn = optional(string)<br/>      connection_arn  = optional(string)<br/>    }))<br/>    code_repository = optional(object({<br/>      repository_url   = string<br/>      source_directory = optional(string)<br/>      source_code_version = object({<br/>        type  = optional(string, "BRANCH")<br/>        value = string<br/>      })<br/>      code_configuration = optional(object({<br/>        configuration_source = string<br/>        code_configuration_values = optional(object({<br/>          build_command                 = optional(string)<br/>          port                          = optional(string)<br/>          runtime                       = string<br/>          runtime_environment_variables = optional(map(string), {})<br/>          runtime_environment_secrets   = optional(map(string), {})<br/>          start_command                 = optional(string)<br/>        }))<br/>      }))<br/>    }))<br/>    image_repository = optional(object({<br/>      image_identifier      = string<br/>      image_repository_type = string<br/>      image_configuration = optional(object({<br/>        port                          = optional(string)<br/>        runtime_environment_variables = optional(map(string), {})<br/>        runtime_environment_secrets   = optional(map(string), {})<br/>        start_command                 = optional(string)<br/>      }))<br/>    }))<br/>  })</pre> | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| vpc\_connector\_name | The name of the VPC Connector | `string` | `null` | no |
| vpc\_connector\_security\_groups | The security groups to use for the VPC Connector | `list(string)` | `[]` | no |
| vpc\_connector\_subnets | The subnets to use for the VPC Connector | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| access\_iam\_role\_arn | The Amazon Resource Name (ARN) specifying the IAM role |
| access\_iam\_role\_name | The name of the IAM role |
| access\_iam\_role\_unique\_id | Stable and unique string identifying the IAM role |
| auto\_scaling\_configurations | Map of attribute maps for all autoscaling configurations created |
| connections | Map of attribute maps for all connections created |
| custom\_domain\_association\_certificate\_validation\_records | A set of certificate CNAME records used for this domain name |
| custom\_domain\_association\_dns\_target | The App Runner subdomain of the App Runner service. The custom domain name is mapped to this target name. Attribute only available if resource created (not imported) with Terraform |
| custom\_domain\_association\_id | The `domain_name` and `service_arn` separated by a comma (`,`) |
| instance\_iam\_role\_arn | The Amazon Resource Name (ARN) specifying the IAM role |
| instance\_iam\_role\_name | The name of the IAM role |
| instance\_iam\_role\_unique\_id | Stable and unique string identifying the IAM role |
| observability\_configuration\_arn | ARN of this observability configuration |
| observability\_configuration\_latest | Whether the observability configuration has the highest `observability_configuration_revision` among all configurations that share the same `observability_configuration_name` |
| observability\_configuration\_revision | The revision of the observability configuration |
| observability\_configuration\_status | The current state of the observability configuration. An `INACTIVE` configuration revision has been deleted and can't be used. It is permanently removed some time after deletion |
| service\_arn | The Amazon Resource Name (ARN) of the service |
| service\_id | An alphanumeric ID that App Runner generated for this service. Unique within the AWS Region |
| service\_status | The current state of the App Runner service |
| service\_url | A subdomain URL that App Runner generated for this service. You can use this URL to access your service web application |
| vpc\_connector\_arn | The Amazon Resource Name (ARN) of VPC connector |
| vpc\_connector\_revision | The revision of VPC connector. It's unique among all the active connectors ("Status": "ACTIVE") that share the same Name |
| vpc\_connector\_status | The current state of the VPC connector. If the status of a connector revision is INACTIVE, it was deleted and can't be used. Inactive connector revisions are permanently removed some time after they are deleted |
| vpc\_ingress\_connection\_arn | The Amazon Resource Name (ARN) of the VPC Ingress Connection |
| vpc\_ingress\_connection\_domain\_name | The domain name associated with the VPC Ingress Connection resource |
<!-- END_TF_DOCS -->

## Examples

## Basic Usage (Public ECR Image)

Deploys an App Runner service from a public container image. No access IAM role is needed for public images. An instance IAM role and X-Ray observability configuration are created automatically.

```hcl
module "app_runner" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//app-runner?depth=1&ref=master"

  enabled = true

  name         = "hello-world"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//app-runner?depth=1&ref=master"

  enabled = true

  name         = "api-service"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//app-runner?depth=1&ref=master"

  enabled = true

  name         = "internal-api"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//app-runner?depth=1&ref=master"

  enabled = true

  name         = "storefront"

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
