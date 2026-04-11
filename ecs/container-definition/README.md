# ECS Container Definition

OpenTofu module to create an ECS container definition with an optional CloudWatch log group. Generates the container definition JSON object used by ECS task definitions, with sensible defaults for common settings.

## Features

- **Full Container Definition** - Supports all ECS container definition parameters including image, CPU, memory, port mappings, environment variables, secrets, health checks, and more
- **CloudWatch Logging** - Automatically configures the `awslogs` log driver with a managed CloudWatch log group
- **ECS Exec Support** - When `enable_execute_command` is enabled, automatically sets `initProcessEnabled` in Linux parameters
- **Environment Variables and Secrets** - Pass plaintext environment variables and reference SSM Parameter Store or Secrets Manager values
- **Health Check Defaults** - Provides sensible defaults for container health checks (30s interval, 3 retries, 5s timeout)
- **Read-Only Root Filesystem** - Enabled by default for improved security on Linux containers
- **Windows Support** - Automatically excludes Linux-only parameters when `operating_system_family` is not LINUX
- **Log Group Security** - Optional KMS encryption for CloudWatch log groups via `cloudwatch_log_group_kms_key_id` and deletion protection via `cloudwatch_log_group_deletion_protection_enabled`

## Usage

```hcl
module "container_definition" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/container-definition?depth=1&ref=master"

  name    = "my-app"
  image   = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:latest"
  service = "my-service"

  cpu    = 512
  memory = 1024

  port_mappings = [
    {
      name          = "http"
      containerPort = 8080
      protocol      = "tcp"
    }
  ]

  environment = [
    {
      name  = "APP_ENV"
      value = "production"
    }
  ]

  secrets = [
    {
      name      = "DB_PASSWORD"
      valueFrom = "arn:aws:secretsmanager:us-east-1:123456789012:secret:db-password"
    }
  ]

  health_check = {
    command = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
  }

  enable_execute_command = true

  tags = {
    Environment = "production"
  }
}
```

### Sidecar Container

```hcl
module "sidecar" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/container-definition?depth=1&ref=master"

  name      = "datadog-agent"
  image     = "public.ecr.aws/datadog/agent:latest"
  service   = "my-service"
  essential = false

  port_mappings = [
    {
      containerPort = 8126
      protocol      = "tcp"
    }
  ]

  environment = [
    {
      name  = "DD_APM_ENABLED"
      value = "true"
    }
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | The name of the container | `string` | `null` | no |
| `image` | The Docker image to use | `string` | `null` | no |
| `service` | The name of the service associated with this container definition | `string` | `null` | no |
| `cpu` | The number of CPU units to reserve | `number` | `null` | no |
| `memory` | The hard limit (in MiB) of memory for the container | `number` | `null` | no |
| `memory_reservation` | The soft limit (in MiB) of memory to reserve | `number` | `null` | no |
| `essential` | Whether this container is essential to the task | `bool` | `null` | no |
| `port_mappings` | List of port mappings for the container | `list(any)` | `[]` | no |
| `environment` | Environment variables to pass to the container | `list(object)` | `[]` | no |
| `secrets` | Secrets to pass to the container from SSM or Secrets Manager | `list(object)` | `[]` | no |
| `health_check` | Container health check configuration | `any` | `{}` | no |
| `command` | The command passed to the container | `list(string)` | `[]` | no |
| `entrypoint` | The entry point passed to the container | `list(string)` | `[]` | no |
| `working_directory` | The working directory to run commands inside the container | `string` | `null` | no |
| `readonly_root_filesystem` | Whether the root filesystem is read-only | `bool` | `true` | no |
| `enable_execute_command` | Whether to enable ECS Exec | `bool` | `false` | no |
| `enable_cloudwatch_logging` | Whether to configure CloudWatch logging | `bool` | `true` | no |
| `create_cloudwatch_log_group` | Whether to create a CloudWatch log group | `bool` | `true` | no |
| `cloudwatch_log_group_retention_in_days` | Number of days to retain log events | `number` | `30` | no |
| `operating_system_family` | The OS family for the task (LINUX by default) | `string` | `"LINUX"` | no |
| `tags` | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `container_definition` | The container definition object |
| `cloudwatch_log_group_name` | Name of CloudWatch log group created |
| `cloudwatch_log_group_arn` | ARN of CloudWatch log group created |


## Examples

The container-definition module produces a JSON-encoded container definition map (via its `container_definition` output) for use as input to the `ecs/service` module's `container_definitions` variable. It does not create any AWS resources except for an optional CloudWatch log group.

## Basic Web Container

A simple application container sending logs to CloudWatch.

```hcl
module "container_api" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/container-definition?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/container-definition?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/container-definition?depth=1&ref=master"

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
