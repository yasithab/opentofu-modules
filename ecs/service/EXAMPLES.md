# ECS Service Module - Examples

## Basic Fargate Service

A simple Fargate service running two tasks with a single container definition.

```hcl
module "ecs_service_api" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/service?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/service?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/service?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/service?depth=1&ref=v2.0.0"

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
