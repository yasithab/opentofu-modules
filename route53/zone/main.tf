data "aws_partition" "current" {}

locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
    Region    = data.aws_region.current.region
  })

  dnssec_zones    = { for k, v in var.zones : k => v if local.enabled && v.dnssec != null }
  query_log_zones = { for k, v in var.zones : k => v if local.enabled && v.query_logging != null }

  # Zones with query logging that need a module-created log group
  query_log_create_group = { for k, v in local.query_log_zones : k => v if v.query_logging.cloudwatch_log_group_arn == null }

  create_query_log_resource_policy = local.enabled && var.create_query_log_resource_policy
}

resource "aws_route53_zone" "default" {
  for_each = { for k, v in var.zones : k => v if local.enabled }

  name                        = each.value.domain_name != null ? each.value.domain_name : each.key
  comment                     = each.value.comment
  force_destroy               = each.value.force_destroy
  enable_accelerated_recovery = each.value.enable_accelerated_recovery

  delegation_set_id = each.value.delegation_set_id

  dynamic "vpc" {
    for_each = each.value.vpc

    content {
      vpc_id     = vpc.value.vpc_id
      vpc_region = vpc.value.vpc_region
    }
  }

  # Prevent the deletion of associated VPCs after the initial creation. See documentation on aws_route53_zone_association for details
  lifecycle {
    ignore_changes = [vpc]
  }

  tags = merge(local.tags, each.value.tags)
}

################################################################################
# DNSSEC Signing
################################################################################

# The KMS key must be an asymmetric, customer-managed ECC_NIST_P256 key located
# in us-east-1, with a key policy that allows the Route 53 DNSSEC service
# (dnssec-route53.amazonaws.com) to use it.
resource "aws_route53_key_signing_key" "this" {
  for_each = local.dnssec_zones

  hosted_zone_id             = aws_route53_zone.default[each.key].zone_id
  key_management_service_arn = each.value.dnssec.kms_key_arn
  name                       = coalesce(each.value.dnssec.key_signing_key_name, "ksk")
  status                     = each.value.dnssec.key_signing_key_status
}

resource "aws_route53_hosted_zone_dnssec" "this" {
  for_each = local.dnssec_zones

  hosted_zone_id = aws_route53_key_signing_key.this[each.key].hosted_zone_id
  signing_status = each.value.dnssec.signing_status

  depends_on = [aws_route53_key_signing_key.this]
}

################################################################################
# Query Logging
################################################################################

# Route 53 only delivers public DNS query logs to CloudWatch Logs in us-east-1,
# so module-created log groups (and any externally supplied log group) must
# live in that region.
resource "aws_cloudwatch_log_group" "query_log" {
  for_each = local.query_log_create_group

  name              = "/aws/route53/${each.value.domain_name != null ? each.value.domain_name : each.key}"
  retention_in_days = each.value.query_logging.log_group_retention_in_days
  kms_key_id        = each.value.query_logging.log_group_kms_key_id

  tags = merge(local.tags, each.value.tags)
}

# CloudWatch Logs resource policy allowing Route 53 to deliver query logs.
# This is account-wide - enable it here only if it is not already managed elsewhere.
data "aws_iam_policy_document" "query_log" {
  count = local.create_query_log_resource_policy ? 1 : 0

  statement {
    sid    = "Route53QueryLogging"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:${data.aws_partition.current.partition}:logs:*:*:log-group:/aws/route53/*"]

    principals {
      type        = "Service"
      identifiers = ["route53.amazonaws.com"]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "query_log" {
  policy_name     = var.query_log_resource_policy_name
  policy_document = data.aws_iam_policy_document.query_log[0].json

  lifecycle {
    enabled = local.create_query_log_resource_policy
  }
}

resource "aws_route53_query_log" "this" {
  for_each = local.query_log_zones

  zone_id                  = aws_route53_zone.default[each.key].zone_id
  cloudwatch_log_group_arn = each.value.query_logging.cloudwatch_log_group_arn != null ? each.value.query_logging.cloudwatch_log_group_arn : aws_cloudwatch_log_group.query_log[each.key].arn

  depends_on = [aws_cloudwatch_log_resource_policy.query_log]
}

data "aws_region" "current" {}
