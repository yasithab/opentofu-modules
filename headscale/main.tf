data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  create = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  # Detect ARM architecture from instance type (t4g, c6g, c7g, m6g, r6g, etc.)
  is_arm = can(regex("[a-zA-Z]+\\d+g[a-z]*\\..+", var.instance_type))

  use_letsencrypt = var.acm_certificate_arn == "" && var.letsencrypt_email != ""
  use_data_volume = var.ebs_data_volume_size > 0
  data_dir        = local.use_data_volume ? "/opt/headscale" : "/var/lib/headscale"

  # Secrets Manager
  has_sm_secrets = var.secrets_manager_arn != ""

  # EIP: use existing allocation, or the one we create, or none
  has_eip           = var.create_eip || var.eip_allocation_id != ""
  eip_allocation_id = var.eip_allocation_id != "" ? var.eip_allocation_id : try(aws_eip.this.id, "")

  # Resolved EIP public IP (works for both created and existing EIPs)
  eip_public_ip = try(aws_eip.this.public_ip, try(data.aws_eip.existing[0].public_ip, null))

  # DNS: for ASG-based deployment, we must use EIP (no static instance IP)
  dns_ip = var.route53_private_zone ? null : local.eip_public_ip
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
  description = "Headscale coordination server"
  vpc_id      = var.vpc_id

  # HTTPS / gRPC (Tailscale clients connect here)
  ingress {
    description = "HTTPS and gRPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Let's Encrypt HTTP-01 challenge (only when using built-in ACME)
  dynamic "ingress" {
    for_each = local.use_letsencrypt ? [1] : []

    content {
      description = "HTTP for Lets Encrypt ACME challenge"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # DERP STUN (UDP - NAT traversal relay)
  dynamic "ingress" {
    for_each = var.derp_enabled ? [1] : []

    content {
      description = "DERP STUN"
      from_port   = var.derp_stun_port
      to_port     = var.derp_stun_port
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # trivy:ignore:AVD-AWS-0104 - Headscale needs outbound for DERP relay traffic and package updates
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
      name                     = var.name
      headscale_version        = var.headscale_version
      is_arm                   = local.is_arm
      server_url               = var.server_url
      base_domain              = var.base_domain
      ip_prefixes              = join(",", var.ip_prefixes)
      data_dir                 = local.data_dir
      use_data_volume          = local.use_data_volume
      data_volume_id           = local.use_data_volume ? aws_ebs_volume.data.id : ""
      derp_enabled             = var.derp_enabled
      derp_stun_port           = var.derp_stun_port
      use_letsencrypt          = local.use_letsencrypt
      letsencrypt_email        = var.letsencrypt_email
      oidc_issuer              = try(var.oidc.issuer, "")
      oidc_client_id           = try(var.oidc.client_id, "")
      oidc_client_secret       = try(var.oidc.client_secret, "")
      oidc_allowed_users       = try(join(",", var.oidc.allowed_users), "")
      oidc_expiry              = try(var.oidc.expiry, "24h")
      secrets_manager_arn      = var.secrets_manager_arn
      secrets_manager_oidc_key = var.secrets_manager_oidc_key
      aws_region               = data.aws_region.current.id
      acl_policy               = var.acl_policy
      eip_allocation_id        = local.has_eip ? local.eip_allocation_id : ""
      subnet_router_enabled    = var.subnet_router_enabled
      advertise_routes         = join(",", var.subnet_router_advertise_routes)
      subnet_router_user       = var.subnet_router_user
      tailscale_version        = var.tailscale_version
      exit_node_enabled        = var.exit_node_enabled
      cloudwatch_logs_enabled  = var.cloudwatch_logs_enabled
      cloudwatch_log_group     = var.cloudwatch_logs_enabled ? "/headscale/${var.name}" : ""
      metrics_port             = var.metrics_port
      publish_auth_key         = var.publish_auth_key
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
# EBS Data Volume (persistent  - survives instance replacements)
################################################################################

data "aws_subnet" "this" {
  count = local.create && local.use_data_volume ? 1 : 0
  id    = var.subnet_id
}

resource "aws_ebs_volume" "data" {
  availability_zone = data.aws_subnet.this[0].availability_zone
  size              = var.ebs_data_volume_size
  type              = "gp3"
  encrypted         = var.encryption
  kms_key_id        = var.kms_key_id

  tags = merge(local.tags, {
    "Name" = "${var.name}-data"
  })

  lifecycle {
    enabled = local.create && local.use_data_volume
  }
}

################################################################################
# EBS Snapshots (daily via Data Lifecycle Manager)
################################################################################

data "aws_iam_policy_document" "dlm_assume_role" {
  statement {
    sid     = "DLMAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "dlm" {
  name_prefix        = "${var.name}-dlm-"
  assume_role_policy = data.aws_iam_policy_document.dlm_assume_role.json

  tags = local.tags

  lifecycle {
    enabled = local.create && local.use_data_volume && var.snapshot_enabled
  }
}

resource "aws_iam_role_policy_attachment" "dlm" {
  role       = aws_iam_role.dlm.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"

  lifecycle {
    enabled = local.create && local.use_data_volume && var.snapshot_enabled
  }
}

resource "aws_dlm_lifecycle_policy" "data_volume" {
  description        = "Daily snapshot of ${var.name} data volume"
  execution_role_arn = aws_iam_role.dlm.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    target_tags = {
      "Name" = "${var.name}-data"
    }

    schedule {
      name = "Daily snapshot"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = [var.snapshot_time]
      }

      retain_rule {
        count = var.snapshot_retention_days
      }

      tags_to_add = merge(local.tags, {
        "Name"      = "${var.name}-data-snapshot"
        "Automated" = "dlm"
      })

      copy_tags = true
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.create && local.use_data_volume && var.snapshot_enabled
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
    description                 = "${var.name} ENI"
    subnet_id                   = var.subnet_id
    associate_public_ip_address = var.associate_public_ip_address
    security_groups             = concat([aws_security_group.this.id], var.additional_security_group_ids)
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
      condition     = !var.subnet_router_enabled || length(var.subnet_router_advertise_routes) > 0 || var.exit_node_enabled
      error_message = "subnet_router_advertise_routes must not be empty when subnet_router_enabled is true (unless exit_node_enabled is true)."
    }
    precondition {
      condition     = var.oidc == null || try(var.oidc.client_secret, "") != "" || var.secrets_manager_arn != ""
      error_message = "OIDC requires either oidc.client_secret or secrets_manager_arn."
    }
  }
}

################################################################################
# Auto Scaling Group (self-healing  - replaces failed instances automatically)
################################################################################

resource "aws_autoscaling_group" "this" {
  name_prefix               = "${var.name}-"
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  health_check_type         = "EC2"
  health_check_grace_period = 300
  default_instance_warmup   = 300
  vpc_zone_identifier       = [var.subnet_id]

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  # Name tag  - propagated to instances
  dynamic "tag" {
    for_each = merge(local.tags, { "Name" = var.name })

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false # launch template tag_specifications handles it
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

# trivy:ignore:AVD-AWS-0057 - SSM Session Manager and EC2 self-service actions require wildcard resources
data "aws_iam_policy_document" "this" {
  # SSM Session Manager
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

  # EC2 Describe actions (required for EIP association and volume attachment, no tag conditions supported)
  dynamic "statement" {
    for_each = local.has_eip || local.use_data_volume ? [1] : []

    content {
      sid    = "EC2Describe"
      effect = "Allow"
      actions = compact([
        local.has_eip ? "ec2:DescribeAddresses" : "",
        local.use_data_volume ? "ec2:DescribeVolumes" : "",
      ])
      resources = ["*"]
    }
  }

  # EIP self-association (instance associates its own EIP at boot)
  dynamic "statement" {
    for_each = local.has_eip ? [1] : []

    content {
      sid       = "AssociateEIP"
      effect    = "Allow"
      actions   = ["ec2:AssociateAddress"]
      resources = ["*"]
    }
  }

  # Disable source/dest check for subnet router mode
  dynamic "statement" {
    for_each = var.subnet_router_enabled ? [1] : []

    content {
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
  }

  # EBS data volume self-attachment (instance attaches its data volume at boot)
  dynamic "statement" {
    for_each = local.use_data_volume ? [1] : []

    content {
      sid       = "AttachDataVolume"
      effect    = "Allow"
      actions   = ["ec2:AttachVolume"]
      resources = ["*"]

      condition {
        test     = "StringEquals"
        variable = "ec2:ResourceTag/Name"
        values   = [var.name, "${var.name}-data"]
      }
    }
  }

  # Secrets Manager
  dynamic "statement" {
    for_each = local.has_sm_secrets ? [1] : []

    content {
      sid    = "SecretsManagerAccess"
      effect = "Allow"
      actions = compact([
        "secretsmanager:GetSecretValue",
        var.publish_auth_key ? "secretsmanager:PutSecretValue" : "",
      ])
      resources = [var.secrets_manager_arn]
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
# Elastic IP
################################################################################

data "aws_eip" "existing" {
  count = local.create && var.eip_allocation_id != "" ? 1 : 0
  id    = var.eip_allocation_id
}

resource "aws_eip" "this" {
  domain = "vpc"

  tags = merge(local.tags, {
    "Name" = var.name
  })

  lifecycle {
    enabled = local.create && var.create_eip && var.eip_allocation_id == ""
  }
}

# Note: EIP association is done by the instance itself at boot via user_data
# (not via aws_eip_association) so that ASG replacements can self-associate.

################################################################################
# Route53 DNS Record
################################################################################

resource "aws_route53_record" "this" {
  zone_id = var.route53_zone_id
  name    = var.route53_record_name
  type    = "A"
  ttl     = var.route53_record_ttl
  records = [local.dns_ip]

  lifecycle {
    enabled = local.create && var.route53_zone_id != "" && local.has_eip
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
  alarm_description   = "Headscale instance is unhealthy - ASG has 0 in-service instances"
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

