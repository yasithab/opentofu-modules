locals {
  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  resource_id = coalesce(
    var.vpc_id,
    var.eni_id,
    var.subnet_id,
    var.transit_gateway_id,
    var.transit_gateway_attachment_id,
    var.regional_nat_gateway_id,
    "flow-logs"
  )

  # Conditional IAM role ARN
  iam_role_arn = var.log_destination_type == "cloud-watch-logs" ? (
    coalesce(var.iam_role_arn, try(aws_iam_role.this.arn, null))
  ) : null

  # Log destination resolution
  log_destination = coalesce(
    var.log_destination,
    {
      "cloud-watch-logs"      = try(aws_cloudwatch_log_group.this.arn, null),
      "s3"                    = var.s3_bucket_arn,
      "kinesis-data-firehose" = var.kinesis_firehose_delivery_stream_arn
    }[var.log_destination_type]
  )

  # Conditional resource flags
  create_cw_log_group  = var.enabled && var.log_destination_type == "cloud-watch-logs" && var.log_destination == null
  create_iam_resources = var.enabled && var.log_destination_type == "cloud-watch-logs" && var.iam_role_arn == null
}

################################################################################
# Flow Logs
################################################################################

resource "aws_flow_log" "this" {
  # Resource attachment
  vpc_id                        = var.vpc_id
  eni_id                        = var.eni_id
  subnet_id                     = var.subnet_id
  transit_gateway_id            = var.transit_gateway_id
  transit_gateway_attachment_id = var.transit_gateway_attachment_id
  regional_nat_gateway_id       = var.regional_nat_gateway_id

  # Logging configuration
  log_destination_type       = var.log_destination_type
  log_destination            = local.log_destination
  traffic_type               = var.traffic_type
  deliver_cross_account_role = var.deliver_cross_account_role
  iam_role_arn               = local.iam_role_arn
  max_aggregation_interval   = var.max_aggregation_interval
  log_format                 = var.log_format

  dynamic "destination_options" {
    for_each = var.log_destination_type == "s3" && var.destination_options != null ? [var.destination_options] : []
    content {
      file_format                = destination_options.value.file_format
      hive_compatible_partitions = destination_options.value.hive_compatible_partitions
      per_hour_partition         = destination_options.value.per_hour_partition
    }
  }

  tags = merge(local.tags, { Name = var.name })

  lifecycle {
    enabled = var.enabled
  }
}

################################################################################
# CloudWatch Log Group
################################################################################

resource "aws_cloudwatch_log_group" "this" {
  name              = coalesce(var.cloudwatch_log_group_name, "/aws/vpc-flow-logs/${local.resource_id}")
  retention_in_days = var.cloudwatch_log_retention_in_days
  kms_key_id        = var.cloudwatch_log_kms_key_id
  skip_destroy      = var.cloudwatch_log_group_skip_destroy
  log_group_class   = var.cloudwatch_log_group_class
  tags              = local.tags

  lifecycle {
    enabled = local.create_cw_log_group
  }
}

################################################################################
# IAM Resources
################################################################################

resource "aws_iam_role" "this" {
  name               = coalesce(var.iam_role_name, "vpc-flow-logs-role-${local.resource_id}")
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json
  tags               = local.tags

  lifecycle {
    enabled = local.create_iam_resources
  }
}

data "aws_iam_policy_document" "assume_role" {
  count = local.create_iam_resources ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn

  lifecycle {
    enabled = local.create_iam_resources
  }
}

resource "aws_iam_policy" "this" {
  name        = coalesce(var.iam_policy_name, "vpc-flow-logs-policy-${local.resource_id}")
  description = "IAM policy for VPC Flow Logs to CloudWatch"
  policy      = data.aws_iam_policy_document.this[0].json
  tags        = local.tags

  lifecycle {
    enabled = local.create_iam_resources
  }
}

data "aws_iam_policy_document" "this" {
  count = local.create_iam_resources ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

################################################################################
