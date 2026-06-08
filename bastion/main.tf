data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_subnet" "this" {
  count = local.enabled && local.create_sg ? 1 : 0

  id = var.subnet_id
}

locals {
  enabled     = var.enabled
  name        = var.name
  is_ha       = var.ha_mode
  is_instance = !var.ha_mode

  bastion_id              = local.name != null ? local.name : "bastion"
  ami_ssm_path            = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-${var.cpu_architecture}"
  eip_allocation_id       = var.public ? aws_eip.this.id : ""
  ssh_host_key_ssm_prefix = var.ssh_host_key_ssm_prefix != null ? var.ssh_host_key_ssm_prefix : "/bastion/${local.bastion_id}/ssh-host-keys"

  create_sg          = length(var.vpc_security_group_ids) == 0
  security_group_ids = local.create_sg ? [aws_security_group.this.id] : var.vpc_security_group_ids

  has_tunnel_users   = var.public && length(var.tunnel_users) > 0
  has_instance_udata = local.is_instance && (local.has_tunnel_users || length(var.user_data_parts) > 0)

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
    Role      = "bastion"
  })
}

################################################################################
# User Data
################################################################################

data "cloudinit_config" "ha" {
  count = local.enabled && local.is_ha ? 1 : 0

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/user_data.sh", {
      eip_allocation_id       = local.eip_allocation_id
      persist_ssh_host_keys   = var.persist_ssh_host_keys && var.public
      ssh_host_key_ssm_prefix = local.ssh_host_key_ssm_prefix
      tunnel_users            = var.tunnel_users
    })
  }

  dynamic "part" {
    for_each = var.user_data_parts

    content {
      content_type = part.value["content_type"]
      content      = part.value["content"]
    }
  }
}

data "cloudinit_config" "instance" {
  count = local.enabled && local.is_instance && local.has_instance_udata ? 1 : 0

  gzip          = true
  base64_encode = true

  dynamic "part" {
    for_each = local.has_tunnel_users ? [1] : []

    content {
      content_type = "text/x-shellscript"
      content = templatefile("${path.module}/templates/tunnel_users.sh", {
        tunnel_users = var.tunnel_users
      })
    }
  }

  dynamic "part" {
    for_each = var.user_data_parts

    content {
      content_type = part.value["content_type"]
      content      = part.value["content"]
    }
  }
}

################################################################################
# IAM Role / Instance Profile
################################################################################

data "aws_iam_policy_document" "assume_role" {
  count = local.enabled ? 1 : 0

  statement {
    sid     = "EC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = "${local.bastion_id}-role"
  assume_role_policy   = data.aws_iam_policy_document.assume_role[0].json
  permissions_boundary = var.iam_role_permissions_boundary

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.this.name

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_iam_role_policy_attachment" "ssm_patch" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMPatchAssociation"
  role       = aws_iam_role.this.name

  lifecycle {
    enabled = local.enabled && local.is_instance
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.this.name

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = { for k, v in var.additional_iam_policies : k => v if local.enabled }

  policy_arn = each.value
  role       = aws_iam_role.this.name
}

data "aws_iam_policy_document" "bastion" {
  count = local.enabled ? 1 : 0

  dynamic "statement" {
    for_each = var.public && local.is_ha ? [1] : []

    content {
      sid     = "AssociateEIP"
      effect  = "Allow"
      actions = ["ec2:AssociateAddress"]
      resources = [
        aws_eip.this.arn,
        "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:instance/*",
        "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:network-interface/*",
      ]
    }
  }

  dynamic "statement" {
    for_each = [1]

    content {
      sid    = "SessionLogging"
      effect = "Allow"
      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
      ]
      resources = ["${aws_cloudwatch_log_group.ssm_sessions.arn}:*"]
    }
  }

  dynamic "statement" {
    for_each = var.persist_ssh_host_keys && var.public && local.is_ha ? [1] : []

    content {
      sid    = "SSHHostKeyPersistence"
      effect = "Allow"
      actions = [
        "ssm:GetParameter",
      ]
      resources = [
        "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${local.ssh_host_key_ssm_prefix}",
      ]
    }
  }

  dynamic "statement" {
    for_each = var.persist_ssh_host_keys && var.public && local.is_ha ? [1] : []

    content {
      sid    = "SSHHostKeyDecrypt"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
      ]
      resources = [
        "arn:${data.aws_partition.current.partition}:kms:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:key/*",
      ]

      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["ssm.${data.aws_region.current.region}.amazonaws.com"]
      }
    }
  }

  dynamic "statement" {
    for_each = var.session_log_kms_key_id != null ? [1] : []

    content {
      sid    = "SessionLogEncryption"
      effect = "Allow"
      actions = [
        "kms:GenerateDataKey",
      ]
      resources = [var.session_log_kms_key_id]

      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["logs.${data.aws_region.current.region}.amazonaws.com"]
      }
    }
  }
}

resource "aws_iam_role_policy" "bastion" {
  name   = "${local.bastion_id}-policy"
  role   = aws_iam_role.this.name
  policy = data.aws_iam_policy_document.bastion[0].json

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_iam_instance_profile" "this" {
  name = "${local.bastion_id}-profile"
  role = aws_iam_role.this.name

  tags = local.tags

  lifecycle {
    enabled               = local.enabled
    create_before_destroy = true
  }
}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "this" {
  name_prefix = "${local.bastion_id}-"
  description = "Security group for ${local.bastion_id}"
  vpc_id      = data.aws_subnet.this[0].vpc_id

  tags = merge(local.tags, { "Name" = local.bastion_id })

  lifecycle {
    enabled               = local.enabled && local.create_sg
    create_before_destroy = true
  }
}

# trivy:ignore:AVD-AWS-0104 - Bastion requires unrestricted egress for package updates, SSM agent, and tunnel traffic
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.this.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = local.tags

  lifecycle {
    enabled = local.enabled && local.create_sg
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  for_each = { for idx, cidr in var.allowed_ssh_cidrs : idx => cidr if local.enabled && local.create_sg && var.public }

  security_group_id = aws_security_group.this.id
  description       = "SSH from ${each.value}"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = each.value

  tags = local.tags
}

################################################################################
# Elastic IP (public bastion only)
################################################################################

resource "aws_eip" "this" {
  instance = local.is_instance ? aws_instance.this.id : null
  domain   = "vpc"

  tags = merge(local.tags, var.eip_tags, { "Name" = local.bastion_id })

  lifecycle {
    enabled = local.enabled && var.public
  }
}

################################################################################
# SSM Session Logging
################################################################################

resource "aws_cloudwatch_log_group" "ssm_sessions" {
  name              = "/ssm/sessions/${local.bastion_id}"
  retention_in_days = var.session_log_retention_days
  kms_key_id        = var.session_log_kms_key_id
  log_group_class   = "STANDARD"
  skip_destroy      = false

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_ssm_document" "session_preferences" {
  name            = "SSM-SessionManagerRunShell-${local.bastion_id}"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Session Manager settings for ${local.bastion_id}"
    sessionType   = "Standard_Stream"
    inputs = {
      cloudWatchLogGroupName      = aws_cloudwatch_log_group.ssm_sessions.name
      cloudWatchEncryptionEnabled = var.session_log_kms_key_id != null
      idleSessionTimeout          = tostring(var.session_idle_timeout_minutes)
      runAsEnabled                = false
    }
  })

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# SSH Host Key Persistence (ha_mode + public only)
################################################################################

locals {
  persist_host_keys = local.enabled && var.persist_ssh_host_keys && var.public && local.is_ha
}

resource "tls_private_key" "ssh_host_ed25519" {
  algorithm = "ED25519"

  lifecycle {
    enabled = local.persist_host_keys
  }
}

resource "tls_private_key" "ssh_host_rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096

  lifecycle {
    enabled = local.persist_host_keys
  }
}

resource "tls_private_key" "ssh_host_ecdsa" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"

  lifecycle {
    enabled = local.persist_host_keys
  }
}

resource "aws_ssm_parameter" "ssh_host_keys" {
  name = local.ssh_host_key_ssm_prefix
  type = "SecureString"
  tier = "Advanced"
  value = jsonencode({
    ed25519 = {
      private_key = tls_private_key.ssh_host_ed25519.private_key_openssh
      public_key  = tls_private_key.ssh_host_ed25519.public_key_openssh
    }
    rsa = {
      private_key = tls_private_key.ssh_host_rsa.private_key_openssh
      public_key  = tls_private_key.ssh_host_rsa.public_key_openssh
    }
    ecdsa = {
      private_key = tls_private_key.ssh_host_ecdsa.private_key_openssh
      public_key  = tls_private_key.ssh_host_ecdsa.public_key_openssh
    }
  })

  tags = merge(local.tags, { "Name" = "${local.bastion_id}-ssh-host-keys" })

  lifecycle {
    enabled = local.persist_host_keys
  }
}
