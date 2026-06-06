################################################################################
# Launch Template
################################################################################

# trivy:ignore:AVD-AWS-0131 - EBS encryption is caller-controlled via var.ebs_encrypted; defaults to true
resource "aws_launch_template" "this" {
  name_prefix = "${local.bastion_id}-"
  image_id    = "resolve:ssm:${local.ami_ssm_path}"
  key_name    = var.key_name
  user_data   = data.cloudinit_config.ha[0].rendered

  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  network_interfaces {
    description                 = "${local.bastion_id} primary ENI"
    subnet_id                   = var.subnet_id
    associate_public_ip_address = var.public
    security_groups             = local.security_group_ids
  }

  monitoring {
    enabled = var.monitoring
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.ebs_root_volume_size
      volume_type = "gp3"
      encrypted   = var.ebs_encrypted
      kms_key_id  = var.kms_key_id
    }
  }

  dynamic "tag_specifications" {
    for_each = ["instance", "volume", "network-interface"]

    content {
      resource_type = tag_specifications.value
      tags = merge(local.tags, {
        "Name" = local.bastion_id
      })
    }
  }

  tags = merge(local.tags, {
    "Name" = local.bastion_id
  })

  lifecycle {
    enabled = local.enabled && local.is_ha
  }
}

################################################################################
# Auto Scaling Group
################################################################################

resource "aws_autoscaling_group" "this" {
  name_prefix               = "${local.bastion_id}-"
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  health_check_type         = "EC2"
  health_check_grace_period = 120
  default_instance_warmup   = 120
  vpc_zone_identifier       = [var.subnet_id]

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(local.tags, { "Name" = local.bastion_id })

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances",
  ]

  timeouts {
    delete = "15m"
  }

  lifecycle {
    enabled = local.enabled && local.is_ha
  }
}

################################################################################
# Scheduled Replacement (weekly AMI refresh)
################################################################################

resource "aws_autoscaling_schedule" "scale_down" {
  scheduled_action_name  = "${local.bastion_id}-weekly-scale-down"
  autoscaling_group_name = aws_autoscaling_group.this.name
  recurrence             = var.replacement_scale_down_schedule
  min_size               = 0
  max_size               = 1
  desired_capacity       = 0
  time_zone              = "UTC"

  lifecycle {
    enabled = local.enabled && local.is_ha
  }
}

resource "aws_autoscaling_schedule" "scale_up" {
  scheduled_action_name  = "${local.bastion_id}-weekly-scale-up"
  autoscaling_group_name = aws_autoscaling_group.this.name
  recurrence             = var.replacement_scale_up_schedule
  min_size               = 1
  max_size               = 1
  desired_capacity       = 1
  time_zone              = "UTC"

  lifecycle {
    enabled = local.enabled && local.is_ha
  }
}
