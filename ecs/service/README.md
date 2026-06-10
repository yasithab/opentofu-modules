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
| alarms | Information about the CloudWatch alarms | `any` | `{}` | no |
| assign\_public\_ip | Assign a public IP address to the ENI (Fargate launch type only) | `bool` | `false` | no |
| autoscaling\_max\_capacity | Maximum number of tasks to run in your service | `number` | `10` | no |
| autoscaling\_min\_capacity | Minimum number of tasks to run in your service | `number` | `1` | no |
| autoscaling\_policies | Map of autoscaling policies to create for the service | `any` | <pre>{<br/>  "cpu": {<br/>    "policy_type": "TargetTrackingScaling",<br/>    "target_tracking_scaling_policy_configuration": {<br/>      "predefined_metric_specification": {<br/>        "predefined_metric_type": "ECSServiceAverageCPUUtilization"<br/>      }<br/>    }<br/>  },<br/>  "memory": {<br/>    "policy_type": "TargetTrackingScaling",<br/>    "target_tracking_scaling_policy_configuration": {<br/>      "predefined_metric_specification": {<br/>        "predefined_metric_type": "ECSServiceAverageMemoryUtilization"<br/>      }<br/>    }<br/>  }<br/>}</pre> | no |
| autoscaling\_role\_arn | The ARN of the IAM role that allows Application AutoScaling to modify the scalable target on your behalf. Only required when using a service-linked role is not possible | `string` | `null` | no |
| autoscaling\_scheduled\_actions | Map of autoscaling scheduled actions to create for the service | `any` | `{}` | no |
| autoscaling\_suspended\_state | Suspends scaling activities for the autoscaling target. Map of optional boolean keys: dynamic\_scaling\_in\_suspended, dynamic\_scaling\_out\_suspended, scheduled\_scaling\_suspended | `any` | `null` | no |
| availability\_zone\_rebalancing | ECS automatically redistributes tasks within a service across Availability Zones (AZs) to mitigate the risk of impaired application availability due to underlying infrastructure failures and task lifecycle activities. Valid values: ENABLED, DISABLED | `string` | `null` | no |
| capacity\_provider\_strategy | Capacity provider strategies to use for the service. Can be one or more | `any` | `{}` | no |
| cloudwatch\_log\_group\_deletion\_protection\_enabled | Whether to enable deletion protection on the CloudWatch log group. If enabled, the log group cannot be deleted. | `bool` | `null` | no |
| cloudwatch\_log\_group\_skip\_destroy | Set to true to prevent the service-connect log group from being deleted on module destroy | `bool` | `false` | no |
| cluster\_arn | ARN of the ECS cluster where the resources will be provisioned | `string` | `null` | no |
| container\_definition\_defaults | A map of default values for [container definitions](http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ContainerDefinition.html) created by `container_definitions` | `any` | `{}` | no |
| container\_definitions | A map of valid [container definitions](http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ContainerDefinition.html). Please note that you should only provide values that are part of the container definition document | `any` | `{}` | no |
| cpu | Number of cpu units used by the task. If the `requires_compatibilities` is `FARGATE` this field is required | `number` | `1024` | no |
| create\_iam\_role | Determines whether the ECS service IAM role should be created | `bool` | `true` | no |
| create\_infrastructure\_iam\_role | Determines whether the ECS infrastructure IAM role should be created. Required for managed EBS volumes (volume\_configuration) and VPC Lattice | `bool` | `false` | no |
| create\_security\_group | Determines if a security group is created | `bool` | `true` | no |
| create\_service | Determines whether service resource will be created (set to `false` in case you want to create task definition only) | `bool` | `true` | no |
| create\_task\_definition | Determines whether to create a task definition or use existing/provided | `bool` | `true` | no |
| create\_task\_exec\_iam\_role | Determines whether the ECS task definition IAM role should be created | `bool` | `true` | no |
| create\_task\_exec\_policy | Determines whether the ECS task definition IAM policy should be created. This includes permissions included in AmazonECSTaskExecutionRolePolicy as well as access to secrets and SSM parameters | `bool` | `true` | no |
| create\_tasks\_iam\_role | Determines whether the ECS tasks IAM role should be created | `bool` | `true` | no |
| deployment\_circuit\_breaker | Configuration block for deployment circuit breaker. Defaults to enabled with automatic rollback - set to `{ enable = false, rollback = false }` to opt out | `any` | <pre>{<br/>  "enable": true,<br/>  "rollback": true<br/>}</pre> | no |
| deployment\_configuration | Configuration block for deployment configuration (blue/green, canary, linear strategies) | `any` | `{}` | no |
| deployment\_controller | Configuration block for deployment controller configuration | `any` | `{}` | no |
| deployment\_maximum\_percent | Upper limit (as a percentage of the service's `desired_count`) of the number of running tasks that can be running in a service during a deployment | `number` | `200` | no |
| deployment\_minimum\_healthy\_percent | Lower limit (as a percentage of the service's `desired_count`) of the number of running tasks that must remain running and healthy in a service during a deployment | `number` | `66` | no |
| desired\_count | Number of instances of the task definition to place and keep running | `number` | `1` | no |
| enable\_autoscaling | Determines whether to enable autoscaling for the service | `bool` | `true` | no |
| enable\_ecs\_managed\_tags | Specifies whether to enable Amazon ECS managed tags for the tasks within the service | `bool` | `true` | no |
| enable\_execute\_command | Specifies whether to enable Amazon ECS Exec for the tasks within the service | `bool` | `false` | no |
| enable\_fault\_injection | Enables fault injection and allows for fault injection requests to be accepted from the task's containers. Valid values are `true` or `false` | `bool` | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| ephemeral\_storage | The amount of ephemeral storage to allocate for the task. This parameter is used to expand the total amount of ephemeral storage available, beyond the default amount, for tasks hosted on AWS Fargate | `any` | `{}` | no |
| external\_id | The external ID associated with the task set | `string` | `null` | no |
| family | A unique name for your task definition | `string` | `null` | no |
| firehose\_delivery\_stream\_arn | Existing Firehose delivery stream ARN for FireLens | `string` | `null` | no |
| force\_delete | Whether to allow deleting the task set without waiting for scaling down to 0 | `bool` | `null` | no |
| force\_new\_deployment | Enable to force a new task deployment of the service. This can be used to update tasks to use a newer Docker image with same image/tag combination, roll Fargate tasks onto a newer platform version, or immediately deploy `ordered_placement_strategy` and `placement_constraints` updates | `bool` | `true` | no |
| health\_check\_grace\_period\_seconds | Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 2147483647. Only valid for services configured to use load balancers | `number` | `null` | no |
| iam\_role\_arn | Existing IAM role ARN | `string` | `null` | no |
| iam\_role\_description | Description of the role | `string` | `null` | no |
| iam\_role\_name | Name to use on IAM role created | `string` | `null` | no |
| iam\_role\_path | IAM role path | `string` | `null` | no |
| iam\_role\_permissions\_boundary | ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| iam\_role\_statements | A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage | `any` | `{}` | no |
| iam\_role\_tags | A map of additional tags to add to the IAM role created | `map(string)` | `{}` | no |
| iam\_role\_use\_name\_prefix | Determines whether the IAM role name (`iam_role_name`) is used as a prefix | `bool` | `true` | no |
| ignore\_task\_definition\_changes | Whether changes to service `task_definition` changes should be ignored | `bool` | `false` | no |
| infrastructure\_iam\_role\_arn | Existing IAM role ARN to use as the infrastructure role | `string` | `null` | no |
| infrastructure\_iam\_role\_description | Description of the infrastructure IAM role | `string` | `null` | no |
| infrastructure\_iam\_role\_name | Name to use on the infrastructure IAM role created | `string` | `null` | no |
| infrastructure\_iam\_role\_path | IAM role path for the infrastructure role | `string` | `null` | no |
| infrastructure\_iam\_role\_permissions\_boundary | ARN of the policy used as permissions boundary for the infrastructure IAM role | `string` | `null` | no |
| infrastructure\_iam\_role\_policies | Map of IAM policy ARNs to attach to the infrastructure IAM role | `map(string)` | `{}` | no |
| infrastructure\_iam\_role\_tags | A map of additional tags to add to the infrastructure IAM role created | `map(string)` | `{}` | no |
| infrastructure\_iam\_role\_use\_name\_prefix | Determines whether the infrastructure IAM role name is used as a prefix | `bool` | `true` | no |
| ipc\_mode | IPC resource namespace to be used for the containers in the task The valid values are `host`, `task`, and `none` | `string` | `null` | no |
| launch\_type | Launch type on which to run your service. The valid values are `EC2`, `FARGATE`, and `EXTERNAL`. Defaults to `FARGATE` | `string` | `"FARGATE"` | no |
| load\_balancer | Configuration block for load balancers | `any` | `{}` | no |
| memory | Amount (in MiB) of memory used by the task. If the `requires_compatibilities` is `FARGATE` this field is required | `number` | `2048` | no |
| name | Name of the service (up to 255 letters, numbers, hyphens, and underscores) | `string` | `null` | no |
| network\_mode | Docker networking mode to use for the containers in the task. Valid values are `none`, `bridge`, `awsvpc`, and `host` | `string` | `"awsvpc"` | no |
| ordered\_placement\_strategy | Service level strategy rules that are taken into consideration during task placement. List from top to bottom in order of precedence | `any` | `{}` | no |
| pid\_mode | Process namespace to use for the containers in the task. The valid values are `host` and `task` | `string` | `null` | no |
| placement\_constraints | Configuration block for rules that are taken into consideration during task placement (up to max of 10). This is set at the service, see `task_definition_placement_constraints` for setting at the task definition | `any` | `{}` | no |
| platform\_version | Platform version on which to run your service. Only applicable for `launch_type` set to `FARGATE`. Defaults to `LATEST` | `string` | `null` | no |
| propagate\_tags | Specifies whether to propagate the tags from the task definition or the service to the tasks. The valid values are `SERVICE` and `TASK_DEFINITION` | `string` | `"SERVICE"` | no |
| proxy\_configuration | Configuration block for the App Mesh proxy | `any` | `{}` | no |
| requires\_compatibilities | Set of launch types required by the task. The valid values are `EC2` and `FARGATE` | `list(string)` | <pre>[<br/>  "FARGATE"<br/>]</pre> | no |
| runtime\_platform | Configuration block for `runtime_platform` that containers in your task may use | `any` | <pre>{<br/>  "cpu_architecture": "X86_64",<br/>  "operating_system_family": "LINUX"<br/>}</pre> | no |
| scale | A floating-point percentage of the desired number of tasks to place and keep running in the task set | `any` | `{}` | no |
| scheduling\_strategy | Scheduling strategy to use for the service. The valid values are `REPLICA` and `DAEMON`. Defaults to `REPLICA` | `string` | `null` | no |
| security\_group\_description | Description of the security group created | `string` | `null` | no |
| security\_group\_ids | List of security groups to associate with the task or service | `list(string)` | `[]` | no |
| security\_group\_name | Name to use on security group created | `string` | `null` | no |
| security\_group\_rules | Security group rules to add to the security group created | <pre>map(object({<br/>    type                         = optional(string, "ingress")<br/>    ip_protocol                  = optional(string, "tcp")<br/>    from_port                    = optional(number)<br/>    to_port                      = optional(number)<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    description                  = optional(string)<br/>    prefix_list_id               = optional(string)<br/>    referenced_security_group_id = optional(string)<br/>    tags                         = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| security\_group\_tags | A map of additional tags to add to the security group created | `map(string)` | `{}` | no |
| security\_group\_use\_name\_prefix | Determines whether the security group name (`security_group_name`) is used as a prefix | `bool` | `true` | no |
| service\_connect\_configuration | The ECS Service Connect configuration for this service to discover and connect to services, and be discovered by, and connected from, other services within a namespace | <pre>object({<br/>    enabled = optional(bool, true)<br/>    access_log_configuration = optional(object({<br/>      format                   = optional(string)<br/>      include_query_parameters = optional(bool)<br/>    }))<br/>    log_configuration = optional(object({<br/>      log_driver = string<br/>      options    = optional(map(string))<br/>      secret_option = optional(list(object({<br/>        name       = string<br/>        value_from = string<br/>      })))<br/>    }))<br/>    namespace = optional(string)<br/>    service = optional(list(object({<br/>      client_alias = optional(object({<br/>        dns_name = optional(string)<br/>        port     = number<br/>        test_traffic_rules = optional(object({<br/>          header = optional(object({<br/>            name = string<br/>            value = optional(object({<br/>              exact = string<br/>            }))<br/>          }))<br/>        }))<br/>      }))<br/>      discovery_name        = optional(string)<br/>      ingress_port_override = optional(number)<br/>      port_name             = string<br/>      timeout = optional(object({<br/>        idle_timeout_seconds        = optional(number)<br/>        per_request_timeout_seconds = optional(number)<br/>      }))<br/>      tls = optional(object({<br/>        issuer_cert_authority = object({<br/>          aws_pca_authority_arn = string<br/>        })<br/>        kms_key  = optional(string)<br/>        role_arn = optional(string)<br/>      }))<br/>    })))<br/>  })</pre> | `null` | no |
| service\_registries | Service discovery registries for the service | <pre>object({<br/>    container_name = optional(string)<br/>    container_port = optional(number)<br/>    port           = optional(number)<br/>    registry_arn   = string<br/>  })</pre> | `null` | no |
| service\_tags | A map of additional tags to add to the service | `map(string)` | `{}` | no |
| sigint\_rollback | Whether to enable rollback of the service when a SIGINT signal is received | `bool` | `null` | no |
| skip\_destroy | If true, the task definition is not deleted when the service is destroyed | `bool` | `true` | no |
| subnet\_ids | List of subnets to associate with the task or service | `list(string)` | `[]` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| task\_definition\_arn | Existing task definition ARN. Required when `create_task_definition` is `false` | `string` | `null` | no |
| task\_definition\_placement\_constraints | Configuration block for rules that are taken into consideration during task placement (up to max of 10). This is set at the task definition, see `placement_constraints` for setting at the service | `any` | `{}` | no |
| task\_exec\_iam\_role\_arn | Existing IAM role ARN | `string` | `null` | no |
| task\_exec\_iam\_role\_description | Description of the role | `string` | `null` | no |
| task\_exec\_iam\_role\_max\_session\_duration | Maximum session duration (in seconds) for ECS task execution role. Default is 3600. | `number` | `null` | no |
| task\_exec\_iam\_role\_name | Name to use on IAM role created | `string` | `null` | no |
| task\_exec\_iam\_role\_path | IAM role path | `string` | `null` | no |
| task\_exec\_iam\_role\_permissions\_boundary | ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| task\_exec\_iam\_role\_policies | Map of IAM role policy ARNs to attach to the IAM role | `map(string)` | `{}` | no |
| task\_exec\_iam\_role\_tags | A map of additional tags to add to the IAM role created | `map(string)` | `{}` | no |
| task\_exec\_iam\_role\_use\_name\_prefix | Determines whether the IAM role name (`task_exec_iam_role_name`) is used as a prefix | `bool` | `true` | no |
| task\_exec\_iam\_statements | A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage | `any` | `{}` | no |
| task\_exec\_secret\_arns | List of SecretsManager secret ARNs the task execution role will be permitted to get/read. Provide specific ARNs instead of wildcards to follow least-privilege | `list(string)` | `[]` | no |
| task\_exec\_ssm\_param\_arns | List of SSM parameter ARNs the task execution role will be permitted to get/read. Provide specific ARNs instead of wildcards to follow least-privilege | `list(string)` | `[]` | no |
| task\_tags | A map of additional tags to add to the task definition/set created | `map(string)` | `{}` | no |
| tasks\_iam\_role\_arn | Existing IAM role ARN | `string` | `null` | no |
| tasks\_iam\_role\_description | Description of the role | `string` | `null` | no |
| tasks\_iam\_role\_name | Name to use on IAM role created | `string` | `null` | no |
| tasks\_iam\_role\_path | IAM role path | `string` | `null` | no |
| tasks\_iam\_role\_permissions\_boundary | ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| tasks\_iam\_role\_policies | Map of IAM role policy ARNs to attach to the IAM role | `map(string)` | `{}` | no |
| tasks\_iam\_role\_statements | A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage | `any` | `{}` | no |
| tasks\_iam\_role\_tags | A map of additional tags to add to the IAM role created | `map(string)` | `{}` | no |
| tasks\_iam\_role\_use\_name\_prefix | Determines whether the IAM role name (`tasks_iam_role_name`) is used as a prefix | `bool` | `true` | no |
| timeouts | Create, update, and delete timeout configurations for the service | `map(string)` | `{}` | no |
| track\_latest | Whether should track latest task definition or the one created with the resource | `bool` | `true` | no |
| triggers | Map of arbitrary keys and values that, when changed, will trigger an in-place update (redeployment). Useful with `timestamp()` | `any` | `{}` | no |
| volume | Configuration block for volumes that containers in your task may use | `any` | `{}` | no |
| volume\_configuration | Configuration for a volume specified in the task definition as a volume that is configured at launch time. Currently, the only supported volume type is an Amazon EBS volume | `any` | `{}` | no |
| vpc\_lattice\_configurations | List of VPC Lattice configuration blocks to associate with the service. Each block requires port\_name, role\_arn, and target\_group\_arn | <pre>list(object({<br/>    port_name        = string<br/>    role_arn         = string<br/>    target_group_arn = string<br/>  }))</pre> | `[]` | no |
| wait\_for\_steady\_state | If true, Terraform will wait for the service to reach a steady state before continuing. Default is `false` | `bool` | `null` | no |
| wait\_until\_stable | Whether terraform should wait until the task set has reached `STEADY_STATE` | `bool` | `null` | no |
| wait\_until\_stable\_timeout | Wait timeout for task set to reach `STEADY_STATE`. Valid time units include `ns`, `us` (or µs), `ms`, `s`, `m`, and `h`. Default `10m` | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| autoscaling\_policies | Map of autoscaling policies and their attributes |
| autoscaling\_scheduled\_actions | Map of autoscaling scheduled actions and their attributes |
| container\_definitions | Container definitions |
| iam\_role\_arn | Service IAM role ARN |
| iam\_role\_name | Service IAM role name |
| iam\_role\_unique\_id | Stable and unique string identifying the service IAM role |
| id | ARN that identifies the service |
| infrastructure\_iam\_role\_arn | Infrastructure IAM role ARN |
| infrastructure\_iam\_role\_name | Infrastructure IAM role name |
| infrastructure\_iam\_role\_unique\_id | Stable and unique string identifying the infrastructure IAM role |
| name | Name of the service |
| security\_group\_arn | Amazon Resource Name (ARN) of the security group |
| security\_group\_id | ID of the security group |
| service\_connect\_log\_group\_arn | ARN of the CloudWatch log group created for Service Connect |
| service\_connect\_log\_group\_name | Name of the CloudWatch log group created for Service Connect |
| task\_definition\_arn | Full ARN of the Task Definition (including both `family` and `revision`) |
| task\_definition\_family | The unique name of the task definition |
| task\_definition\_family\_revision | The family and revision (family:revision) of the task definition |
| task\_definition\_revision | Revision of the task in a particular family |
| task\_exec\_iam\_role\_arn | Task execution IAM role ARN |
| task\_exec\_iam\_role\_name | Task execution IAM role name |
| task\_exec\_iam\_role\_unique\_id | Stable and unique string identifying the task execution IAM role |
| task\_set\_arn | The Amazon Resource Name (ARN) that identifies the task set |
| task\_set\_id | The ID of the task set |
| task\_set\_stability\_status | The stability status. This indicates whether the task set has reached a steady state |
| task\_set\_status | The status of the task set |
| tasks\_iam\_role\_arn | Tasks IAM role ARN |
| tasks\_iam\_role\_name | Tasks IAM role name |
| tasks\_iam\_role\_unique\_id | Stable and unique string identifying the tasks IAM role |
<!-- END_TF_DOCS -->

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

## Notes

- **Deployment circuit breaker default**: `deployment_circuit_breaker` now defaults to `{ enable = true, rollback = true }` so failed deployments roll back automatically. Pass `deployment_circuit_breaker = {}` to opt out (required when using the `CODE_DEPLOY` or `EXTERNAL` deployment controller, where the circuit breaker is not supported).
- **Module-created security group has no default rules**: when `create_security_group = true`, the security group is created with no ingress or egress rules. Tasks cannot pull images or reach AWS APIs without egress - define at least an egress rule via `security_group_rules`, for example:

  ```hcl
  security_group_rules = {
    egress_all = {
      type        = "egress"
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow all outbound"
    }
  }
  ```
