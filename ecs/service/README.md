<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.11.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.37.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.37.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarms"></a> [alarms](#input\_alarms) | Information about the CloudWatch alarms | `any` | `{}` | no |
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Assign a public IP address to the ENI (Fargate launch type only) | `bool` | `false` | no |
| <a name="input_autoscaling_max_capacity"></a> [autoscaling\_max\_capacity](#input\_autoscaling\_max\_capacity) | Maximum number of tasks to run in your service | `number` | `10` | no |
| <a name="input_autoscaling_min_capacity"></a> [autoscaling\_min\_capacity](#input\_autoscaling\_min\_capacity) | Minimum number of tasks to run in your service | `number` | `1` | no |
| <a name="input_autoscaling_policies"></a> [autoscaling\_policies](#input\_autoscaling\_policies) | Map of autoscaling policies to create for the service | `any` | <pre>{<br/>  "cpu": {<br/>    "policy_type": "TargetTrackingScaling",<br/>    "target_tracking_scaling_policy_configuration": {<br/>      "predefined_metric_specification": {<br/>        "predefined_metric_type": "ECSServiceAverageCPUUtilization"<br/>      }<br/>    }<br/>  },<br/>  "memory": {<br/>    "policy_type": "TargetTrackingScaling",<br/>    "target_tracking_scaling_policy_configuration": {<br/>      "predefined_metric_specification": {<br/>        "predefined_metric_type": "ECSServiceAverageMemoryUtilization"<br/>      }<br/>    }<br/>  }<br/>}</pre> | no |
| <a name="input_autoscaling_role_arn"></a> [autoscaling\_role\_arn](#input\_autoscaling\_role\_arn) | The ARN of the IAM role that allows Application AutoScaling to modify the scalable target on your behalf. Only required when using a service-linked role is not possible | `string` | `null` | no |
| <a name="input_autoscaling_scheduled_actions"></a> [autoscaling\_scheduled\_actions](#input\_autoscaling\_scheduled\_actions) | Map of autoscaling scheduled actions to create for the service | `any` | `{}` | no |
| <a name="input_autoscaling_suspended_state"></a> [autoscaling\_suspended\_state](#input\_autoscaling\_suspended\_state) | Suspends scaling activities for the autoscaling target. Map of optional boolean keys: dynamic\_scaling\_in\_suspended, dynamic\_scaling\_out\_suspended, scheduled\_scaling\_suspended | `any` | `null` | no |
| <a name="input_availability_zone_rebalancing"></a> [availability\_zone\_rebalancing](#input\_availability\_zone\_rebalancing) | ECS automatically redistributes tasks within a service across Availability Zones (AZs) to mitigate the risk of impaired application availability due to underlying infrastructure failures and task lifecycle activities. Valid values: ENABLED, DISABLED | `string` | `null` | no |
| <a name="input_capacity_provider_strategy"></a> [capacity\_provider\_strategy](#input\_capacity\_provider\_strategy) | Capacity provider strategies to use for the service. Can be one or more | `any` | `{}` | no |
| <a name="input_cloudwatch_log_group_deletion_protection_enabled"></a> [cloudwatch\_log\_group\_deletion\_protection\_enabled](#input\_cloudwatch\_log\_group\_deletion\_protection\_enabled) | Whether to enable deletion protection on the CloudWatch log group. If enabled, the log group cannot be deleted. | `bool` | `null` | no |
| <a name="input_cloudwatch_log_group_skip_destroy"></a> [cloudwatch\_log\_group\_skip\_destroy](#input\_cloudwatch\_log\_group\_skip\_destroy) | Set to true to prevent the service-connect log group from being deleted on module destroy | `bool` | `false` | no |
| <a name="input_cluster_arn"></a> [cluster\_arn](#input\_cluster\_arn) | ARN of the ECS cluster where the resources will be provisioned | `string` | `null` | no |
| <a name="input_container_definition_defaults"></a> [container\_definition\_defaults](#input\_container\_definition\_defaults) | A map of default values for [container definitions](http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ContainerDefinition.html) created by `container_definitions` | `any` | `{}` | no |
| <a name="input_container_definitions"></a> [container\_definitions](#input\_container\_definitions) | A map of valid [container definitions](http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ContainerDefinition.html). Please note that you should only provide values that are part of the container definition document | `any` | `{}` | no |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | Number of cpu units used by the task. If the `requires_compatibilities` is `FARGATE` this field is required | `number` | `1024` | no |
| <a name="input_create_iam_role"></a> [create\_iam\_role](#input\_create\_iam\_role) | Determines whether the ECS service IAM role should be created | `bool` | `true` | no |
| <a name="input_create_infrastructure_iam_role"></a> [create\_infrastructure\_iam\_role](#input\_create\_infrastructure\_iam\_role) | Determines whether the ECS infrastructure IAM role should be created. Required for managed EBS volumes (volume\_configuration) and VPC Lattice | `bool` | `false` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Determines if a security group is created | `bool` | `true` | no |
| <a name="input_create_service"></a> [create\_service](#input\_create\_service) | Determines whether service resource will be created (set to `false` in case you want to create task definition only) | `bool` | `true` | no |
| <a name="input_create_task_definition"></a> [create\_task\_definition](#input\_create\_task\_definition) | Determines whether to create a task definition or use existing/provided | `bool` | `true` | no |
| <a name="input_create_task_exec_iam_role"></a> [create\_task\_exec\_iam\_role](#input\_create\_task\_exec\_iam\_role) | Determines whether the ECS task definition IAM role should be created | `bool` | `true` | no |
| <a name="input_create_task_exec_policy"></a> [create\_task\_exec\_policy](#input\_create\_task\_exec\_policy) | Determines whether the ECS task definition IAM policy should be created. This includes permissions included in AmazonECSTaskExecutionRolePolicy as well as access to secrets and SSM parameters | `bool` | `true` | no |
| <a name="input_create_tasks_iam_role"></a> [create\_tasks\_iam\_role](#input\_create\_tasks\_iam\_role) | Determines whether the ECS tasks IAM role should be created | `bool` | `true` | no |
| <a name="input_deployment_circuit_breaker"></a> [deployment\_circuit\_breaker](#input\_deployment\_circuit\_breaker) | Configuration block for deployment circuit breaker | `any` | `{}` | no |
| <a name="input_deployment_configuration"></a> [deployment\_configuration](#input\_deployment\_configuration) | Configuration block for deployment configuration (blue/green, canary, linear strategies) | `any` | `{}` | no |
| <a name="input_deployment_controller"></a> [deployment\_controller](#input\_deployment\_controller) | Configuration block for deployment controller configuration | `any` | `{}` | no |
| <a name="input_deployment_maximum_percent"></a> [deployment\_maximum\_percent](#input\_deployment\_maximum\_percent) | Upper limit (as a percentage of the service's `desired_count`) of the number of running tasks that can be running in a service during a deployment | `number` | `200` | no |
| <a name="input_deployment_minimum_healthy_percent"></a> [deployment\_minimum\_healthy\_percent](#input\_deployment\_minimum\_healthy\_percent) | Lower limit (as a percentage of the service's `desired_count`) of the number of running tasks that must remain running and healthy in a service during a deployment | `number` | `66` | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | Number of instances of the task definition to place and keep running | `number` | `1` | no |
| <a name="input_enable_autoscaling"></a> [enable\_autoscaling](#input\_enable\_autoscaling) | Determines whether to enable autoscaling for the service | `bool` | `true` | no |
| <a name="input_enable_ecs_managed_tags"></a> [enable\_ecs\_managed\_tags](#input\_enable\_ecs\_managed\_tags) | Specifies whether to enable Amazon ECS managed tags for the tasks within the service | `bool` | `true` | no |
| <a name="input_enable_execute_command"></a> [enable\_execute\_command](#input\_enable\_execute\_command) | Specifies whether to enable Amazon ECS Exec for the tasks within the service | `bool` | `false` | no |
| <a name="input_enable_fault_injection"></a> [enable\_fault\_injection](#input\_enable\_fault\_injection) | Enables fault injection and allows for fault injection requests to be accepted from the task's containers. Valid values are `true` or `false` | `bool` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Determines whether resources will be created (affects all resources) | `bool` | `true` | no |
| <a name="input_ephemeral_storage"></a> [ephemeral\_storage](#input\_ephemeral\_storage) | The amount of ephemeral storage to allocate for the task. This parameter is used to expand the total amount of ephemeral storage available, beyond the default amount, for tasks hosted on AWS Fargate | `any` | `{}` | no |
| <a name="input_external_id"></a> [external\_id](#input\_external\_id) | The external ID associated with the task set | `string` | `null` | no |
| <a name="input_family"></a> [family](#input\_family) | A unique name for your task definition | `string` | `null` | no |
| <a name="input_firehose_delivery_stream_arn"></a> [firehose\_delivery\_stream\_arn](#input\_firehose\_delivery\_stream\_arn) | Existing Firehose delivery stream ARN for FireLens | `string` | `null` | no |
| <a name="input_force_delete"></a> [force\_delete](#input\_force\_delete) | Whether to allow deleting the task set without waiting for scaling down to 0 | `bool` | `null` | no |
| <a name="input_force_new_deployment"></a> [force\_new\_deployment](#input\_force\_new\_deployment) | Enable to force a new task deployment of the service. This can be used to update tasks to use a newer Docker image with same image/tag combination, roll Fargate tasks onto a newer platform version, or immediately deploy `ordered_placement_strategy` and `placement_constraints` updates | `bool` | `true` | no |
| <a name="input_health_check_grace_period_seconds"></a> [health\_check\_grace\_period\_seconds](#input\_health\_check\_grace\_period\_seconds) | Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 2147483647. Only valid for services configured to use load balancers | `number` | `null` | no |
| <a name="input_iam_role_arn"></a> [iam\_role\_arn](#input\_iam\_role\_arn) | Existing IAM role ARN | `string` | `null` | no |
| <a name="input_iam_role_description"></a> [iam\_role\_description](#input\_iam\_role\_description) | Description of the role | `string` | `null` | no |
| <a name="input_iam_role_name"></a> [iam\_role\_name](#input\_iam\_role\_name) | Name to use on IAM role created | `string` | `null` | no |
| <a name="input_iam_role_path"></a> [iam\_role\_path](#input\_iam\_role\_path) | IAM role path | `string` | `null` | no |
| <a name="input_iam_role_permissions_boundary"></a> [iam\_role\_permissions\_boundary](#input\_iam\_role\_permissions\_boundary) | ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| <a name="input_iam_role_statements"></a> [iam\_role\_statements](#input\_iam\_role\_statements) | A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage | `any` | `{}` | no |
| <a name="input_iam_role_tags"></a> [iam\_role\_tags](#input\_iam\_role\_tags) | A map of additional tags to add to the IAM role created | `map(string)` | `{}` | no |
| <a name="input_iam_role_use_name_prefix"></a> [iam\_role\_use\_name\_prefix](#input\_iam\_role\_use\_name\_prefix) | Determines whether the IAM role name (`iam_role_name`) is used as a prefix | `bool` | `true` | no |
| <a name="input_ignore_task_definition_changes"></a> [ignore\_task\_definition\_changes](#input\_ignore\_task\_definition\_changes) | Whether changes to service `task_definition` changes should be ignored | `bool` | `false` | no |
| <a name="input_infrastructure_iam_role_arn"></a> [infrastructure\_iam\_role\_arn](#input\_infrastructure\_iam\_role\_arn) | Existing IAM role ARN to use as the infrastructure role | `string` | `null` | no |
| <a name="input_infrastructure_iam_role_description"></a> [infrastructure\_iam\_role\_description](#input\_infrastructure\_iam\_role\_description) | Description of the infrastructure IAM role | `string` | `null` | no |
| <a name="input_infrastructure_iam_role_name"></a> [infrastructure\_iam\_role\_name](#input\_infrastructure\_iam\_role\_name) | Name to use on the infrastructure IAM role created | `string` | `null` | no |
| <a name="input_infrastructure_iam_role_path"></a> [infrastructure\_iam\_role\_path](#input\_infrastructure\_iam\_role\_path) | IAM role path for the infrastructure role | `string` | `null` | no |
| <a name="input_infrastructure_iam_role_permissions_boundary"></a> [infrastructure\_iam\_role\_permissions\_boundary](#input\_infrastructure\_iam\_role\_permissions\_boundary) | ARN of the policy used as permissions boundary for the infrastructure IAM role | `string` | `null` | no |
| <a name="input_infrastructure_iam_role_policies"></a> [infrastructure\_iam\_role\_policies](#input\_infrastructure\_iam\_role\_policies) | Map of IAM policy ARNs to attach to the infrastructure IAM role | `map(string)` | `{}` | no |
| <a name="input_infrastructure_iam_role_tags"></a> [infrastructure\_iam\_role\_tags](#input\_infrastructure\_iam\_role\_tags) | A map of additional tags to add to the infrastructure IAM role created | `map(string)` | `{}` | no |
| <a name="input_infrastructure_iam_role_use_name_prefix"></a> [infrastructure\_iam\_role\_use\_name\_prefix](#input\_infrastructure\_iam\_role\_use\_name\_prefix) | Determines whether the infrastructure IAM role name is used as a prefix | `bool` | `true` | no |
| <a name="input_ipc_mode"></a> [ipc\_mode](#input\_ipc\_mode) | IPC resource namespace to be used for the containers in the task The valid values are `host`, `task`, and `none` | `string` | `null` | no |
| <a name="input_launch_type"></a> [launch\_type](#input\_launch\_type) | Launch type on which to run your service. The valid values are `EC2`, `FARGATE`, and `EXTERNAL`. Defaults to `FARGATE` | `string` | `"FARGATE"` | no |
| <a name="input_load_balancer"></a> [load\_balancer](#input\_load\_balancer) | Configuration block for load balancers | `any` | `{}` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Amount (in MiB) of memory used by the task. If the `requires_compatibilities` is `FARGATE` this field is required | `number` | `2048` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the service (up to 255 letters, numbers, hyphens, and underscores) | `string` | `null` | no |
| <a name="input_network_mode"></a> [network\_mode](#input\_network\_mode) | Docker networking mode to use for the containers in the task. Valid values are `none`, `bridge`, `awsvpc`, and `host` | `string` | `"awsvpc"` | no |
| <a name="input_ordered_placement_strategy"></a> [ordered\_placement\_strategy](#input\_ordered\_placement\_strategy) | Service level strategy rules that are taken into consideration during task placement. List from top to bottom in order of precedence | `any` | `{}` | no |
| <a name="input_pid_mode"></a> [pid\_mode](#input\_pid\_mode) | Process namespace to use for the containers in the task. The valid values are `host` and `task` | `string` | `null` | no |
| <a name="input_placement_constraints"></a> [placement\_constraints](#input\_placement\_constraints) | Configuration block for rules that are taken into consideration during task placement (up to max of 10). This is set at the service, see `task_definition_placement_constraints` for setting at the task definition | `any` | `{}` | no |
| <a name="input_platform_version"></a> [platform\_version](#input\_platform\_version) | Platform version on which to run your service. Only applicable for `launch_type` set to `FARGATE`. Defaults to `LATEST` | `string` | `null` | no |
| <a name="input_propagate_tags"></a> [propagate\_tags](#input\_propagate\_tags) | Specifies whether to propagate the tags from the task definition or the service to the tasks. The valid values are `SERVICE` and `TASK_DEFINITION` | `string` | `null` | no |
| <a name="input_proxy_configuration"></a> [proxy\_configuration](#input\_proxy\_configuration) | Configuration block for the App Mesh proxy | `any` | `{}` | no |
| <a name="input_requires_compatibilities"></a> [requires\_compatibilities](#input\_requires\_compatibilities) | Set of launch types required by the task. The valid values are `EC2` and `FARGATE` | `list(string)` | <pre>[<br/>  "FARGATE"<br/>]</pre> | no |
| <a name="input_runtime_platform"></a> [runtime\_platform](#input\_runtime\_platform) | Configuration block for `runtime_platform` that containers in your task may use | `any` | <pre>{<br/>  "cpu_architecture": "X86_64",<br/>  "operating_system_family": "LINUX"<br/>}</pre> | no |
| <a name="input_scale"></a> [scale](#input\_scale) | A floating-point percentage of the desired number of tasks to place and keep running in the task set | `any` | `{}` | no |
| <a name="input_scheduling_strategy"></a> [scheduling\_strategy](#input\_scheduling\_strategy) | Scheduling strategy to use for the service. The valid values are `REPLICA` and `DAEMON`. Defaults to `REPLICA` | `string` | `null` | no |
| <a name="input_security_group_description"></a> [security\_group\_description](#input\_security\_group\_description) | Description of the security group created | `string` | `null` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | List of security groups to associate with the task or service | `list(string)` | `[]` | no |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | Name to use on security group created | `string` | `null` | no |
| <a name="input_security_group_rules"></a> [security\_group\_rules](#input\_security\_group\_rules) | Security group rules to add to the security group created | `any` | `{}` | no |
| <a name="input_security_group_tags"></a> [security\_group\_tags](#input\_security\_group\_tags) | A map of additional tags to add to the security group created | `map(string)` | `{}` | no |
| <a name="input_security_group_use_name_prefix"></a> [security\_group\_use\_name\_prefix](#input\_security\_group\_use\_name\_prefix) | Determines whether the security group name (`security_group_name`) is used as a prefix | `bool` | `true` | no |
| <a name="input_service_connect_configuration"></a> [service\_connect\_configuration](#input\_service\_connect\_configuration) | The ECS Service Connect configuration for this service to discover and connect to services, and be discovered by, and connected from, other services within a namespace | <pre>object({<br/>    enabled = optional(bool, true)<br/>    access_log_configuration = optional(object({<br/>      format                   = optional(string)<br/>      include_query_parameters = optional(bool)<br/>    }))<br/>    log_configuration = optional(object({<br/>      log_driver = string<br/>      options    = optional(map(string))<br/>      secret_option = optional(list(object({<br/>        name       = string<br/>        value_from = string<br/>      })))<br/>    }))<br/>    namespace = optional(string)<br/>    service = optional(list(object({<br/>      client_alias = optional(object({<br/>        dns_name = optional(string)<br/>        port     = number<br/>        test_traffic_rules = optional(object({<br/>          header = optional(object({<br/>            name = string<br/>            value = optional(object({<br/>              exact = string<br/>            }))<br/>          }))<br/>        }))<br/>      }))<br/>      discovery_name        = optional(string)<br/>      ingress_port_override = optional(number)<br/>      port_name             = string<br/>      timeout = optional(object({<br/>        idle_timeout_seconds        = optional(number)<br/>        per_request_timeout_seconds = optional(number)<br/>      }))<br/>      tls = optional(object({<br/>        issuer_cert_authority = object({<br/>          aws_pca_authority_arn = string<br/>        })<br/>        kms_key  = optional(string)<br/>        role_arn = optional(string)<br/>      }))<br/>    })))<br/>  })</pre> | `null` | no |
| <a name="input_service_registries"></a> [service\_registries](#input\_service\_registries) | Service discovery registries for the service | <pre>object({<br/>    container_name = optional(string)<br/>    container_port = optional(number)<br/>    port           = optional(number)<br/>    registry_arn   = string<br/>  })</pre> | `null` | no |
| <a name="input_service_tags"></a> [service\_tags](#input\_service\_tags) | A map of additional tags to add to the service | `map(string)` | `{}` | no |
| <a name="input_sigint_rollback"></a> [sigint\_rollback](#input\_sigint\_rollback) | Whether to enable rollback of the service when a SIGINT signal is received | `bool` | `null` | no |
| <a name="input_skip_destroy"></a> [skip\_destroy](#input\_skip\_destroy) | If true, the task definition is not deleted when the service is destroyed | `bool` | `true` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnets to associate with the task or service | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_task_definition_arn"></a> [task\_definition\_arn](#input\_task\_definition\_arn) | Existing task definition ARN. Required when `create_task_definition` is `false` | `string` | `null` | no |
| <a name="input_task_definition_placement_constraints"></a> [task\_definition\_placement\_constraints](#input\_task\_definition\_placement\_constraints) | Configuration block for rules that are taken into consideration during task placement (up to max of 10). This is set at the task definition, see `placement_constraints` for setting at the service | `any` | `{}` | no |
| <a name="input_task_exec_iam_role_arn"></a> [task\_exec\_iam\_role\_arn](#input\_task\_exec\_iam\_role\_arn) | Existing IAM role ARN | `string` | `null` | no |
| <a name="input_task_exec_iam_role_description"></a> [task\_exec\_iam\_role\_description](#input\_task\_exec\_iam\_role\_description) | Description of the role | `string` | `null` | no |
| <a name="input_task_exec_iam_role_max_session_duration"></a> [task\_exec\_iam\_role\_max\_session\_duration](#input\_task\_exec\_iam\_role\_max\_session\_duration) | Maximum session duration (in seconds) for ECS task execution role. Default is 3600. | `number` | `null` | no |
| <a name="input_task_exec_iam_role_name"></a> [task\_exec\_iam\_role\_name](#input\_task\_exec\_iam\_role\_name) | Name to use on IAM role created | `string` | `null` | no |
| <a name="input_task_exec_iam_role_path"></a> [task\_exec\_iam\_role\_path](#input\_task\_exec\_iam\_role\_path) | IAM role path | `string` | `null` | no |
| <a name="input_task_exec_iam_role_permissions_boundary"></a> [task\_exec\_iam\_role\_permissions\_boundary](#input\_task\_exec\_iam\_role\_permissions\_boundary) | ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| <a name="input_task_exec_iam_role_policies"></a> [task\_exec\_iam\_role\_policies](#input\_task\_exec\_iam\_role\_policies) | Map of IAM role policy ARNs to attach to the IAM role | `map(string)` | `{}` | no |
| <a name="input_task_exec_iam_role_tags"></a> [task\_exec\_iam\_role\_tags](#input\_task\_exec\_iam\_role\_tags) | A map of additional tags to add to the IAM role created | `map(string)` | `{}` | no |
| <a name="input_task_exec_iam_role_use_name_prefix"></a> [task\_exec\_iam\_role\_use\_name\_prefix](#input\_task\_exec\_iam\_role\_use\_name\_prefix) | Determines whether the IAM role name (`task_exec_iam_role_name`) is used as a prefix | `bool` | `true` | no |
| <a name="input_task_exec_iam_statements"></a> [task\_exec\_iam\_statements](#input\_task\_exec\_iam\_statements) | A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage | `any` | `{}` | no |
| <a name="input_task_exec_secret_arns"></a> [task\_exec\_secret\_arns](#input\_task\_exec\_secret\_arns) | List of SecretsManager secret ARNs the task execution role will be permitted to get/read. Provide specific ARNs instead of wildcards to follow least-privilege | `list(string)` | `[]` | no |
| <a name="input_task_exec_ssm_param_arns"></a> [task\_exec\_ssm\_param\_arns](#input\_task\_exec\_ssm\_param\_arns) | List of SSM parameter ARNs the task execution role will be permitted to get/read. Provide specific ARNs instead of wildcards to follow least-privilege | `list(string)` | `[]` | no |
| <a name="input_task_tags"></a> [task\_tags](#input\_task\_tags) | A map of additional tags to add to the task definition/set created | `map(string)` | `{}` | no |
| <a name="input_tasks_iam_role_arn"></a> [tasks\_iam\_role\_arn](#input\_tasks\_iam\_role\_arn) | Existing IAM role ARN | `string` | `null` | no |
| <a name="input_tasks_iam_role_description"></a> [tasks\_iam\_role\_description](#input\_tasks\_iam\_role\_description) | Description of the role | `string` | `null` | no |
| <a name="input_tasks_iam_role_name"></a> [tasks\_iam\_role\_name](#input\_tasks\_iam\_role\_name) | Name to use on IAM role created | `string` | `null` | no |
| <a name="input_tasks_iam_role_path"></a> [tasks\_iam\_role\_path](#input\_tasks\_iam\_role\_path) | IAM role path | `string` | `null` | no |
| <a name="input_tasks_iam_role_permissions_boundary"></a> [tasks\_iam\_role\_permissions\_boundary](#input\_tasks\_iam\_role\_permissions\_boundary) | ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| <a name="input_tasks_iam_role_policies"></a> [tasks\_iam\_role\_policies](#input\_tasks\_iam\_role\_policies) | Map of IAM role policy ARNs to attach to the IAM role | `map(string)` | `{}` | no |
| <a name="input_tasks_iam_role_statements"></a> [tasks\_iam\_role\_statements](#input\_tasks\_iam\_role\_statements) | A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage | `any` | `{}` | no |
| <a name="input_tasks_iam_role_tags"></a> [tasks\_iam\_role\_tags](#input\_tasks\_iam\_role\_tags) | A map of additional tags to add to the IAM role created | `map(string)` | `{}` | no |
| <a name="input_tasks_iam_role_use_name_prefix"></a> [tasks\_iam\_role\_use\_name\_prefix](#input\_tasks\_iam\_role\_use\_name\_prefix) | Determines whether the IAM role name (`tasks_iam_role_name`) is used as a prefix | `bool` | `true` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Create, update, and delete timeout configurations for the service | `map(string)` | `{}` | no |
| <a name="input_track_latest"></a> [track\_latest](#input\_track\_latest) | Whether should track latest task definition or the one created with the resource | `bool` | `true` | no |
| <a name="input_triggers"></a> [triggers](#input\_triggers) | Map of arbitrary keys and values that, when changed, will trigger an in-place update (redeployment). Useful with `timestamp()` | `any` | `{}` | no |
| <a name="input_volume"></a> [volume](#input\_volume) | Configuration block for volumes that containers in your task may use | `any` | `{}` | no |
| <a name="input_volume_configuration"></a> [volume\_configuration](#input\_volume\_configuration) | Configuration for a volume specified in the task definition as a volume that is configured at launch time. Currently, the only supported volume type is an Amazon EBS volume | `any` | `{}` | no |
| <a name="input_vpc_lattice_configurations"></a> [vpc\_lattice\_configurations](#input\_vpc\_lattice\_configurations) | List of VPC Lattice configuration blocks to associate with the service. Each block requires port\_name, role\_arn, and target\_group\_arn | <pre>list(object({<br/>    port_name        = string<br/>    role_arn         = string<br/>    target_group_arn = string<br/>  }))</pre> | `[]` | no |
| <a name="input_wait_for_steady_state"></a> [wait\_for\_steady\_state](#input\_wait\_for\_steady\_state) | If true, Terraform will wait for the service to reach a steady state before continuing. Default is `false` | `bool` | `null` | no |
| <a name="input_wait_until_stable"></a> [wait\_until\_stable](#input\_wait\_until\_stable) | Whether terraform should wait until the task set has reached `STEADY_STATE` | `bool` | `null` | no |
| <a name="input_wait_until_stable_timeout"></a> [wait\_until\_stable\_timeout](#input\_wait\_until\_stable\_timeout) | Wait timeout for task set to reach `STEADY_STATE`. Valid time units include `ns`, `us` (or µs), `ms`, `s`, `m`, and `h`. Default `10m` | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_autoscaling_policies"></a> [autoscaling\_policies](#output\_autoscaling\_policies) | Map of autoscaling policies and their attributes |
| <a name="output_autoscaling_scheduled_actions"></a> [autoscaling\_scheduled\_actions](#output\_autoscaling\_scheduled\_actions) | Map of autoscaling scheduled actions and their attributes |
| <a name="output_container_definitions"></a> [container\_definitions](#output\_container\_definitions) | Container definitions |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | Service IAM role ARN |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | Service IAM role name |
| <a name="output_iam_role_unique_id"></a> [iam\_role\_unique\_id](#output\_iam\_role\_unique\_id) | Stable and unique string identifying the service IAM role |
| <a name="output_id"></a> [id](#output\_id) | ARN that identifies the service |
| <a name="output_infrastructure_iam_role_arn"></a> [infrastructure\_iam\_role\_arn](#output\_infrastructure\_iam\_role\_arn) | Infrastructure IAM role ARN |
| <a name="output_infrastructure_iam_role_name"></a> [infrastructure\_iam\_role\_name](#output\_infrastructure\_iam\_role\_name) | Infrastructure IAM role name |
| <a name="output_infrastructure_iam_role_unique_id"></a> [infrastructure\_iam\_role\_unique\_id](#output\_infrastructure\_iam\_role\_unique\_id) | Stable and unique string identifying the infrastructure IAM role |
| <a name="output_name"></a> [name](#output\_name) | Name of the service |
| <a name="output_security_group_arn"></a> [security\_group\_arn](#output\_security\_group\_arn) | Amazon Resource Name (ARN) of the security group |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the security group |
| <a name="output_service_connect_log_group_arn"></a> [service\_connect\_log\_group\_arn](#output\_service\_connect\_log\_group\_arn) | ARN of the CloudWatch log group created for Service Connect |
| <a name="output_service_connect_log_group_name"></a> [service\_connect\_log\_group\_name](#output\_service\_connect\_log\_group\_name) | Name of the CloudWatch log group created for Service Connect |
| <a name="output_task_definition_arn"></a> [task\_definition\_arn](#output\_task\_definition\_arn) | Full ARN of the Task Definition (including both `family` and `revision`) |
| <a name="output_task_definition_family"></a> [task\_definition\_family](#output\_task\_definition\_family) | The unique name of the task definition |
| <a name="output_task_definition_family_revision"></a> [task\_definition\_family\_revision](#output\_task\_definition\_family\_revision) | The family and revision (family:revision) of the task definition |
| <a name="output_task_definition_revision"></a> [task\_definition\_revision](#output\_task\_definition\_revision) | Revision of the task in a particular family |
| <a name="output_task_exec_iam_role_arn"></a> [task\_exec\_iam\_role\_arn](#output\_task\_exec\_iam\_role\_arn) | Task execution IAM role ARN |
| <a name="output_task_exec_iam_role_name"></a> [task\_exec\_iam\_role\_name](#output\_task\_exec\_iam\_role\_name) | Task execution IAM role name |
| <a name="output_task_exec_iam_role_unique_id"></a> [task\_exec\_iam\_role\_unique\_id](#output\_task\_exec\_iam\_role\_unique\_id) | Stable and unique string identifying the task execution IAM role |
| <a name="output_task_set_arn"></a> [task\_set\_arn](#output\_task\_set\_arn) | The Amazon Resource Name (ARN) that identifies the task set |
| <a name="output_task_set_id"></a> [task\_set\_id](#output\_task\_set\_id) | The ID of the task set |
| <a name="output_task_set_stability_status"></a> [task\_set\_stability\_status](#output\_task\_set\_stability\_status) | The stability status. This indicates whether the task set has reached a steady state |
| <a name="output_task_set_status"></a> [task\_set\_status](#output\_task\_set\_status) | The status of the task set |
| <a name="output_tasks_iam_role_arn"></a> [tasks\_iam\_role\_arn](#output\_tasks\_iam\_role\_arn) | Tasks IAM role ARN |
| <a name="output_tasks_iam_role_name"></a> [tasks\_iam\_role\_name](#output\_tasks\_iam\_role\_name) | Tasks IAM role name |
| <a name="output_tasks_iam_role_unique_id"></a> [tasks\_iam\_role\_unique\_id](#output\_tasks\_iam\_role\_unique\_id) | Stable and unique string identifying the tasks IAM role |
<!-- END_TF_DOCS -->
