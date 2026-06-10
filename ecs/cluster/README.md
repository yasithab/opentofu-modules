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

  name         = "my-cluster"

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

  name                                  = "my-ec2-cluster"
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

## Examples

## Basic Fargate Cluster

A Fargate-only ECS cluster with Container Insights enabled and a dedicated CloudWatch log group for execute-command sessions.

```hcl
module "ecs_cluster" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ecs/cluster?depth=1&ref=master"

  enabled      = true
  name         = "myapp-production"

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
  name         = "myapp-production"

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
  name         = "myapp-ec2-production"

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
| autoscaling\_capacity\_providers | Map of autoscaling capacity provider definitions to create for the cluster | `any` | `{}` | no |
| cloudwatch\_log\_group\_class | Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT\_ACCESS | `string` | `null` | no |
| cloudwatch\_log\_group\_deletion\_protection\_enabled | Whether to enable deletion protection on the CloudWatch log group. If enabled, the log group cannot be deleted. | `bool` | `null` | no |
| cloudwatch\_log\_group\_kms\_key\_id | If a KMS Key ARN is set, this key will be used to encrypt the corresponding log group. Please be sure that the KMS Key has an appropriate key policy (https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html) | `string` | `null` | no |
| cloudwatch\_log\_group\_name | Custom name of CloudWatch Log Group for ECS cluster | `string` | `null` | no |
| cloudwatch\_log\_group\_retention\_in\_days | Number of days to retain log events | `number` | `60` | no |
| cloudwatch\_log\_group\_skip\_destroy | Set to true to prevent the log group from being deleted on module destroy. Preserves audit and execute-command logs. | `bool` | `false` | no |
| cloudwatch\_log\_group\_tags | A map of additional tags to add to the log group created | `map(string)` | `{}` | no |
| cluster\_configuration | The execute command configuration for the cluster | `any` | `{}` | no |
| cluster\_service\_connect\_defaults | Configures a default Service Connect namespace | `map(string)` | `{}` | no |
| cluster\_settings | List of configuration block(s) with cluster settings. For example, this can be used to enable CloudWatch Container Insights for a cluster | `any` | <pre>[<br/>  {<br/>    "name": "containerInsights",<br/>    "value": "enabled"<br/>  }<br/>]</pre> | no |
| create\_cloudwatch\_log\_group | Determines whether a log group is created by this module for the cluster logs. If not, AWS will automatically create one if logging is enabled | `bool` | `true` | no |
| create\_node\_iam\_role | Determines whether the ECS node IAM role and instance profile should be created. Required for EC2 launch type | `bool` | `false` | no |
| create\_security\_group | Determines whether a security group is created for the cluster (used with EC2 launch type) | `bool` | `false` | no |
| create\_task\_exec\_iam\_role | Determines whether the ECS task definition IAM role should be created | `bool` | `false` | no |
| create\_task\_exec\_policy | Determines whether the ECS task definition IAM policy should be created. This includes permissions included in AmazonECSTaskExecutionRolePolicy as well as access to secrets and SSM parameters | `bool` | `true` | no |
| default\_capacity\_provider\_use\_fargate | Determines whether to use Fargate or autoscaling for default capacity provider strategy | `bool` | `true` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| fargate\_capacity\_providers | Map of Fargate capacity provider definitions to use for the cluster | `any` | `{}` | no |
| name | Name of the cluster (up to 255 letters, numbers, hyphens, and underscores) | `string` | `null` | no |
| node\_iam\_role\_attach\_ssm\_policy | Whether to attach the AmazonSSMManagedInstanceCore policy to the node IAM role, enabling SSM Session Manager on EC2 nodes | `bool` | `true` | no |
| node\_iam\_role\_description | Description of the node IAM role | `string` | `null` | no |
| node\_iam\_role\_name | Name to use on the node IAM role created | `string` | `null` | no |
| node\_iam\_role\_path | IAM role path for the node role | `string` | `null` | no |
| node\_iam\_role\_permissions\_boundary | ARN of the policy used as permissions boundary for the node IAM role | `string` | `null` | no |
| node\_iam\_role\_policies | Map of IAM policy ARNs to attach to the node IAM role in addition to the defaults | `map(string)` | `{}` | no |
| node\_iam\_role\_tags | A map of additional tags to add to the node IAM role created | `map(string)` | `{}` | no |
| node\_iam\_role\_use\_name\_prefix | Determines whether the node IAM role name is used as a prefix | `bool` | `true` | no |
| security\_group\_description | Description of the security group | `string` | `null` | no |
| security\_group\_name | Name to use on the security group created | `string` | `null` | no |
| security\_group\_rules | Map of security group rule objects to add to the security group. Keys are rule names, values accept type (ingress/egress), ip\_protocol, from\_port, to\_port, and cidr\_ipv4/cidr\_ipv6/referenced\_security\_group\_id | <pre>map(object({<br/>    type                         = optional(string, "ingress")<br/>    ip_protocol                  = optional(string, "tcp")<br/>    from_port                    = optional(number)<br/>    to_port                      = optional(number)<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    description                  = optional(string)<br/>    prefix_list_id               = optional(string)<br/>    referenced_security_group_id = optional(string)<br/>    tags                         = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| security\_group\_tags | A map of additional tags to add to the security group created | `map(string)` | `{}` | no |
| security\_group\_use\_name\_prefix | Determines whether the security group name is used as a prefix | `bool` | `true` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| task\_exec\_iam\_role\_description | Description of the role | `string` | `null` | no |
| task\_exec\_iam\_role\_name | Name to use on IAM role created | `string` | `null` | no |
| task\_exec\_iam\_role\_path | IAM role path | `string` | `null` | no |
| task\_exec\_iam\_role\_permissions\_boundary | ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| task\_exec\_iam\_role\_policies | Map of IAM role policy ARNs to attach to the IAM role | `map(string)` | `{}` | no |
| task\_exec\_iam\_role\_tags | A map of additional tags to add to the IAM role created | `map(string)` | `{}` | no |
| task\_exec\_iam\_role\_use\_name\_prefix | Determines whether the IAM role name (`task_exec_iam_role_name`) is used as a prefix | `bool` | `true` | no |
| task\_exec\_iam\_statements | A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage | `any` | `{}` | no |
| task\_exec\_secret\_arns | List of SecretsManager secret ARNs the task execution role will be permitted to get/read. Provide specific ARNs instead of wildcards to follow least-privilege | `list(string)` | `[]` | no |
| task\_exec\_ssm\_param\_arns | List of SSM parameter ARNs the task execution role will be permitted to get/read. Provide specific ARNs instead of wildcards to follow least-privilege | `list(string)` | `[]` | no |
| vpc\_id | ID of the VPC where the security group will be created | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| arn | ARN that identifies the cluster |
| autoscaling\_capacity\_providers | Map of autoscaling capacity providers created and their attributes |
| cloudwatch\_log\_group\_arn | ARN of CloudWatch log group created |
| cloudwatch\_log\_group\_name | Name of CloudWatch log group created |
| cluster\_capacity\_providers | Map of cluster capacity providers attributes |
| id | ID that identifies the cluster |
| name | Name that identifies the cluster |
| node\_iam\_instance\_profile\_arn | Node IAM instance profile ARN |
| node\_iam\_instance\_profile\_name | Node IAM instance profile name |
| node\_iam\_role\_arn | Node IAM role ARN |
| node\_iam\_role\_name | Node IAM role name |
| node\_iam\_role\_unique\_id | Stable and unique string identifying the node IAM role |
| security\_group\_arn | Amazon Resource Name (ARN) of the cluster security group |
| security\_group\_id | ID of the cluster security group |
| task\_exec\_iam\_role\_arn | Task execution IAM role ARN |
| task\_exec\_iam\_role\_name | Task execution IAM role name |
| task\_exec\_iam\_role\_unique\_id | Stable and unique string identifying the task execution IAM role |
<!-- END_TF_DOCS -->

</details>
