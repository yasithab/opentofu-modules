# ECS Service

OpenTofu module to create an Amazon ECS service with an integrated task definition, container definitions, IAM roles, autoscaling, and security group. Supports both Fargate and EC2 launch types with advanced deployment strategies.

## Features

- **Integrated Task Definition** - Automatically creates a task definition with container definitions, or use an existing one
- **Multiple Launch Types** - Supports FARGATE, EC2, and EXTERNAL launch types with capacity provider strategies
- **IAM Roles** - Creates task execution, task, service, and infrastructure IAM roles with configurable policies
- **Application Autoscaling** - Built-in target tracking scaling policies for CPU and memory utilization with support for scheduled actions
- **Security Group** - Optionally creates a dedicated security group with configurable rules
- **Load Balancer Integration** - Attach to ALB/NLB target groups with health check grace periods
- **Service Connect** - Full ECS Service Connect support with TLS and access logging
- **Deployment Configuration** - Circuit breaker, blue/green, canary, and linear deployment strategies
- **VPC Lattice** - Support for VPC Lattice target group configurations via `vpc_lattice_configurations`
- **EBS Volume Support** - Managed EBS volume configuration for task storage
- **Fault Injection** - Optional fault injection support for chaos engineering

## Usage

### Fargate Service

```hcl
module "ecs_service" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/service?depth=1&ref=master"

  name        = "my-service"
  cluster_arn = "arn:aws:ecs:us-east-1:123456789012:cluster/my-cluster"

  cpu    = 512
  memory = 1024

  container_definitions = {
    my-app = {
      cpu       = 512
      memory    = 1024
      essential = true
      image     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:latest"

      port_mappings = [
        {
          name          = "http"
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
    }
  }

  subnet_ids = ["subnet-abc123", "subnet-def456"]

  load_balancer = {
    service = {
      target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/my-tg/abc123"
      container_name   = "my-app"
      container_port   = 8080
    }
  }

  tags = {
    Environment = "production"
  }
}
```

### With Autoscaling

```hcl
module "ecs_service" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/service?depth=1&ref=master"

  name        = "my-service"
  cluster_arn = "arn:aws:ecs:us-east-1:123456789012:cluster/my-cluster"

  cpu    = 256
  memory = 512

  container_definitions = {
    my-app = {
      essential = true
      image     = "my-app:latest"
    }
  }

  subnet_ids = ["subnet-abc123"]

  enable_autoscaling       = true
  autoscaling_min_capacity = 2
  autoscaling_max_capacity = 20
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Name of the service | `string` | `null` | no |
| `cluster_arn` | ARN of the ECS cluster | `string` | `null` | no |
| `cpu` | Number of cpu units used by the task | `number` | `1024` | no |
| `memory` | Amount (in MiB) of memory used by the task | `number` | `2048` | no |
| `desired_count` | Number of instances of the task definition to run | `number` | `1` | no |
| `launch_type` | Launch type (EC2, FARGATE, EXTERNAL) | `string` | `"FARGATE"` | no |
| `container_definitions` | Map of container definitions | `any` | `{}` | no |
| `subnet_ids` | List of subnets to associate with the task or service | `list(string)` | `[]` | no |
| `security_group_ids` | List of security groups to associate with the task or service | `list(string)` | `[]` | no |
| `load_balancer` | Configuration block for load balancers | `any` | `{}` | no |
| `enable_autoscaling` | Whether to enable autoscaling for the service | `bool` | `true` | no |
| `autoscaling_min_capacity` | Minimum number of tasks | `number` | `1` | no |
| `autoscaling_max_capacity` | Maximum number of tasks | `number` | `10` | no |
| `autoscaling_policies` | Map of autoscaling policies (CPU and memory target tracking by default) | `any` | See defaults | no |
| `create_task_definition` | Whether to create a task definition or use an existing one | `bool` | `true` | no |
| `create_service` | Whether to create the service (set to false for task definition only) | `bool` | `true` | no |
| `create_iam_role` | Whether to create the ECS service IAM role | `bool` | `true` | no |
| `create_task_exec_iam_role` | Whether to create the task execution IAM role | `bool` | `true` | no |
| `create_tasks_iam_role` | Whether to create the tasks IAM role | `bool` | `true` | no |
| `create_security_group` | Whether to create a security group | `bool` | `true` | no |
| `deployment_circuit_breaker` | Configuration for deployment circuit breaker | `any` | `{}` | no |
| `service_connect_configuration` | ECS Service Connect configuration | `object` | `null` | no |
| `force_new_deployment` | Enable to force a new task deployment | `bool` | `true` | no |
| `enabled` | Determines whether resources will be created | `bool` | `true` | no |
| `tags` | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `id` | ARN that identifies the service |
| `name` | Name of the service |
| `iam_role_arn` | Service IAM role ARN |
| `task_definition_arn` | Full ARN of the Task Definition |
| `task_definition_revision` | Revision of the task in a particular family |
| `task_definition_family` | The unique name of the task definition |
| `task_exec_iam_role_arn` | Task execution IAM role ARN |
| `tasks_iam_role_arn` | Tasks IAM role ARN |
| `autoscaling_policies` | Map of autoscaling policies and their attributes |
| `security_group_arn` | ARN of the security group |
| `security_group_id` | ID of the security group |
| `infrastructure_iam_role_arn` | Infrastructure IAM role ARN |


## Examples

## Basic Fargate Service

A simple Fargate service running two tasks with a single container definition.

```hcl
module "ecs_service_api" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/service?depth=1&ref=master"

  enabled = true
  name    = "api"

  cluster_arn    = "arn:aws:ecs:ap-southeast-1:123456789012:cluster/myapp-production"
  launch_type    = "FARGATE"
  desired_count  = 2

  cpu    = 1024
  memory = 2048

  subnet_ids = ["subnet-0abc123def456789a", "subnet-0def456789abc1230b"]

  container_definitions = {
    api = {
      image = "123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/myapp/api:v1.2.3"
      port_mappings = [
        { containerPort = 8080, protocol = "tcp" }
      ]
      environment = [
        { name = "APP_ENV", value = "production" }
      ]
    }
  }

  tags = {
    Environment = "production"
    Team        = "backend"
  }
}
```

## With Application Load Balancer

A Fargate service registered with an ALB target group, with health check grace period configured.

```hcl
module "ecs_service_web" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/service?depth=1&ref=master"

  enabled = true
  name    = "web"

  cluster_arn   = "arn:aws:ecs:ap-southeast-1:123456789012:cluster/myapp-production"
  launch_type   = "FARGATE"
  desired_count = 3

  cpu    = 512
  memory = 1024

  subnet_ids = ["subnet-0abc123def456789a", "subnet-0def456789abc1230b"]

  security_group_rules = {
    ingress_alb = {
      type                         = "ingress"
      ip_protocol                  = "tcp"
      from_port                    = 8080
      to_port                      = 8080
      referenced_security_group_id = "sg-0alb123security456group"
      description                  = "Allow traffic from ALB"
    }
    egress_all = {
      type        = "egress"
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  load_balancer = {
    service = {
      target_group_arn = "arn:aws:elasticloadbalancing:ap-southeast-1:123456789012:targetgroup/myapp-web/abc123def456"
      container_name   = "web"
      container_port   = 8080
    }
  }

  health_check_grace_period_seconds = 60

  task_exec_secret_arns = [
    "arn:aws:secretsmanager:ap-southeast-1:123456789012:secret:myapp/production/db-password-abc123"
  ]

  container_definitions = {
    web = {
      image = "123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/myapp/web:v3.0.0"
      port_mappings = [
        { containerPort = 8080, protocol = "tcp" }
      ]
    }
  }

  tags = {
    Environment = "production"
    Team        = "frontend"
  }
}
```

## With Autoscaling and Capacity Provider Strategy

A service using a mix of FARGATE and FARGATE_SPOT with CPU/memory target-tracking autoscaling.

```hcl
module "ecs_service_processor" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/service?depth=1&ref=master"

  enabled = true
  name    = "processor"

  cluster_arn   = "arn:aws:ecs:ap-southeast-1:123456789012:cluster/myapp-production"
  desired_count = 2

  cpu    = 2048
  memory = 4096

  subnet_ids = ["subnet-0abc123def456789a", "subnet-0def456789abc1230b"]

  capacity_provider_strategy = {
    on_demand = {
      capacity_provider = "FARGATE"
      weight            = 20
      base              = 1
    }
    spot = {
      capacity_provider = "FARGATE_SPOT"
      weight            = 80
    }
  }

  enable_autoscaling    = true
  autoscaling_min_capacity = 2
  autoscaling_max_capacity = 20

  autoscaling_policies = {
    cpu = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
        target_value = 60
      }
    }
    memory = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageMemoryUtilization"
        }
        target_value = 70
      }
    }
  }

  container_definitions = {
    processor = {
      image = "123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/myapp/processor:v1.0.0"
      environment = [
        { name = "QUEUE_URL", value = "https://sqs.ap-southeast-1.amazonaws.com/123456789012/myapp-jobs" }
      ]
    }
  }

  tags = {
    Environment = "production"
    Team        = "data"
  }
}
```

## With EFS Volume Mount

A service that mounts an EFS file system into the container for shared persistent storage.

```hcl
module "ecs_service_cms" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/service?depth=1&ref=master"

  enabled = true
  name    = "cms"

  cluster_arn   = "arn:aws:ecs:ap-southeast-1:123456789012:cluster/myapp-production"
  launch_type   = "FARGATE"
  desired_count = 1

  cpu    = 1024
  memory = 2048

  subnet_ids = ["subnet-0abc123def456789a"]

  volume = {
    shared_uploads = {
      name = "shared-uploads"
      efs_volume_configuration = {
        file_system_id          = "fs-0abc123def456789a"
        root_directory          = "/"
        transit_encryption      = "ENABLED"
        transit_encryption_port = 2049
        authorization_config = {
          iam = "ENABLED"
        }
      }
    }
  }

  container_definitions = {
    cms = {
      image = "123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/myapp/cms:v2.1.0"
      mount_points = [
        {
          sourceVolume  = "shared-uploads"
          containerPath = "/var/www/uploads"
          readOnly      = false
        }
      ]
      port_mappings = [
        { containerPort = 80, protocol = "tcp" }
      ]
    }
  }

  tags = {
    Environment = "production"
    Team        = "content"
  }
}
```
