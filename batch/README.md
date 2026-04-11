# AWS Batch

OpenTofu module for provisioning AWS Batch compute environments, job queues, job definitions, and scheduling policies with full IAM and security group management.

## Features

- **Compute Environment** - Supports managed (EC2, Fargate, Spot) and unmanaged compute environments with configurable resources, launch templates, and EKS integration
- **Job Queues** - Multiple job queues with priority ordering, compute environment associations, and job state time limit actions
- **Job Definitions** - Container, multinode, and ECS job definitions with retry strategies, timeouts, and platform capabilities
- **Scheduling Policies** - Fair share scheduling with configurable compute reservation, share decay, and weighted share distribution
- **IAM Roles** - Automatic creation of Batch service role, ECS task execution role, and job role with customizable policy attachments
- **Security Groups** - Optional security group creation with configurable ingress and egress rules for compute environments
- **EKS Integration** - Native support for running Batch jobs on Amazon EKS clusters

## Usage

```hcl
module "batch" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//batch?depth=1&ref=master"

  name   = "my-batch-env"
  vpc_id = "vpc-0123456789abcdef0"

  compute_resources = {
    type      = "FARGATE"
    max_vcpus = 16
    subnets   = ["subnet-0123456789abcdef0"]
  }

  job_queues = {
    default = {
      name     = "my-job-queue"
      priority = 1
    }
  }

  tags = {
    Environment = "production"
  }
}
```

## Examples

### Fargate Compute Environment

A managed Fargate compute environment with a job queue and container job definition.

```hcl
module "batch_fargate" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//batch?depth=1&ref=master"

  name   = "data-pipeline-fargate"
  vpc_id = "vpc-0abc123def456789a"

  compute_resources = {
    type      = "FARGATE"
    max_vcpus = 32
    subnets   = ["subnet-0abc123def456789a", "subnet-0def456789abc123a"]
  }

  job_queues = {
    high_priority = {
      name     = "data-pipeline-high"
      priority = 10
    }
    low_priority = {
      name     = "data-pipeline-low"
      priority = 1
    }
  }

  job_definitions = {
    etl = {
      name                  = "data-pipeline-etl"
      platform_capabilities = ["FARGATE"]
      container_properties = jsonencode({
        image      = "123456789012.dkr.ecr.us-east-1.amazonaws.com/etl:latest"
        resourceRequirements = [
          { type = "VCPU", value = "2" },
          { type = "MEMORY", value = "4096" }
        ]
        executionRoleArn = "arn:aws:iam::123456789012:role/batch-execution"
        jobRoleArn       = "arn:aws:iam::123456789012:role/batch-job"
      })
      retry_strategy = {
        attempts = 3
        evaluate_on_exit = [
          { action = "RETRY", on_exit_code = "1" },
          { action = "EXIT", on_status_reason = "CannotPullContainerError:*" }
        ]
      }
      timeout = {
        attempt_duration_seconds = 3600
      }
    }
  }

  tags = {
    Environment = "production"
    Team        = "data-engineering"
  }
}
```

### EC2 Compute Environment with Fair Share Scheduling

An EC2-backed compute environment using spot instances with a fair share scheduling policy.

```hcl
module "batch_ec2" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//batch?depth=1&ref=master"

  name   = "ml-training"
  vpc_id = "vpc-0abc123def456789a"

  compute_resources = {
    type                = "SPOT"
    allocation_strategy = "SPOT_PRICE_CAPACITY_OPTIMIZED"
    max_vcpus           = 256
    min_vcpus           = 0
    instance_type       = ["m5.xlarge", "m5.2xlarge", "c5.xlarge"]
    bid_percentage      = 60
    subnets             = ["subnet-0abc123def456789a"]
  }

  scheduling_policies = {
    fair_share = {
      name = "ml-training-fair-share"
      fair_share_policy = {
        compute_reservation = 1
        share_decay_seconds = 3600
        share_distribution = [
          { share_identifier = "teamA", weight_factor = 0.5 },
          { share_identifier = "teamB", weight_factor = 0.5 }
        ]
      }
    }
  }

  job_queues = {
    training = {
      name                 = "ml-training-queue"
      priority             = 1
      scheduling_policy_key = "fair_share"
    }
  }

  tags = {
    Environment = "production"
    Team        = "ml-platform"
  }
}
```

### Minimal Unmanaged Environment

An unmanaged compute environment where you control the underlying compute infrastructure.

```hcl
module "batch_unmanaged" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//batch?depth=1&ref=master"

  name                    = "custom-compute"
  compute_environment_type = "UNMANAGED"
  create_security_group   = false
  create_service_role     = false
  create_execution_role   = false
  create_job_role         = false

  job_queues = {
    default = {
      name     = "custom-queue"
      priority = 1
    }
  }

  tags = {
    Environment = "staging"
  }
}
```
