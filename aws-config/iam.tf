locals {
  create_iam_role = local.create && var.create_iam_role
  iam_role_name   = coalesce(var.iam_role_name, "${local.recorder_name}-config-role")

  # A dedicated org aggregator role is needed for organization_aggregation_source.
  # AWSConfigRole does not include organizations:* permissions - those require
  # AWSConfigRoleForOrganizations, attached to a separate role created below.
  create_org_aggregator_role = (
    local.create_iam_role
    && var.aggregator_organization != null
    && var.aggregator_organization.role_arn == null
  )

  # S3 path prefix for the delivery IAM policy. Includes the trailing slash so the
  # wildcard path is correct whether or not a key prefix is configured.
  s3_delivery_prefix = var.delivery_channel_s3_key_prefix != null ? "${var.delivery_channel_s3_key_prefix}/" : ""
}

# -- Config Recorder IAM Role -------------------------------------------------

data "aws_iam_policy_document" "config_assume" {
  count = local.create_iam_role ? 1 : 0

  statement {
    sid     = "ConfigAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "config" {
  count = local.create_iam_role ? 1 : 0

  name               = local.iam_role_name
  assume_role_policy = data.aws_iam_policy_document.config_assume[0].json
  tags               = local.tags
}

# AWSConfigRole covers Config API calls, broad S3 write, and SNS publish.
resource "aws_iam_role_policy_attachment" "config" {
  count = local.create_iam_role ? 1 : 0

  role       = aws_iam_role.config[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

# Scoped S3 delivery policy - supplements AWSConfigRole with a least-privilege
# statement targeting only the caller-supplied bucket and optional KMS key.
data "aws_iam_policy_document" "config_s3" {
  count = local.create_iam_role && var.delivery_channel_s3_bucket_name != null ? 1 : 0

  statement {
    sid     = "ConfigS3PutObject"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "arn:aws:s3:::${var.delivery_channel_s3_bucket_name}/${local.s3_delivery_prefix}AWSLogs/*",
    ]

    # StringLikeIfExists: passes whether or not the request carries the ACL header.
    # Buckets with Object Ownership = BucketOwnerEnforced omit the header entirely;
    # buckets with ACLs enabled require bucket-owner-full-control.
    condition {
      test     = "StringLikeIfExists"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid       = "ConfigS3GetBucketAcl"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::${var.delivery_channel_s3_bucket_name}"]
  }

  dynamic "statement" {
    for_each = var.delivery_channel_s3_kms_key_arn != null ? [var.delivery_channel_s3_kms_key_arn] : []
    content {
      sid    = "ConfigS3KmsEncrypt"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey",
      ]
      resources = [statement.value]
    }
  }
}

resource "aws_iam_policy" "config_s3" {
  count = local.create_iam_role && var.delivery_channel_s3_bucket_name != null ? 1 : 0

  name        = "${local.iam_role_name}-s3-delivery"
  description = "Least-privilege S3 delivery policy for AWS Config."
  policy      = data.aws_iam_policy_document.config_s3[0].json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "config_s3" {
  count = local.create_iam_role && var.delivery_channel_s3_bucket_name != null ? 1 : 0

  role       = aws_iam_role.config[0].name
  policy_arn = aws_iam_policy.config_s3[0].arn
}

# -- Organization Aggregator IAM Role -----------------------------------------
# Organization aggregation requires a role with AWSConfigRoleForOrganizations -
# the recorder role (AWSConfigRole) does not include organizations:* permissions.
# Auto-created only when aggregator_organization is set and no role_arn is supplied.

resource "aws_iam_role" "config_org_aggregator" {
  count = local.create_org_aggregator_role ? 1 : 0

  name               = "${local.iam_role_name}-org-aggregator"
  assume_role_policy = data.aws_iam_policy_document.config_assume[0].json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "config_org_aggregator" {
  count = local.create_org_aggregator_role ? 1 : 0

  role       = aws_iam_role.config_org_aggregator[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}
