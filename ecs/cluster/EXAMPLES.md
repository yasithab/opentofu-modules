# ECS Cluster Module - Examples

## Basic Fargate Cluster

A Fargate-only ECS cluster with Container Insights enabled and a dedicated CloudWatch log group for execute-command sessions.

```hcl
module "ecs_cluster" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/cluster?depth=1&ref=v2.0.0"

  enabled      = true
  cluster_name = "myapp-production"

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 20
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## With Task Execution IAM Role

A cluster that also creates a shared task execution IAM role, granting access to specific SSM parameters and Secrets Manager secrets.

```hcl
module "ecs_cluster" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/cluster?depth=1&ref=v2.0.0"

  enabled      = true
  cluster_name = "myapp-production"

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
        base   = 1
      }
    }
  }

  create_task_exec_iam_role = true
  task_exec_ssm_param_arns = [
    "arn:aws:ssm:ap-southeast-1:123456789012:parameter/myapp/production/*"
  ]
  task_exec_secret_arns = [
    "arn:aws:secretsmanager:ap-southeast-1:123456789012:secret:myapp/production/db-password-*"
  ]

  cloudwatch_log_group_retention_in_days = 30

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## EC2 Launch Type Cluster

A cluster for EC2-backed workloads, creating the node IAM role, instance profile, and a cluster security group.

```hcl
module "ecs_ec2_cluster" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/cluster?depth=1&ref=v2.0.0"

  enabled      = true
  cluster_name = "myapp-ec2-production"

  default_capacity_provider_use_fargate = false

  autoscaling_capacity_providers = {
    ec2_asg = {
      auto_scaling_group_arn = "arn:aws:autoscaling:ap-southeast-1:123456789012:autoScalingGroup:abc123:autoScalingGroupName/myapp-ecs-asg"
      managed_termination_protection = "ENABLED"
      managed_draining               = "ENABLED"

      managed_scaling = {
        minimum_scaling_step_size = 1
        maximum_scaling_step_size = 10
        status                    = "ENABLED"
        target_capacity           = 80
      }

      default_capacity_provider_strategy = {
        weight = 100
        base   = 1
      }
    }
  }

  create_node_iam_role             = true
  node_iam_role_attach_ssm_policy  = true

  create_security_group = true
  vpc_id                = "vpc-0abc123def456789a"
  security_group_rules = {
    egress_all = {
      type      = "egress"
      ip_protocol = "-1"
      cidr_ipv4 = "0.0.0.0/0"
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```
