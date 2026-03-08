# ECS Container Definition Module - Examples

The container-definition module produces a JSON-encoded container definition map (via its `container_definition` output) for use as input to the `ecs/service` module's `container_definitions` variable. It does not create any AWS resources except for an optional CloudWatch log group.

## Basic Web Container

A simple application container sending logs to CloudWatch.

```hcl
module "container_api" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/container-definition?depth=1&ref=v2.0.0"

  name    = "api"
  service = "myapp"
  image   = "123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/myapp/api:v1.2.3"

  cpu    = 512
  memory = 1024

  port_mappings = [
    {
      containerPort = 8080
      protocol      = "tcp"
    }
  ]

  environment = [
    { name = "APP_ENV",  value = "production" },
    { name = "LOG_LEVEL", value = "info" }
  ]

  cloudwatch_log_group_retention_in_days = 30

  tags = {
    Environment = "production"
    Team        = "backend"
  }
}
```

## With Secrets and Health Check

A container that pulls credentials from Secrets Manager and has a health check configured.

```hcl
module "container_worker" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/container-definition?depth=1&ref=v2.0.0"

  name    = "worker"
  service = "myapp"
  image   = "123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/myapp/worker:v2.0.0"

  cpu    = 1024
  memory = 2048

  environment = [
    { name = "APP_ENV", value = "production" }
  ]

  secrets = [
    {
      name      = "DB_PASSWORD"
      valueFrom = "arn:aws:secretsmanager:ap-southeast-1:123456789012:secret:myapp/production/db-password-abc123"
    },
    {
      name      = "API_KEY"
      valueFrom = "arn:aws:ssm:ap-southeast-1:123456789012:parameter/myapp/production/api-key"
    }
  ]

  health_check = {
    command     = ["CMD-SHELL", "curl -f http://localhost:8080/healthz || exit 1"]
    interval    = 30
    timeout     = 5
    retries     = 3
    startPeriod = 60
  }

  readonly_root_filesystem = true

  cloudwatch_log_group_retention_in_days = 14

  tags = {
    Environment = "production"
    Team        = "backend"
  }
}
```

## Sidecar with FireLens Log Routing

A FluentBit sidecar container using FireLens configuration to route logs to an external destination.

```hcl
module "container_fluentbit" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/container-definition?depth=1&ref=v2.0.0"

  name    = "log-router"
  service = "myapp"
  image   = "public.ecr.aws/aws-observability/aws-for-fluent-bit:stable"

  cpu              = 64
  memory_reservation = 128

  essential = true

  firelens_configuration = {
    type = "fluentbit"
    options = {
      enable-ecs-log-metadata = "true"
    }
  }

  enable_cloudwatch_logging = false

  readonly_root_filesystem = false

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```
