data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  create = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  is_arm         = can(regex("[a-zA-Z]+\\d+g[a-z]*\\..+", var.instance_type))
  hostname       = var.hostname != "" ? var.hostname : var.name
  has_sm_secrets = var.secrets_manager_arn != ""
}

################################################################################
# AMI - Amazon Linux 2023
################################################################################

data "aws_ssm_parameter" "ami" {
  count = local.create && var.ami_id == null ? 1 : 0
  name  = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-${local.is_arm ? "arm64" : "x86_64"}"
}

locals {
  ami_id = var.ami_id != null ? var.ami_id : try(data.aws_ssm_parameter.ami[0].value, null)
}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "this" {
  name_prefix = "${var.name}-"
  description = "Tailscale subnet router - egress only"
  vpc_id      = var.vpc_id

  # trivy:ignore:AVD-AWS-0104 - Subnet router needs outbound for WireGuard tunnels and VPC resource access
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    "Name" = var.name
  })

  lifecycle {
    enabled               = local.create
    create_before_destroy = true
  }
}

################################################################################
# User Data
################################################################################

data "cloudinit_config" "this" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/user_data.sh", {
      is_arm                         = local.is_arm
      tailscale_version              = var.tailscale_version
      headscale_url                  = var.headscale_server_url
      auth_key                       = var.headscale_auth_key
      secrets_manager_arn            = var.secrets_manager_arn
      secrets_manager_auth_key_field = var.secrets_manager_auth_key_field
      advertise_routes               = join(",", var.advertise_routes)
      hostname                       = local.hostname
      accept_dns                     = var.accept_dns
      aws_region                     = data.aws_region.current.id
      exit_node_enabled              = var.exit_node_enabled
      cloudwatch_logs_enabled        = var.cloudwatch_logs_enabled
      cloudwatch_log_group           = var.cloudwatch_logs_enabled ? "/headscale/${var.name}" : ""
    })
  }

  dynamic "part" {
    for_each = var.cloud_init_parts

    content {
      content_type = part.value["content_type"]
      content      = part.value["content"]
    }
  }
}

################################################################################
# Launch Template
################################################################################

# trivy:ignore:AVD-AWS-0131 - EBS encryption is caller-controlled via var.encryption; defaults to true
resource "aws_launch_template" "this" {
  name_prefix   = "${var.name}-"
  image_id      = local.ami_id
  instance_type = var.instance_type
  user_data     = data.cloudinit_config.this.rendered

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  network_interfaces {
    description     = "${var.name} ENI"
    subnet_id       = var.subnet_id
    security_groups = concat([aws_security_group.this.id], var.additional_security_group_ids)
  }

  dynamic "instance_market_options" {
    for_each = var.use_spot_instances ? [1] : []

    content {
      market_type = "spot"
    }
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.ebs_root_volume_size
      volume_type = "gp3"
      encrypted   = var.encryption
      kms_key_id  = var.kms_key_id
    }
  }

  dynamic "tag_specifications" {
    for_each = ["instance", "network-interface", "volume"]

    content {
      resource_type = tag_specifications.value
      tags = merge(local.tags, {
        "Name" = var.name
      })
    }
  }

  tags = merge(local.tags, {
    "Name" = var.name
  })

  lifecycle {
    enabled = local.create
    precondition {
      condition     = var.headscale_auth_key != "" || var.secrets_manager_arn != ""
      error_message = "Either headscale_auth_key or secrets_manager_arn must be provided."
    }
  }
}

################################################################################
# Auto Scaling Group (self-healing - replaces failed instances automatically)
################################################################################

resource "aws_autoscaling_group" "this" {
  name_prefix               = "${var.name}-"
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  health_check_type         = "EC2"
  health_check_grace_period = 180
  default_instance_warmup   = 180
  vpc_zone_identifier       = [var.subnet_id]

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(local.tags, { "Name" = var.name })

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
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
    enabled = local.create
  }
}

################################################################################
# IAM Role / Instance Profile
################################################################################

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "EC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name_prefix           = "${var.name}-"
  assume_role_policy    = data.aws_iam_policy_document.assume_role.json
  force_detach_policies = true

  tags = local.tags

  lifecycle {
    enabled = local.create
  }
}

resource "aws_iam_instance_profile" "this" {
  name_prefix = "${var.name}-"
  role        = aws_iam_role.this.name

  tags = local.tags

  lifecycle {
    enabled               = local.create
    create_before_destroy = true
  }
}

# trivy:ignore:AVD-AWS-0057 - SSM Session Manager actions require wildcard resources per AWS documentation
data "aws_iam_policy_document" "this" {
  dynamic "statement" {
    for_each = var.attach_ssm_policy ? [1] : []

    content {
      sid    = "SessionManager"
      effect = "Allow"
      actions = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel",
        "ssm:UpdateInstanceInformation",
      ]
      resources = ["*"]
    }
  }

  # Disable source/dest check at boot (subnet router must forward packets)
  statement {
    sid       = "DisableSourceDestCheck"
    effect    = "Allow"
    actions   = ["ec2:ModifyInstanceAttribute"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Name"
      values   = [var.name]
    }
  }

  dynamic "statement" {
    for_each = local.has_sm_secrets ? [1] : []

    content {
      sid    = "SecretsManagerRead"
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
      ]
      resources = [var.secrets_manager_arn]
    }
  }

  # KMS decrypt (required for cross-account Secrets Manager encrypted with customer managed key)
  dynamic "statement" {
    for_each = local.has_sm_secrets ? [1] : []

    content {
      sid    = "KMSDecrypt"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
      ]
      resources = ["*"]
    }
  }

  # CloudWatch Logs
  dynamic "statement" {
    for_each = var.cloudwatch_logs_enabled ? [1] : []

    content {
      sid    = "CloudWatchLogs"
      effect = "Allow"
      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
      ]
      resources = ["${aws_cloudwatch_log_group.this.arn}:*"]
    }
  }
}

resource "aws_iam_policy" "this" {
  name_prefix = "${var.name}-"
  policy      = data.aws_iam_policy_document.this.json

  tags = local.tags

  lifecycle {
    enabled = local.create
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn

  lifecycle {
    enabled = local.create
  }
}

################################################################################
# CloudWatch Alarm (ASG health)
################################################################################

resource "aws_sns_topic" "alarm" {
  name_prefix = "${var.name}-alarm-"

  tags = local.tags

  lifecycle {
    enabled = local.create && var.alarm_enabled && var.alarm_sns_topic_arn == ""
  }
}

resource "aws_cloudwatch_metric_alarm" "asg_health" {
  alarm_name          = "${var.name}-unhealthy"
  alarm_description   = "Subnet router is unhealthy - ASG has 0 in-service instances"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "GroupInServiceInstances"
  namespace           = "AWS/AutoScaling"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  treat_missing_data  = "breaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }

  alarm_actions = [var.alarm_sns_topic_arn != "" ? var.alarm_sns_topic_arn : aws_sns_topic.alarm.arn]
  ok_actions    = [var.alarm_sns_topic_arn != "" ? var.alarm_sns_topic_arn : aws_sns_topic.alarm.arn]

  tags = local.tags

  lifecycle {
    enabled = local.create && var.alarm_enabled
  }
}

################################################################################
# CloudWatch Logs
################################################################################

resource "aws_cloudwatch_log_group" "this" {
  name              = "/headscale/${var.name}"
  retention_in_days = var.cloudwatch_logs_retention_days

  tags = local.tags

  lifecycle {
    enabled = local.create && var.cloudwatch_logs_enabled
  }
}
