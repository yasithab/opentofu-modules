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
