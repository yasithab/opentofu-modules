data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  create = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  # Detect ARM architecture from instance type (t4g, c6g, c6gn, c7g, c7gn, m6g, r6g, etc.)
  is_arm = can(regex("[a-zA-Z]+\\d+g[a-z]*\\..+", var.instance_type))

  eip_id        = length(var.eip_allocation_ids) > 0 ? var.eip_allocation_ids[0] : ""
  instance_name = lookup(var.tags, "Name", var.name)

  security_groups = concat([aws_security_group.this.id], var.additional_security_group_ids)
}

################################################################################
# AMI - fck-nat AL2023
################################################################################

data "aws_ami" "this" {
  count = local.create && var.ami_id == null ? 1 : 0

  most_recent = true
  owners      = ["568608671756"]

  filter {
    name   = "name"
    values = ["fck-nat-al2023-hvm-*"]
  }

  filter {
    name   = "architecture"
    values = [local.is_arm ? "arm64" : "x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  ami_id = var.ami_id != null ? var.ami_id : try(data.aws_ami.this[0].id, null)
}

################################################################################
# Security Group
################################################################################

data "aws_vpc" "this" {
  count = local.create ? 1 : 0
  id    = var.vpc_id
}

resource "aws_security_group" "this" {
  name_prefix = "${var.name}-"
  description = "fck-nat in subnet ${var.subnet_id}"
  vpc_id      = var.vpc_id

  # Ingress - all traffic from VPC CIDRs (including secondary)
  ingress {
    description = "All traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = data.aws_vpc.this[0].cidr_block_associations[*].cidr_block
  }

  # trivy:ignore:AVD-AWS-0104 - NAT instance requires unrestricted egress to forward private subnet traffic to the internet
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
# ENI - static interface (persists across instance replacements)
#
# Route tables point to this ENI. Destroying it kills all private subnet
# outbound traffic until a new ENI is provisioned and routes updated.
################################################################################

resource "aws_network_interface" "this" {
  subnet_id         = var.subnet_id
  security_groups   = local.security_groups
  source_dest_check = false
  description       = "${var.name} static private ENI"

  tags = merge(local.tags, {
    "Name" = var.name
  })

  lifecycle {
    enabled = local.create
  }
}

################################################################################
# Route Table Updates
################################################################################

resource "aws_route" "this" {
  for_each = { for k, v in var.route_tables_ids : k => v if local.create && var.update_route_tables }

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.this.id

  timeouts {
    create = "5m"
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
      eni_id           = aws_network_interface.this.id
      eip_id           = local.eip_id
      conntrack_max    = var.conntrack_max
      local_port_range = var.local_port_range
    })
  }

  dynamic "part" {
    for_each = var.cloud_init_parts

    content {
      content_type = part.value["content_type"]
      content      = part.value["content"]
    }
  }

  lifecycle {
    enabled = local.create
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

  # Ephemeral public ENI in the target subnet. The fck-nat service attaches the
  # static ENI (aws_network_interface.this) on startup via user_data, which is
  # critical for HA mode where the ASG replaces instances.
  network_interfaces {
    description                 = "${var.name} ephemeral public ENI"
    subnet_id                   = var.subnet_id
    associate_public_ip_address = true
    security_groups             = local.security_groups
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

  credit_specification {
    cpu_credits = var.credit_specification
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
  }
}

################################################################################
# EC2 Instance (non-HA mode)
################################################################################

resource "aws_instance" "this" {
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tags = merge(local.tags, {
    "Name" = var.name
  })

  lifecycle {
    enabled = local.create && !var.ha_mode
    ignore_changes = [
      source_dest_check,
      user_data,
      tags,
    ]
  }
}

################################################################################
# Auto Scaling Group (HA mode)
################################################################################

resource "aws_autoscaling_group" "this" {
  name_prefix               = "${var.name}-"
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

  # Name tag - propagated to instances
  dynamic "tag" {
    for_each = lookup(var.tags, "Name", null) == null ? ["Name"] : []

    content {
      key                 = "Name"
      value               = var.name
      propagate_at_launch = true
    }
  }

  # User tags - not propagated (launch template tag_specifications handles it)
  dynamic "tag" {
    for_each = local.tags

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
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
    "GroupInServiceCapacity",
    "GroupPendingCapacity",
    "GroupStandbyCapacity",
    "GroupTerminatingCapacity",
    "GroupTotalCapacity",
  ]

  timeouts {
    delete = "15m"
  }

  lifecycle {
    enabled = local.create && var.ha_mode
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

  lifecycle {
    enabled = local.create
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

data "aws_iam_policy_document" "this" {
  # trivy:ignore:AVD-AWS-0057 - ENI management requires wildcard resources; scoped by ec2:ResourceTag/Name condition
  statement {
    sid    = "ManageNetworkInterface"
    effect = "Allow"
    actions = [
      "ec2:AttachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Name"
      values   = [local.instance_name]
    }
  }

  # EIP association - scoped to the specific allocation (only when EIP is provided)
  dynamic "statement" {
    for_each = length(var.eip_allocation_ids) > 0 ? [1] : []

    content {
      sid    = "ManageEIPAllocation"
      effect = "Allow"
      actions = [
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
      ]
      resources = [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:elastic-ip/${var.eip_allocation_ids[0]}",
      ]
    }
  }

  dynamic "statement" {
    for_each = length(var.eip_allocation_ids) > 0 ? [1] : []

    content {
      sid    = "ManageEIPNetworkInterface"
      effect = "Allow"
      actions = [
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
      ]
      resources = [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*",
      ]

      condition {
        test     = "StringEquals"
        variable = "ec2:ResourceTag/Name"
        values   = [local.instance_name]
      }
    }
  }

  # trivy:ignore:AVD-AWS-0057 - SSM Session Manager actions require wildcard resources per AWS documentation
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

  lifecycle {
    enabled = local.create
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
