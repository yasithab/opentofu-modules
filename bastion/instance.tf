################################################################################
# AMI - Latest Amazon Linux 2023
################################################################################

data "aws_ssm_parameter" "ami" {
  count = local.enabled && local.is_instance ? 1 : 0

  name = local.ami_ssm_path
}

################################################################################
# Instance
################################################################################

resource "aws_instance" "this" {
  ami           = nonsensitive(data.aws_ssm_parameter.ami[0].value)
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  key_name      = var.key_name

  vpc_security_group_ids      = local.security_group_ids
  associate_public_ip_address = var.public
  iam_instance_profile        = aws_iam_instance_profile.this.name
  monitoring                  = var.monitoring
  disable_api_termination     = true
  user_data_base64            = local.has_instance_udata ? data.cloudinit_config.instance[0].rendered : null

  maintenance_options {
    auto_recovery = "default"
  }

  root_block_device {
    volume_size           = var.ebs_root_volume_size
    volume_type           = "gp3"
    encrypted             = var.ebs_encrypted
    kms_key_id            = var.kms_key_id
    delete_on_termination = true

    tags = merge(local.tags, { "Name" = local.bastion_id })
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(local.tags, {
    "Name"       = local.bastion_id
    "PatchGroup" = local.bastion_id
  })

  lifecycle {
    enabled = local.enabled && local.is_instance
    ignore_changes = [
      ami
    ]
  }
}

################################################################################
# SSM Patch Baseline
################################################################################

resource "aws_ssm_patch_baseline" "this" {
  name             = "${local.bastion_id}-patch-baseline"
  operating_system = "AMAZON_LINUX_2023"

  approval_rule {
    approve_after_days = var.patch_baseline_approval_days

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Security", "Bugfix"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["Critical", "Important"]
    }

    compliance_level = "HIGH"
  }

  approval_rule {
    approve_after_days = var.patch_baseline_approval_days

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Enhancement", "Recommended"]
    }

    compliance_level = "MEDIUM"
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled && local.is_instance
  }
}

resource "aws_ssm_patch_group" "this" {
  baseline_id = aws_ssm_patch_baseline.this.id
  patch_group = local.bastion_id

  lifecycle {
    enabled = local.enabled && local.is_instance
  }
}

################################################################################
# SSM Maintenance Window
################################################################################

resource "aws_ssm_maintenance_window" "this" {
  name     = "${local.bastion_id}-patch-window"
  schedule = var.patch_schedule
  duration = var.maintenance_window_duration
  cutoff   = var.maintenance_window_cutoff

  allow_unassociated_targets = false

  tags = local.tags

  lifecycle {
    enabled = local.enabled && local.is_instance
  }
}

resource "aws_ssm_maintenance_window_target" "this" {
  window_id     = aws_ssm_maintenance_window.this.id
  name          = "${local.bastion_id}-target"
  resource_type = "INSTANCE"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.this.id]
  }

  lifecycle {
    enabled = local.enabled && local.is_instance
  }
}

resource "aws_ssm_maintenance_window_task" "patch" {
  window_id       = aws_ssm_maintenance_window.this.id
  task_type       = "RUN_COMMAND"
  task_arn        = "AWS-RunPatchBaseline"
  priority        = 1
  max_concurrency = "1"
  max_errors      = "0"

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.this.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      timeout_seconds = 3600

      parameter {
        name   = "Operation"
        values = [var.patch_operation]
      }

      parameter {
        name   = "RebootOption"
        values = [var.reboot_option]
      }
    }
  }

  lifecycle {
    enabled = local.enabled && local.is_instance
  }
}

################################################################################
# Auto-Recovery Alarm
################################################################################

resource "aws_cloudwatch_metric_alarm" "auto_recovery" {
  alarm_name          = "${local.bastion_id}-auto-recovery"
  alarm_description   = "Auto-recover bastion on system status check failure"
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed_System"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0

  dimensions = {
    InstanceId = aws_instance.this.id
  }

  alarm_actions = [
    "arn:${data.aws_partition.current.partition}:automate:${data.aws_region.current.region}:ec2:recover"
  ]

  tags = local.tags

  lifecycle {
    enabled = local.enabled && local.is_instance
  }
}

################################################################################
# SSM Agent Auto-Update
################################################################################

resource "aws_ssm_association" "update_ssm_agent" {
  name                = "AWS-UpdateSSMAgent"
  association_name    = "${local.bastion_id}-update-ssm-agent"
  schedule_expression = "rate(7 days)"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.this.id]
  }

  lifecycle {
    enabled = local.enabled && local.is_instance
  }
}
