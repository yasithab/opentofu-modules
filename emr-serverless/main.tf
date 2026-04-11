locals {
  enabled = var.enabled
  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# EMR Serverless Application
################################################################################

resource "aws_emrserverless_application" "this" {
  name          = var.name
  release_label = var.release_label
  type          = var.application_type

  architecture = var.architecture

  dynamic "auto_start_configuration" {
    for_each = var.auto_start_enabled != null ? [1] : []

    content {
      enabled = var.auto_start_enabled
    }
  }

  dynamic "auto_stop_configuration" {
    for_each = var.auto_stop_enabled != null ? [1] : []

    content {
      enabled              = var.auto_stop_enabled
      idle_timeout_minutes = var.auto_stop_idle_timeout_minutes
    }
  }

  dynamic "initial_capacity" {
    for_each = var.initial_capacity

    content {
      initial_capacity_type = initial_capacity.key

      initial_capacity_config {
        worker_count = initial_capacity.value.worker_count

        dynamic "worker_configuration" {
          for_each = try([initial_capacity.value.worker_configuration], [])

          content {
            cpu    = worker_configuration.value.cpu
            memory = worker_configuration.value.memory
            disk   = try(worker_configuration.value.disk, null)
          }
        }
      }
    }
  }

  dynamic "maximum_capacity" {
    for_each = var.maximum_capacity != null ? [var.maximum_capacity] : []

    content {
      cpu    = maximum_capacity.value.cpu
      memory = maximum_capacity.value.memory
      disk   = try(maximum_capacity.value.disk, null)
    }
  }

  dynamic "network_configuration" {
    for_each = length(var.subnet_ids) > 0 || length(var.security_group_ids) > 0 ? [1] : []

    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  dynamic "image_configuration" {
    for_each = var.image_uri != null ? [1] : []

    content {
      image_uri = var.image_uri
    }
  }

  dynamic "interactive_configuration" {
    for_each = var.interactive_enabled != null ? [1] : []

    content {
      studio_enabled        = var.interactive_enabled
      livy_endpoint_enabled = try(var.livy_endpoint_enabled, false)
    }
  }

  tags = merge(local.tags, { Name = var.name })

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# IAM Execution Role
################################################################################

resource "aws_iam_role" "execution" {
  name               = "${var.name}-execution-role"
  description        = "Execution role for EMR Serverless application ${var.name}"
  assume_role_policy = data.aws_iam_policy_document.execution_assume_role.json

  tags = merge(local.tags, { Name = "${var.name}-execution-role" })

  lifecycle {
    enabled = local.enabled && var.create_execution_role
  }
}

data "aws_iam_policy_document" "execution_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["emr-serverless.amazonaws.com"]
    }

    dynamic "condition" {
      for_each = var.execution_role_source_account_id != null ? [1] : []

      content {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [var.execution_role_source_account_id]
      }
    }
  }
}

resource "aws_iam_role_policy" "execution_s3" {
  name   = "${var.name}-s3-access"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.execution_s3.json

  lifecycle {
    enabled = local.enabled && var.create_execution_role && length(var.execution_role_s3_bucket_arns) > 0
  }
}

data "aws_iam_policy_document" "execution_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = concat(
      var.execution_role_s3_bucket_arns,
      [for arn in var.execution_role_s3_bucket_arns : "${arn}/*"]
    )
  }
}

resource "aws_iam_role_policy" "execution_glue" {
  name   = "${var.name}-glue-access"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.execution_glue.json

  lifecycle {
    enabled = local.enabled && var.create_execution_role && var.execution_role_glue_access_enabled
  }
}

data "aws_iam_policy_document" "execution_glue" {
  statement {
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:CreateTable",
      "glue:UpdateTable",
      "glue:DeleteTable",
      "glue:BatchCreatePartition",
      "glue:BatchDeletePartition"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "execution_additional" {
  for_each = local.enabled && var.create_execution_role ? toset(var.execution_role_additional_policy_arns) : toset([])

  role       = aws_iam_role.execution.name
  policy_arn = each.value
}
