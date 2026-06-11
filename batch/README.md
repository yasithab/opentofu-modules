# AWS Batch

OpenTofu module for provisioning AWS Batch compute environments, job queues, job definitions, and scheduling policies with full IAM and security group management.

## Features

- **Compute Environment** - Supports managed (EC2, Fargate, Spot) and unmanaged compute environments with configurable resources, launch templates, and EKS integration
- **Job Queues** - Multiple job queues with priority ordering, compute environment associations, and job state time limit actions
- **Job Definitions** - Container, multinode, and ECS job definitions with retry strategies, timeouts, and platform capabilities
- **Scheduling Policies** - Fair share scheduling with configurable compute reservation, share decay, and weighted share distribution
- **IAM Roles** - Automatic creation of Batch service role, ECS task execution role, and job role with customizable policy attachments. Existing roles can be passed instead via `service_role_arn`, `execution_role_arn`, and `job_role_arn` (set the matching `create_*_role = false`); a MANAGED compute environment requires either `create_service_role = true` or `service_role_arn`
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

## Reference

<details>
<summary>Requirements, providers, inputs and outputs (generated by terraform-docs)</summary>

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
| compute\_environment\_state | State of the compute environment. Valid values: `ENABLED`, `DISABLED`. | `string` | `"ENABLED"` | no |
| compute\_environment\_type | Type of the compute environment. Valid values: `MANAGED`, `UNMANAGED`. | `string` | `"MANAGED"` | no |
| compute\_resources | Compute resources configuration for the compute environment. Required for MANAGED type. | <pre>object({<br/>    type                = optional(string, "FARGATE")<br/>    allocation_strategy = optional(string)<br/>    min_vcpus           = optional(number, 0)<br/>    max_vcpus           = optional(number, 16)<br/>    desired_vcpus       = optional(number)<br/>    instance_type       = optional(list(string))<br/>    instance_role       = optional(string)<br/>    image_id            = optional(string)<br/>    ec2_key_pair        = optional(string)<br/>    bid_percentage      = optional(number)<br/>    spot_iam_fleet_role = optional(string)<br/>    subnets             = optional(list(string), [])<br/>    security_group_ids  = optional(list(string), [])<br/>    tags                = optional(map(string))<br/>    ec2_configuration = optional(object({<br/>      image_id_override = optional(string)<br/>      image_type        = optional(string)<br/>    }))<br/>    launch_template = optional(object({<br/>      launch_template_id   = optional(string)<br/>      launch_template_name = optional(string)<br/>      version              = optional(string)<br/>    }))<br/>  })</pre> | `null` | no |
| create\_execution\_role | Whether to create the Batch execution IAM role for Fargate tasks. | `bool` | `true` | no |
| create\_job\_role | Whether to create a default job IAM role. | `bool` | `true` | no |
| create\_security\_group | Whether to create a security group for the Batch compute environment. | `bool` | `true` | no |
| create\_service\_role | Whether to create the Batch service IAM role. When false and the compute environment type is MANAGED, `service_role_arn` must be provided. | `bool` | `true` | no |
| eks\_configuration | EKS configuration for the compute environment. | <pre>object({<br/>    eks_cluster_arn      = string<br/>    kubernetes_namespace = string<br/>  })</pre> | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| execution\_role\_arn | ARN of an existing IAM execution role for Fargate tasks. Used when `create_execution_role` is false; reflected in the `execution_role_arn` output. | `string` | `null` | no |
| execution\_role\_policies | Map of additional IAM policy ARNs to attach to the execution role. | `map(string)` | `{}` | no |
| job\_definitions | Map of job definition configurations. `container_properties`, `node_properties`, and `ecs_properties` are JSON strings. | <pre>map(object({<br/>    name                  = string<br/>    type                  = optional(string, "container")<br/>    platform_capabilities = optional(list(string), ["FARGATE"])<br/>    propagate_tags        = optional(bool, true)<br/>    scheduling_priority   = optional(number)<br/>    parameters            = optional(map(string))<br/>    container_properties  = optional(string)<br/>    node_properties       = optional(string)<br/>    ecs_properties        = optional(string)<br/>    retry_strategy = optional(object({<br/>      attempts = optional(number, 3)<br/>      evaluate_on_exit = optional(list(object({<br/>        action           = string<br/>        on_exit_code     = optional(string)<br/>        on_reason        = optional(string)<br/>        on_status_reason = optional(string)<br/>      })), [])<br/>    }))<br/>    timeout = optional(object({<br/>      attempt_duration_seconds = optional(number)<br/>    }))<br/>  }))</pre> | `{}` | no |
| job\_queues | Map of job queue configurations to create. `scheduling_policy_key` references a key in `scheduling_policies`; `compute_environment_order` defaults to this module's compute environment. | <pre>map(object({<br/>    name                  = string<br/>    state                 = optional(string, "ENABLED")<br/>    priority              = optional(number, 1)<br/>    scheduling_policy_arn = optional(string)<br/>    scheduling_policy_key = optional(string)<br/>    compute_environment_order = optional(list(object({<br/>      order               = number<br/>      compute_environment = optional(string)<br/>    })))<br/>    job_state_time_limit_actions = optional(list(object({<br/>      action           = string<br/>      max_time_seconds = number<br/>      reason           = string<br/>      state            = string<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| job\_role\_arn | ARN of an existing IAM job role. Used when `create_job_role` is false; reflected in the `job_role_arn` output. | `string` | `null` | no |
| job\_role\_policies | Map of IAM policy ARNs to attach to the job role. | `map(string)` | `{}` | no |
| name | Name used as a prefix for all Batch resources. | `string` | n/a | yes |
| scheduling\_policies | Map of scheduling policy configurations with fair share settings. | <pre>map(object({<br/>    name = string<br/>    fair_share_policy = optional(object({<br/>      compute_reservation = optional(number, 0)<br/>      share_decay_seconds = optional(number, 0)<br/>      share_distribution = optional(list(object({<br/>        share_identifier = string<br/>        weight_factor    = optional(number, 1)<br/>      })), [])<br/>    }))<br/>  }))</pre> | `{}` | no |
| security\_group\_rules | Map of security group rules for the Batch compute environment. Use `type` key with value `ingress` or `egress`. | <pre>map(object({<br/>    type                         = optional(string, "ingress")<br/>    ip_protocol                  = optional(string, "tcp")<br/>    from_port                    = optional(number)<br/>    to_port                      = optional(number)<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    description                  = optional(string)<br/>    prefix_list_id               = optional(string)<br/>    referenced_security_group_id = optional(string)<br/>    tags                         = optional(map(string), {})<br/>  }))</pre> | <pre>{<br/>  "egress_all": {<br/>    "cidr_ipv4": "0.0.0.0/0",<br/>    "description": "Allow all outbound traffic",<br/>    "ip_protocol": "-1",<br/>    "type": "egress"<br/>  }<br/>}</pre> | no |
| service\_role\_arn | ARN of an existing IAM role for the Batch service. Used when `create_service_role` is false. | `string` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| update\_policy | Update policy for the compute environment. | <pre>object({<br/>    job_execution_timeout_minutes = optional(number, 30)<br/>    terminate_jobs_on_update      = optional(bool, false)<br/>  })</pre> | `null` | no |
| vpc\_id | VPC ID for the security group. Required when `create_security_group` is true. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| compute\_environment\_arn | The ARN of the Batch compute environment. |
| compute\_environment\_id | The ID of the Batch compute environment. |
| compute\_environment\_name | The name of the Batch compute environment. |
| compute\_environment\_status | The current status of the Batch compute environment. |
| execution\_role\_arn | The effective ARN of the Batch execution IAM role (created by the module or passed via `execution_role_arn`). |
| job\_definition\_arns | Map of job definition ARNs. |
| job\_definition\_ids | Map of job definition IDs. |
| job\_queue\_arns | Map of job queue ARNs. |
| job\_queue\_ids | Map of job queue IDs. |
| job\_role\_arn | The effective ARN of the Batch job IAM role (created by the module or passed via `job_role_arn`). |
| scheduling\_policy\_arns | Map of scheduling policy ARNs. |
| security\_group\_arn | The ARN of the Batch compute environment security group. |
| security\_group\_id | The ID of the Batch compute environment security group. |
| service\_role\_arn | The effective ARN of the Batch service IAM role (created by the module or passed via `service_role_arn`). |
<!-- END_TF_DOCS -->

</details>
