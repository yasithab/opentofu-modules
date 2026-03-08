data "aws_organizations_organization" "org" {}

locals {
  name                                       = var.name
  tags                                       = merge(var.tags, { ManagedBy = "opentofu" })
  deny_leaving_orgs_statement                = var.deny_leaving_orgs ? [""] : []
  deny_creating_iam_users_statement          = var.deny_creating_iam_users ? [""] : []
  deny_deleting_kms_keys_statement           = var.deny_deleting_kms_keys ? [""] : []
  deny_deleting_route53_zones_statement      = var.deny_deleting_route53_zones ? [""] : []
  deny_deleting_cloudwatch_logs_statement    = var.deny_deleting_cloudwatch_logs ? [""] : []
  deny_root_account_statement                = var.deny_root_account ? [""] : []
  protect_s3_buckets_statement               = var.protect_s3_buckets ? [""] : []
  deny_s3_buckets_public_access_statement    = var.deny_s3_buckets_public_access ? [""] : []
  protect_iam_roles_statement                = var.protect_iam_roles ? [""] : []
  limit_ec2_instance_types                   = var.limit_ec2_instance_types ? [""] : []
  limit_regions_statement                    = var.limit_regions ? [""] : []
  deny_unencrypted_object_uploads_statement  = var.require_s3_encryption ? [""] : []
  deny_incorrect_encryption_header_statement = var.require_s3_encryption ? [""] : []
  deny_network_modifications_statement       = var.deny_network_modifications ? [""] : []
  deny_vpc_modifications_statement           = var.deny_vpc_modifications ? [""] : []
  require_mfa_statement                      = var.require_mfa ? [""] : []
  enforce_cloudtrail_logging_statement       = var.enforce_cloudtrail_logging ? [""] : []
  enforce_resource_tagging_statement         = var.enforce_resource_tagging ? [""] : []

  # Generate conditions dynamically based on required_tag_keys
  resource_tagging_conditions = var.enforce_resource_tagging ? [
    for tag in var.required_tag_keys : {
      test     = "Null"
      variable = "aws:RequestTag/${tag}"
      values   = ["true"]
    }
  ] : []
}

################################################################################
# Combine Policies
################################################################################

data "aws_iam_policy_document" "combined_policy_block" {
  # Deny leaving AWS Organizations
  dynamic "statement" {
    for_each = local.deny_leaving_orgs_statement
    content {
      sid       = "DenyLeavingOrgs"
      effect    = "Deny"
      actions   = ["organizations:LeaveOrganization"]
      resources = ["*"]
    }
  }

  # Deny creating IAM users or access keys
  dynamic "statement" {
    for_each = local.deny_creating_iam_users_statement
    content {
      sid    = "DenyCreatingIAMUsers"
      effect = "Deny"
      actions = [
        "iam:CreateUser",
        "iam:CreateAccessKey"
      ]
      resources = ["*"]
    }
  }

  # Deny deleting KMS Keys
  dynamic "statement" {
    for_each = local.deny_deleting_kms_keys_statement
    content {
      sid    = "DenyDeletingKMSKeys"
      effect = "Deny"
      actions = [
        "kms:ScheduleKeyDeletion",
        "kms:Delete*"
      ]
      resources = ["*"]
    }
  }

  # Deny deleting Route53 Hosted Zones
  dynamic "statement" {
    for_each = local.deny_deleting_route53_zones_statement
    content {
      sid    = "DenyDeletingRoute53Zones"
      effect = "Deny"
      actions = [
        "route53:DeleteHostedZone"
      ]
      resources = ["*"]
    }
  }

  # Deny deleting VPC Flow logs, cloudwatch log groups, and cloudwatch log streams
  dynamic "statement" {
    for_each = local.deny_deleting_cloudwatch_logs_statement
    content {
      sid    = "DenyDeletingCloudwatchLogs"
      effect = "Deny"
      actions = [
        "ec2:DeleteFlowLogs",
        "logs:DeleteLogGroup",
        "logs:DeleteLogStream"
      ]
      resources = ["*"]
    }
  }

  # Deny root account
  dynamic "statement" {
    for_each = local.deny_root_account_statement
    content {
      sid       = "DenyRootAccount"
      actions   = ["*"]
      resources = ["*"]
      effect    = "Deny"
      condition {
        test     = "StringLike"
        variable = "aws:PrincipalArn"
        values   = ["arn:aws:iam::*:root"]
      }
    }
  }

  # Protect S3 Buckets
  dynamic "statement" {
    for_each = local.protect_s3_buckets_statement
    content {
      sid    = "ProtectS3Buckets"
      effect = "Deny"
      actions = [
        "s3:DeleteBucket",
        "s3:DeleteObject",
        "s3:DeleteObjectVersion",
      ]
      resources = var.protect_s3_bucket_resources
    }
  }

  # Deny S3 Buckets Public Access
  dynamic "statement" {
    for_each = local.deny_s3_buckets_public_access_statement
    content {
      sid    = "DenyS3BucketsPublicAccess"
      effect = "Deny"
      actions = [
        "s3:PutBucketPublicAccessBlock",
        "s3:DeletePublicAccessBlock"
      ]
      resources = var.deny_s3_bucket_public_access_resources
    }
  }

  # Protect IAM Roles
  dynamic "statement" {
    for_each = local.protect_iam_roles_statement
    content {
      sid    = "ProtectIAMRoles"
      effect = "Deny"
      actions = [
        "iam:AttachRolePolicy",
        "iam:DeleteRole",
        "iam:DeleteRolePermissionsBoundary",
        "iam:DeleteRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePermissionsBoundary",
        "iam:PutRolePolicy",
        "iam:UpdateAssumeRolePolicy",
        "iam:UpdateRole",
        "iam:UpdateRoleDescription"
      ]
      resources = var.protect_iam_role_resources
    }
  }

  # Restrict EC2 Instance Types
  dynamic "statement" {
    for_each = local.limit_ec2_instance_types
    content {
      sid    = "LimitEC2InstanceTypes"
      effect = "Deny"
      actions = [
        "ec2:RunInstances",
        "ec2:StartInstances"
      ]
      resources = ["*"]
      condition {
        test     = "StringNotEquals"
        variable = "ec2:InstanceType"
        values   = var.allowed_ec2_instance_types
      }
    }
  }

  # Restrict Regional Operations
  dynamic "statement" {
    for_each = local.limit_regions_statement
    content {
      sid    = "LimitRegions"
      effect = "Deny"

      # These actions do not operate in a specific region, or only run in
      # a single region, so we don't want to try restricting them by region.
      # List of actions can be found in the following example:
      # https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_examples_general.html
      not_actions = [
        "a4b:*",
        "acm:*",
        "aws-marketplace-management:*",
        "aws-marketplace:*",
        "aws-portal:*",
        "budgets:*",
        "ce:*",
        "chatbot:*",
        "chime:*",
        "cloudfront:*",
        "config:*",
        "cur:*",
        "directconnect:*",
        "ec2:DescribeRegions",
        "ec2:DescribeTransitGateways",
        "ec2:DescribeVpnGateways",
        "ecr-public:*",
        "fms:*",
        "globalaccelerator:*",
        "health:*",
        "iam:*",
        "importexport:*",
        "kms:*",
        "mobileanalytics:*",
        "networkmanager:*",
        "organizations:*",
        "pricing:*",
        "route53:*",
        "route53domains:*",
        "route53-recovery-cluster:*",
        "route53-recovery-control-config:*",
        "route53-recovery-readiness:*",
        "s3:GetAccountPublic*",
        "s3:ListAllMyBuckets",
        "s3:ListMultiRegionAccessPoints",
        "s3:PutAccountPublic*",
        "shield:*",
        "sts:*",
        "support:*",
        "supportapp:*",
        "supportplans:*",
        "trustedadvisor:*",
        "waf-regional:*",
        "waf:*",
        "wafv2:*",
        "wellarchitected:*"
      ]

      resources = ["*"]

      condition {
        test     = "StringNotEquals"
        variable = "aws:RequestedRegion"
        values   = var.allowed_regions
      }
    }
  }

  # Require S3 encryption
  dynamic "statement" {
    for_each = local.deny_incorrect_encryption_header_statement
    content {
      sid       = "DenyIncorrectEncryptionHeader"
      effect    = "Deny"
      actions   = ["s3:PutObject"]
      resources = ["*"]
      condition {
        test     = "StringNotEquals"
        variable = "s3:x-amz-server-side-encryption"
        values   = ["AES256", "aws:kms"]
      }
    }
  }

  dynamic "statement" {
    for_each = local.deny_unencrypted_object_uploads_statement
    content {
      sid       = "DenyUnEncryptedObjectUploads"
      effect    = "Deny"
      actions   = ["s3:PutObject"]
      resources = ["*"]
      condition {
        test     = "Null"
        variable = "s3:x-amz-server-side-encryption"
        values   = [true]
      }
    }
  }

  # Deny network modifications
  dynamic "statement" {
    for_each = local.deny_network_modifications_statement
    content {
      sid    = "DenyNetworkModifications"
      effect = "Deny"
      actions = [
        "ec2:CreateNetworkAcl",
        "ec2:CreateNetworkAclEntry",
        "ec2:DeleteNetworkAcl",
        "ec2:DeleteNetworkAclEntry",
        "ec2:ReplaceNetworkAclEntry",
        "ec2:ReplaceNetworkAclAssociation",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress"
      ]
      resources = ["*"]
    }
  }

  # Deny VPC modifications
  dynamic "statement" {
    for_each = local.deny_vpc_modifications_statement
    content {
      sid    = "DenyVPCModifications"
      effect = "Deny"
      actions = [
        "ec2:CreateVpc",
        "ec2:DeleteVpc",
        "ec2:ModifyVpcAttribute",
        "ec2:CreateVpcPeeringConnection",
        "ec2:AcceptVpcPeeringConnection"
      ]
      resources = ["*"]
    }
  }

  # Require MFA
  dynamic "statement" {
    for_each = local.require_mfa_statement
    content {
      sid    = "RequireMFA"
      effect = "Deny"
      actions = [
        "iam:CreateAccessKey",
        "iam:UpdateLoginProfile",
        "iam:DeleteLoginProfile",
        "iam:CreateLoginProfile"
      ]
      resources = ["*"]
      condition {
        test     = "BoolIfExists"
        variable = "aws:MultiFactorAuthPresent"
        values   = ["false"]
      }
    }
  }

  # Enforce CloudTrail logging
  dynamic "statement" {
    for_each = local.enforce_cloudtrail_logging_statement
    content {
      sid    = "EnforceCloudTrailLogging"
      effect = "Deny"
      actions = [
        "cloudtrail:StopLogging",
        "cloudtrail:DeleteTrail"
      ]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = local.enforce_resource_tagging_statement
    content {
      sid    = "EnforceResourceTagging"
      effect = "Deny"

      actions = var.tag_enforcement_actions

      resources = ["*"]

      dynamic "condition" {
        for_each = local.resource_tagging_conditions
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

# Deny all access policy
data "aws_iam_policy_document" "deny_all_access" {
  statement {
    sid       = "DenyAllAccess"
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]
  }
}

resource "aws_organizations_policy" "this" {
  name         = local.name
  description  = var.description
  content      = var.deny_all ? data.aws_iam_policy_document.deny_all_access.json : data.aws_iam_policy_document.combined_policy_block.json
  type         = "SERVICE_CONTROL_POLICY"
  skip_destroy = var.skip_destroy

  tags = local.tags
}

resource "aws_organizations_policy_attachment" "attach_ous" {
  for_each = toset(var.attach_ous)

  policy_id = aws_organizations_policy.this.id
  target_id = each.value
}

resource "aws_organizations_policy_attachment" "attach_org" {
  policy_id = aws_organizations_policy.this.id
  target_id = data.aws_organizations_organization.org.roots[0].id

  lifecycle {
    enabled = var.attach_to_org
  }
}
