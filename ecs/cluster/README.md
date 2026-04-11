# ECS Cluster

OpenTofu module to create an Amazon ECS cluster with support for both Fargate and EC2 (autoscaling) capacity providers. Includes optional creation of a CloudWatch log group, task execution IAM role, node IAM role with instance profile, and a cluster security group.

## Features

- **Fargate and EC2 Support** - Configure Fargate capacity providers, autoscaling capacity providers backed by Auto Scaling Groups, or both
- **CloudWatch Log Group** - Automatically creates a log group for ECS Exec command logging with configurable retention, KMS encryption, and deletion protection
- **Task Execution IAM Role** - Optionally create a task execution role with permissions for ECR, CloudWatch Logs, SSM Parameter Store, and Secrets Manager
- **Node IAM Role** - Optionally create a node IAM role and instance profile for EC2 launch type with SSM Session Manager support
- **Security Group** - Optionally create a cluster-level security group with configurable ingress and egress rules
- **Container Insights** - CloudWatch Container Insights enabled by default via cluster settings
- **Service Connect** - Configure a default Service Connect namespace for the cluster
- **Managed Capacity Providers** - Support for managed scaling, managed termination protection, and managed draining on autoscaling capacity providers
- **Managed Instances Provider** - Configure managed instances with infrastructure role, tag propagation, infrastructure optimization, and instance launch templates on autoscaling capacity providers

## Usage

### Fargate Cluster

```hcl
module "ecs_cluster" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/cluster?depth=1&ref=master"

  cluster_name = "my-cluster"

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
  }
}
```

### EC2 Cluster with Autoscaling

```hcl
module "ecs_cluster" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/cluster?depth=1&ref=master"

  cluster_name                          = "my-ec2-cluster"
  default_capacity_provider_use_fargate = false

  autoscaling_capacity_providers = {
    my-asg = {
      auto_scaling_group_arn         = "arn:aws:autoscaling:us-east-1:123456789012:autoScalingGroup:xxx:autoScalingGroupName/my-asg"
      managed_termination_protection = "ENABLED"

      managed_scaling = {
        maximum_scaling_step_size = 5
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 80
      }

      default_capacity_provider_strategy = {
        weight = 100
        base   = 1
      }
    }
  }

  create_task_exec_iam_role = true
  create_node_iam_role      = true
  create_security_group     = true
  vpc_id                    = "vpc-0123456789abcdef0"

  tags = {
    Environment = "production"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `cluster_name` | Name of the cluster | `string` | `null` | no |
| `cluster_configuration` | The execute command configuration for the cluster | `any` | `{}` | no |
| `cluster_settings` | List of cluster settings (Container Insights enabled by default) | `any` | `[{name = "containerInsights", value = "enabled"}]` | no |
| `cluster_service_connect_defaults` | Configures a default Service Connect namespace | `map(string)` | `{}` | no |
| `create_cloudwatch_log_group` | Whether to create a CloudWatch log group for cluster logs | `bool` | `true` | no |
| `cloudwatch_log_group_retention_in_days` | Number of days to retain log events | `number` | `60` | no |
| `cloudwatch_log_group_kms_key_id` | KMS Key ARN for encrypting the log group | `string` | `null` | no |
| `default_capacity_provider_use_fargate` | Whether to use Fargate or autoscaling for default capacity provider strategy | `bool` | `true` | no |
| `fargate_capacity_providers` | Map of Fargate capacity provider definitions | `any` | `{}` | no |
| `autoscaling_capacity_providers` | Map of autoscaling capacity provider definitions | `any` | `{}` | no |
| `create_task_exec_iam_role` | Whether to create the ECS task execution IAM role | `bool` | `false` | no |
| `create_node_iam_role` | Whether to create the ECS node IAM role and instance profile | `bool` | `false` | no |
| `create_security_group` | Whether to create a security group for the cluster | `bool` | `false` | no |
| `vpc_id` | ID of the VPC where the security group will be created | `string` | `null` | no |
| `security_group_rules` | Map of security group rule objects | `any` | `{}` | no |
| `enabled` | Determines whether resources will be created | `bool` | `true` | no |
| `tags` | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `arn` | ARN that identifies the cluster |
| `id` | ID that identifies the cluster |
| `name` | Name that identifies the cluster |
| `cloudwatch_log_group_name` | Name of CloudWatch log group created |
| `cloudwatch_log_group_arn` | ARN of CloudWatch log group created |
| `cluster_capacity_providers` | Map of cluster capacity providers attributes |
| `autoscaling_capacity_providers` | Map of autoscaling capacity providers created and their attributes |
| `task_exec_iam_role_name` | Task execution IAM role name |
| `task_exec_iam_role_arn` | Task execution IAM role ARN |
| `node_iam_role_name` | Node IAM role name |
| `node_iam_role_arn` | Node IAM role ARN |
| `node_iam_instance_profile_arn` | Node IAM instance profile ARN |
| `security_group_arn` | ARN of the cluster security group |
| `security_group_id` | ID of the cluster security group |


## Examples

## Basic Fargate Cluster

A Fargate-only ECS cluster with Container Insights enabled and a dedicated CloudWatch log group for execute-command sessions.

```hcl
module "ecs_cluster" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/cluster?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/cluster?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/cluster?depth=1&ref=master"

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
