# Amazon ECS

OpenTofu module for provisioning and managing Amazon Elastic Container Service (ECS) resources. This module is organized into three submodules for managing clusters, services, and container definitions independently.

## Submodules

- **`cluster`** - ECS cluster with capacity providers, autoscaling groups, CloudWatch logging, security groups, and task execution IAM roles
- **`service`** - ECS service with task definitions, load balancer integration, autoscaling policies, service discovery, Service Connect, and EBS volume support
- **`container-definition`** - Container definition builder with environment variables, secrets, logging, health checks, and resource configuration

## Features

- **Cluster Management** - ECS cluster with Container Insights, execute command configuration, and managed storage encryption
- **Capacity Providers** - Support for Fargate, Fargate Spot, and autoscaling group capacity providers with managed scaling
- **Service Deployment** - Configurable deployment strategies including rolling update, blue/green (CODE_DEPLOY), and external controllers
- **Task Definitions** - Full task definition management with Fargate and EC2 launch type support, EBS volumes, and runtime platform configuration
- **Container Definitions** - Comprehensive container configuration including health checks, environment files, secrets from SSM/Secrets Manager, and FireLens logging
- **Auto Scaling** - Application Auto Scaling with target tracking and scheduled scaling policies
- **Networking** - Integrated security group creation, VPC Lattice support, and Service Connect with CloudWatch logging
- **IAM Roles** - Automatic creation of task execution, task, service, and infrastructure IAM roles with customizable policies

## Usage

```hcl
module "ecs_cluster" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/cluster?depth=1&ref=master"

  cluster_name = "my-cluster"

  tags = {
    Environment = "production"
  }
}

module "ecs_service" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/service?depth=1&ref=master"

  name        = "my-service"
  cluster_arn = module.ecs_cluster.arn

  container_definitions = {
    app = {
      image     = "nginx:latest"
      cpu       = 256
      memory    = 512
      essential = true
      port_mappings = [
        { containerPort = 80, protocol = "tcp" }
      ]
    }
  }

  tags = {
    Environment = "production"
  }
}
```
