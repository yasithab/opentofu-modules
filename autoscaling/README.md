# Auto Scaling Group

OpenTofu module for creating and managing AWS Auto Scaling Groups with launch templates, mixed instances policies, scaling policies, warm pools, and lifecycle hooks.

## Features

- **Launch Template** - Configurable launch template with IMDSv2 enforced by default, EBS encryption, and detailed monitoring
- **Mixed Instances Policy** - Support for spot and on-demand instance mixing with configurable allocation strategies
- **Scaling Policies** - Target tracking, step, simple, and predictive scaling policies
- **Scheduled Actions** - Time-based scaling with cron expressions and time zones
- **Warm Pool** - Pre-initialized instances for faster scale-out with configurable pool state and reuse policies
- **Instance Refresh** - Rolling updates with configurable minimum healthy percentage and checkpoints
- **Lifecycle Hooks** - Launch and terminate hooks for custom initialization and cleanup actions
- **Notification Configurations** - SNS notifications for ASG events
- **Traffic Source Attachments** - ALB/NLB target group integration
- **IAM Instance Profile** - Optional IAM role and instance profile creation
- **Security Group** - Optional security group with ingress and egress rules
- **Security by Default** - IMDSv2 required, detailed monitoring enabled, EBS encryption default

### Desired capacity drift

Whether OpenTofu manages `desired_capacity` is controlled by the
`ignore_desired_capacity_changes` variable (default `true`).

OpenTofu cannot make `lifecycle { ignore_changes }` dynamic, so the module maintains
**two copies** of the ASG resource and enables exactly one via mutually exclusive
`lifecycle { enabled }` conditions (the same pattern as the `dynamodb` module's 3-copy
table):

| `ignore_desired_capacity_changes` | Active resource address | Behaviour |
|---|---|---|
| `true` (default) | `aws_autoscaling_group.this` | `lifecycle { ignore_changes = [desired_capacity] }` - changes made by scaling policies, scheduled actions, or manual console edits are **never reverted** by OpenTofu, and updating `desired_capacity` in your configuration after initial creation has **no effect** on the existing group. Use `min_size`/`max_size` to bound capacity. |
| `false` | `aws_autoscaling_group.tracked` | `desired_capacity` is fully managed - OpenTofu reverts out-of-band changes and applies configuration updates. Only use this when nothing else (scaling policies, scheduled actions) adjusts capacity. |

All module outputs resolve from whichever resource is active, so consumers are
unaffected by the choice.

### Launch template naming

The launch template uses `name_prefix` (`<name>-`) with `create_before_destroy` instead of an
exact name, so template changes that require replacement do not fail on name collisions.

## Usage

```hcl
module "asg" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//autoscaling?depth=1&ref=master"

  name = "my-app"

  image_id      = "ami-0abcdef1234567890"
  instance_type = "t3.medium"

  min_size            = 1
  max_size            = 5
  desired_capacity    = 2
  vpc_zone_identifier = ["subnet-abc123", "subnet-def456"]

  tags = {
    Environment = "production"
  }
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
| block\_device\_mappings | List of block device mappings for the launch template. EBS volumes are gp3 and encrypted by default. | <pre>list(object({<br/>    device_name = string<br/>    ebs = optional(object({<br/>      volume_size           = optional(number)<br/>      volume_type           = optional(string, "gp3")<br/>      encrypted             = optional(bool, true)<br/>      kms_key_id            = optional(string)<br/>      iops                  = optional(number)<br/>      throughput            = optional(number)<br/>      delete_on_termination = optional(bool, true)<br/>      snapshot_id           = optional(string)<br/>    }))<br/>  }))</pre> | `[]` | no |
| capacity\_rebalance | Whether capacity rebalancing is enabled | `bool` | `false` | no |
| create\_iam\_instance\_profile | Whether to create an IAM instance profile and role | `bool` | `false` | no |
| create\_launch\_template | Whether to create a launch template | `bool` | `true` | no |
| create\_security\_group | Whether to create a security group for the instances | `bool` | `false` | no |
| default\_cooldown | Default cooldown period in seconds between scaling activities | `number` | `null` | no |
| default\_instance\_warmup | Default instance warmup time in seconds | `number` | `null` | no |
| desired\_capacity | Desired number of instances in the ASG. NOTE: when `ignore_desired_capacity_changes` is true (the default), out-of-band changes to desired capacity (e.g., by scaling policies or scheduled actions) are ignored (`lifecycle.ignore_changes`); OpenTofu will not revert them on subsequent applies. See the README's 'Desired capacity drift' section. | `number` | `null` | no |
| ebs\_optimized | Whether the instance is EBS-optimized | `bool` | `null` | no |
| enable\_monitoring | Whether to enable detailed monitoring for instances | `bool` | `true` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| enabled\_metrics | List of ASG metrics to enable. Defaults to all metrics. | `list(string)` | <pre>[<br/>  "GroupDesiredCapacity",<br/>  "GroupInServiceCapacity",<br/>  "GroupInServiceInstances",<br/>  "GroupMaxSize",<br/>  "GroupMinSize",<br/>  "GroupPendingCapacity",<br/>  "GroupPendingInstances",<br/>  "GroupStandbyCapacity",<br/>  "GroupStandbyInstances",<br/>  "GroupTerminatingCapacity",<br/>  "GroupTerminatingInstances",<br/>  "GroupTotalCapacity",<br/>  "GroupTotalInstances"<br/>]</pre> | no |
| force\_delete | Whether to force delete the ASG without waiting for instances to terminate | `bool` | `false` | no |
| health\_check\_grace\_period | Time in seconds after instance launch before health checking starts | `number` | `300` | no |
| health\_check\_type | Type of health check. Valid values: `EC2`, `ELB`. | `string` | `"EC2"` | no |
| iam\_instance\_profile\_arn | ARN of an existing IAM instance profile. Mutually exclusive with `create_iam_instance_profile`. | `string` | `null` | no |
| iam\_role\_description | Description for the IAM role | `string` | `null` | no |
| iam\_role\_name | Name of the IAM role. Defaults to `<name>-role`. | `string` | `null` | no |
| iam\_role\_path | Path for the IAM role | `string` | `null` | no |
| iam\_role\_permissions\_boundary | ARN of the permissions boundary policy for the IAM role | `string` | `null` | no |
| iam\_role\_policies | Map of inline IAM policies. Key is the policy name, value is the JSON policy document. | `map(string)` | `{}` | no |
| iam\_role\_policy\_arns | Map of IAM policy ARNs to attach to the role | `map(string)` | `{}` | no |
| ignore\_desired\_capacity\_changes | Whether to ignore out-of-band changes to `desired_capacity` (default true). When true the ASG is created as `aws_autoscaling_group.this` with `lifecycle.ignore_changes = [desired_capacity]`, so scaling policies/scheduled actions/manual edits are never reverted. When false the ASG is created as `aws_autoscaling_group.tracked` and OpenTofu manages `desired_capacity` like any other attribute. Toggling this after creation moves the group to a different resource address - see the README's 'Desired capacity drift' section for the required `tofu state mv`. | `bool` | `true` | no |
| image\_id | AMI ID to use for the launch template | `string` | `null` | no |
| instance\_refresh | Instance refresh configuration. Set to `{}` to enable with defaults. Supports `strategy`, `preferences`, and `triggers`. | <pre>object({<br/>    strategy = optional(string, "Rolling")<br/>    triggers = optional(list(string))<br/>    preferences = optional(object({<br/>      min_healthy_percentage       = optional(number, 90)<br/>      instance_warmup              = optional(number)<br/>      checkpoint_delay             = optional(number)<br/>      checkpoint_percentages       = optional(list(number))<br/>      skip_matching                = optional(bool)<br/>      auto_rollback                = optional(bool)<br/>      scale_in_protected_instances = optional(string)<br/>      standby_instances            = optional(string)<br/>    }))<br/>  })</pre> | `null` | no |
| instance\_type | Instance type to use for the launch template | `string` | `null` | no |
| key\_name | Key pair name to associate with instances | `string` | `null` | no |
| launch\_template\_description | Description for the launch template | `string` | `null` | no |
| launch\_template\_id | ID of an existing launch template to use. Required if `create_launch_template` is false. | `string` | `null` | no |
| launch\_template\_version | Launch template version. Can be version number, `$Latest`, or `$Default`. | `string` | `null` | no |
| lifecycle\_hooks | Map of lifecycle hooks. Each entry supports `lifecycle_transition`, `default_result`, `heartbeat_timeout`, `notification_metadata`, `notification_target_arn`, and `role_arn`. | <pre>map(object({<br/>    name                    = optional(string)<br/>    lifecycle_transition    = string<br/>    default_result          = optional(string, "CONTINUE")<br/>    heartbeat_timeout       = optional(number, 3600)<br/>    notification_metadata   = optional(string)<br/>    notification_target_arn = optional(string)<br/>    role_arn                = optional(string)<br/>  }))</pre> | `{}` | no |
| max\_instance\_lifetime | Maximum amount of time in seconds an instance can be in service | `number` | `null` | no |
| max\_size | Maximum number of instances in the ASG | `number` | `1` | no |
| metadata\_options | Metadata options for the launch template. Defaults enforce IMDSv2. | <pre>object({<br/>    http_endpoint               = optional(string, "enabled")<br/>    http_tokens                 = optional(string, "required")<br/>    http_put_response_hop_limit = optional(number, 2)<br/>    instance_metadata_tags      = optional(string)<br/>  })</pre> | `{}` | no |
| metrics\_granularity | Granularity for ASG metrics | `string` | `"1Minute"` | no |
| min\_size | Minimum number of instances in the ASG | `number` | `0` | no |
| mixed\_instances\_override | List of instance type overrides for mixed instances policy | <pre>list(object({<br/>    instance_type     = optional(string)<br/>    weighted_capacity = optional(string)<br/>  }))</pre> | `[]` | no |
| name | Name used for the Auto Scaling Group, launch template, and related resources | `string` | n/a | yes |
| network\_interfaces | List of network interface configurations for the launch template. `device_index` defaults to the list index; `security_groups` defaults to the module-managed security group IDs. | <pre>list(object({<br/>    associate_public_ip_address = optional(bool)<br/>    delete_on_termination       = optional(bool, true)<br/>    description                 = optional(string)<br/>    device_index                = optional(number)<br/>    security_groups             = optional(list(string))<br/>    subnet_id                   = optional(string)<br/>  }))</pre> | `[]` | no |
| notification\_configurations | Map of notification configurations. Each entry requires `topic_arn` and `notifications` (list of event types). | <pre>map(object({<br/>    topic_arn     = string<br/>    notifications = list(string)<br/>  }))</pre> | `{}` | no |
| on\_demand\_base\_capacity | Absolute minimum number of on-demand instances | `number` | `0` | no |
| on\_demand\_percentage\_above\_base\_capacity | Percentage of on-demand instances beyond the base capacity | `number` | `100` | no |
| placement | Placement configuration for the launch template | <pre>object({<br/>    availability_zone = optional(string)<br/>    group_name        = optional(string)<br/>    tenancy           = optional(string)<br/>  })</pre> | `null` | no |
| protect\_from\_scale\_in | Whether instances are protected from scale-in | `bool` | `false` | no |
| scaling\_policies | Map of scaling policies to create. Supports target\_tracking, step, simple, and predictive types. | <pre>map(object({<br/>    name                      = optional(string)<br/>    policy_type               = optional(string, "TargetTrackingScaling")<br/>    adjustment_type           = optional(string)<br/>    scaling_adjustment        = optional(number)<br/>    cooldown                  = optional(number)<br/>    min_adjustment_magnitude  = optional(number)<br/>    metric_aggregation_type   = optional(string)<br/>    estimated_instance_warmup = optional(number)<br/>    target_tracking_configuration = optional(object({<br/>      target_value     = number<br/>      disable_scale_in = optional(bool, false)<br/>      predefined_metric_specification = optional(object({<br/>        predefined_metric_type = string<br/>        resource_label         = optional(string)<br/>      }))<br/>      customized_metric_specification = optional(object({<br/>        metric_name = optional(string)<br/>        namespace   = optional(string)<br/>        statistic   = optional(string)<br/>        unit        = optional(string)<br/>        metric_dimensions = optional(list(object({<br/>          name  = string<br/>          value = string<br/>        })), [])<br/>      }))<br/>    }))<br/>    step_adjustments = optional(list(object({<br/>      scaling_adjustment          = number<br/>      metric_interval_lower_bound = optional(number)<br/>      metric_interval_upper_bound = optional(number)<br/>    })), [])<br/>    predictive_scaling_configuration = optional(object({<br/>      mode                         = optional(string, "ForecastAndScale")<br/>      scheduling_buffer_time       = optional(number)<br/>      max_capacity_breach_behavior = optional(string)<br/>      max_capacity_buffer          = optional(number)<br/>      metric_specification = optional(object({<br/>        target_value = number<br/>        predefined_scaling_metric_specification = optional(object({<br/>          predefined_metric_type = string<br/>          resource_label         = optional(string)<br/>        }))<br/>        predefined_load_metric_specification = optional(object({<br/>          predefined_metric_type = string<br/>          resource_label         = optional(string)<br/>        }))<br/>      }))<br/>    }))<br/>  }))</pre> | `{}` | no |
| scheduled\_actions | Map of scheduled actions. Each entry supports `min_size`, `max_size`, `desired_capacity`, `start_time`, `end_time`, `recurrence`, and `time_zone`. | <pre>map(object({<br/>    name             = optional(string)<br/>    min_size         = optional(number)<br/>    max_size         = optional(number)<br/>    desired_capacity = optional(number)<br/>    start_time       = optional(string)<br/>    end_time         = optional(string)<br/>    recurrence       = optional(string)<br/>    time_zone        = optional(string)<br/>  }))</pre> | `{}` | no |
| security\_group\_description | Description of the security group | `string` | `"Security group for Auto Scaling Group instances"` | no |
| security\_group\_egress\_rules | Map of egress rules for the security group | <pre>map(object({<br/>    description                  = optional(string)<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    from_port                    = optional(number)<br/>    to_port                      = optional(number)<br/>    ip_protocol                  = optional(string, "-1")<br/>    referenced_security_group_id = optional(string)<br/>    prefix_list_id               = optional(string)<br/>  }))</pre> | <pre>{<br/>  "all": {<br/>    "cidr_ipv4": "0.0.0.0/0",<br/>    "description": "Allow all outbound traffic",<br/>    "ip_protocol": "-1"<br/>  }<br/>}</pre> | no |
| security\_group\_ids | List of additional security group IDs to associate with instances | `list(string)` | `[]` | no |
| security\_group\_ingress\_rules | Map of ingress rules for the security group | <pre>map(object({<br/>    description                  = optional(string)<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    from_port                    = optional(number)<br/>    to_port                      = optional(number)<br/>    ip_protocol                  = optional(string, "tcp")<br/>    referenced_security_group_id = optional(string)<br/>    prefix_list_id               = optional(string)<br/>  }))</pre> | `{}` | no |
| security\_group\_name | Name of the security group. Defaults to the ASG name. | `string` | `null` | no |
| service\_linked\_role\_arn | ARN of the service-linked role for the ASG | `string` | `null` | no |
| spot\_allocation\_strategy | Strategy for allocating Spot instances. Valid values: `lowest-price`, `capacity-optimized`, `capacity-optimized-prioritized`, `price-capacity-optimized`. | `string` | `"price-capacity-optimized"` | no |
| spot\_instance\_pools | Number of Spot pools per availability zone. Only relevant with `lowest-price` strategy. | `number` | `null` | no |
| spot\_max\_price | Maximum price per unit hour to pay for Spot instances | `string` | `null` | no |
| suspended\_processes | List of processes to suspend for the ASG | `list(string)` | `[]` | no |
| tag\_specifications | Additional tag specifications for resources created by the launch template (e.g., `instance`, `volume`) | <pre>list(object({<br/>    resource_type = string<br/>    tags          = optional(map(string), {})<br/>  }))</pre> | `[]` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| target\_group\_arns | List of target group ARNs to attach to the ASG (convenience alias for ALB/NLB) | `list(string)` | `[]` | no |
| termination\_policies | List of policies to decide how instances are terminated | `list(string)` | `[]` | no |
| traffic\_source\_attachments | Map of traffic source attachments (ALB/NLB target group ARNs). Each entry requires `traffic_source_identifier` and optionally `traffic_source_type`. | <pre>map(object({<br/>    traffic_source_identifier = string<br/>    traffic_source_type       = optional(string, "elbv2")<br/>  }))</pre> | `{}` | no |
| use\_mixed\_instances\_policy | Whether to use a mixed instances policy | `bool` | `false` | no |
| user\_data | Base64-encoded user data to provide when launching instances | `string` | `null` | no |
| vpc\_id | VPC ID for the security group. Required if `create_security_group` is true. | `string` | `null` | no |
| vpc\_zone\_identifier | List of subnet IDs for the ASG to launch instances in | `list(string)` | `[]` | no |
| wait\_for\_capacity\_timeout | Maximum duration to wait for ASG instances to be healthy | `string` | `"10m"` | no |
| warm\_pool | Warm pool configuration. Set to `{}` to enable with defaults. Supports `pool_state`, `min_size`, `max_group_prepared_capacity`, and `instance_reuse_policy`. | <pre>object({<br/>    pool_state                  = optional(string, "Stopped")<br/>    min_size                    = optional(number, 0)<br/>    max_group_prepared_capacity = optional(number)<br/>    instance_reuse_policy = optional(object({<br/>      reuse_on_scale_in = optional(bool, false)<br/>    }))<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| autoscaling\_group\_arn | The ARN of the Auto Scaling Group |
| autoscaling\_group\_availability\_zones | The availability zones of the Auto Scaling Group |
| autoscaling\_group\_desired\_capacity | The desired capacity of the Auto Scaling Group |
| autoscaling\_group\_health\_check\_type | The health check type of the Auto Scaling Group |
| autoscaling\_group\_id | The ID of the Auto Scaling Group |
| autoscaling\_group\_max\_size | The maximum size of the Auto Scaling Group |
| autoscaling\_group\_min\_size | The minimum size of the Auto Scaling Group |
| autoscaling\_group\_name | The name of the Auto Scaling Group |
| autoscaling\_group\_vpc\_zone\_identifier | The VPC zone identifier (subnets) of the Auto Scaling Group |
| iam\_instance\_profile\_arn | The ARN of the IAM instance profile |
| iam\_instance\_profile\_id | The ID of the IAM instance profile |
| iam\_instance\_profile\_name | The name of the IAM instance profile |
| iam\_role\_arn | The ARN of the IAM role |
| iam\_role\_name | The name of the IAM role |
| launch\_template\_arn | The ARN of the launch template |
| launch\_template\_default\_version | The default version of the launch template |
| launch\_template\_id | The ID of the launch template |
| launch\_template\_latest\_version | The latest version of the launch template |
| launch\_template\_name | The name of the launch template |
| scaling\_policy\_arns | Map of scaling policy ARNs |
| scaling\_policy\_names | Map of scaling policy names |
| scheduled\_action\_arns | Map of scheduled action ARNs |
| security\_group\_arn | The ARN of the security group |
| security\_group\_id | The ID of the security group |
| security\_group\_name | The name of the security group |
| security\_group\_vpc\_id | The VPC ID of the security group |
<!-- END_TF_DOCS -->

## Examples

### Basic with Launch Template

A simple ASG with a launch template, detailed monitoring, and IMDSv2 enforced.

```hcl
module "asg" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//autoscaling?depth=1&ref=master"

  name = "web-server"

  image_id      = "ami-0abcdef1234567890"
  instance_type = "t3.medium"
  key_name      = "my-key-pair"

  min_size            = 1
  max_size            = 3
  desired_capacity    = 2
  vpc_zone_identifier = ["subnet-abc123", "subnet-def456"]

  health_check_type         = "ELB"
  health_check_grace_period = 300
  target_group_arns         = ["arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/my-tg/1234567890"]

  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size = 50
        volume_type = "gp3"
        encrypted   = true
      }
    }
  ]

  tags = {
    Environment = "production"
    Service     = "web"
  }
}
```

### Mixed Instances (Spot + On-Demand)

An ASG using a mixed instances policy with spot and on-demand instances for cost optimization.

```hcl
module "asg_mixed" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//autoscaling?depth=1&ref=master"

  name = "worker-fleet"

  image_id = "ami-0abcdef1234567890"

  use_mixed_instances_policy = true

  mixed_instances_override = [
    { instance_type = "c5.large", weighted_capacity = "1" },
    { instance_type = "c5a.large", weighted_capacity = "1" },
    { instance_type = "c5d.large", weighted_capacity = "1" },
    { instance_type = "c6i.large", weighted_capacity = "1" },
  ]

  on_demand_base_capacity                  = 1
  on_demand_percentage_above_base_capacity = 25
  spot_allocation_strategy                 = "price-capacity-optimized"
  capacity_rebalance                       = true

  min_size            = 2
  max_size            = 20
  desired_capacity    = 4
  vpc_zone_identifier = ["subnet-abc123", "subnet-def456", "subnet-ghi789"]

  tags = {
    Environment = "production"
    Service     = "workers"
  }
}
```

### With Target Tracking Scaling

An ASG with target tracking scaling policies for CPU utilization and ALB request count.

```hcl
module "asg_scaling" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//autoscaling?depth=1&ref=master"

  name = "api-server"

  image_id      = "ami-0abcdef1234567890"
  instance_type = "t3.large"

  min_size            = 2
  max_size            = 10
  vpc_zone_identifier = ["subnet-abc123", "subnet-def456"]
  target_group_arns   = ["arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/api-tg/1234567890"]

  scaling_policies = {
    cpu = {
      policy_type = "TargetTrackingScaling"
      target_tracking_configuration = {
        target_value = 60.0
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
      }
    }
    request_count = {
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = 120
      target_tracking_configuration = {
        target_value = 1000.0
        predefined_metric_specification = {
          predefined_metric_type = "ALBRequestCountPerTarget"
          resource_label         = "app/my-alb/1234567890/targetgroup/api-tg/1234567890"
        }
      }
    }
  }

  tags = {
    Environment = "production"
    Service     = "api"
  }
}
```

### With Scheduled Actions

An ASG that scales up during business hours and scales down at night.

```hcl
module "asg_scheduled" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//autoscaling?depth=1&ref=master"

  name = "batch-processor"

  image_id      = "ami-0abcdef1234567890"
  instance_type = "c5.xlarge"

  min_size            = 1
  max_size            = 20
  desired_capacity    = 1
  vpc_zone_identifier = ["subnet-abc123", "subnet-def456"]

  scheduled_actions = {
    scale_up_morning = {
      min_size         = 5
      max_size         = 20
      desired_capacity = 10
      recurrence       = "0 8 * * MON-FRI"
      time_zone        = "America/New_York"
    }
    scale_down_evening = {
      min_size         = 1
      max_size         = 5
      desired_capacity = 1
      recurrence       = "0 20 * * MON-FRI"
      time_zone        = "America/New_York"
    }
    scale_down_weekend = {
      min_size         = 0
      max_size         = 1
      desired_capacity = 0
      recurrence       = "0 20 * * FRI"
      time_zone        = "America/New_York"
    }
  }

  tags = {
    Environment = "production"
    Service     = "batch"
  }
}
```

### With Warm Pool

An ASG with a warm pool for faster scale-out by keeping pre-initialized stopped instances.

```hcl
module "asg_warm_pool" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//autoscaling?depth=1&ref=master"

  name = "latency-sensitive-app"

  image_id      = "ami-0abcdef1234567890"
  instance_type = "r5.large"

  min_size            = 2
  max_size            = 10
  desired_capacity    = 2
  vpc_zone_identifier = ["subnet-abc123", "subnet-def456"]

  warm_pool = {
    pool_state                  = "Stopped"
    min_size                    = 2
    max_group_prepared_capacity = 5
    instance_reuse_policy = {
      reuse_on_scale_in = true
    }
  }

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 90
      instance_warmup        = 300
    }
  }

  tags = {
    Environment = "production"
    Service     = "latency-app"
  }
}
```

### With Lifecycle Hooks

An ASG with lifecycle hooks for custom instance initialization and cleanup.

```hcl
module "asg_lifecycle" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//autoscaling?depth=1&ref=master"

  name = "stateful-app"

  image_id      = "ami-0abcdef1234567890"
  instance_type = "m5.large"

  min_size            = 2
  max_size            = 8
  desired_capacity    = 4
  vpc_zone_identifier = ["subnet-abc123", "subnet-def456"]

  create_iam_instance_profile = true

  iam_role_policy_arns = {
    ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  lifecycle_hooks = {
    launch_hook = {
      lifecycle_transition    = "autoscaling:EC2_INSTANCE_LAUNCHING"
      default_result          = "ABANDON"
      heartbeat_timeout       = 600
      notification_target_arn = "arn:aws:sns:us-east-1:123456789012:instance-launching"
      notification_metadata   = jsonencode({ action = "configure" })
    }
    terminate_hook = {
      lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
      default_result          = "CONTINUE"
      heartbeat_timeout       = 300
      notification_target_arn = "arn:aws:sns:us-east-1:123456789012:instance-terminating"
      notification_metadata   = jsonencode({ action = "drain" })
    }
  }

  notification_configurations = {
    ops = {
      topic_arn = "arn:aws:sns:us-east-1:123456789012:asg-notifications"
      notifications = [
        "autoscaling:EC2_INSTANCE_LAUNCH",
        "autoscaling:EC2_INSTANCE_TERMINATE",
        "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
        "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
      ]
    }
  }

  tags = {
    Environment = "production"
    Service     = "stateful-app"
  }
}
```
