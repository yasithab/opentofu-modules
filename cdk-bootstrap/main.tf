data "aws_caller_identity" "this" {}
data "aws_region" "this" {}
data "aws_partition" "this" {}

locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  account_id = data.aws_caller_identity.this.account_id
  region     = coalesce(var.region, data.aws_region.this.region)
  partition  = data.aws_partition.this.partition
  qualifier  = var.qualifier

  bucket_name = "cdk-${local.qualifier}-assets-${local.account_id}-${local.region}"
  ecr_name    = "cdk-${local.qualifier}-container-assets-${local.account_id}-${local.region}"

  # Trust principals: always include own account, plus any trusted accounts
  trusted_account_arns = concat(
    ["arn:${local.partition}:iam::${local.account_id}:root"],
    [for id in var.trust_account_ids : "arn:${local.partition}:iam::${id}:root"]
  )

  cfn_execution_policies = coalesce(
    var.cloudformation_execution_policy_arns,
    ["arn:${local.partition}:iam::aws:policy/AdministratorAccess"]
  )
}

################################################################################
# S3 Staging Bucket
################################################################################

resource "aws_s3_bucket" "staging" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = merge(local.tags, { Name = local.bucket_name })

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_s3_bucket_versioning" "staging" {
  bucket = aws_s3_bucket.staging.id

  versioning_configuration {
    status = "Enabled"
  }

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "staging" {
  bucket = aws_s3_bucket.staging.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.create_kms_key ? "aws:kms" : "AES256"
      kms_master_key_id = var.create_kms_key ? aws_kms_key.this.arn : null
    }
    bucket_key_enabled = var.create_kms_key
  }

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_s3_bucket_public_access_block" "staging" {
  bucket = aws_s3_bucket.staging.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_s3_bucket_ownership_controls" "staging" {
  bucket = aws_s3_bucket.staging.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }

  depends_on = [aws_s3_bucket_public_access_block.staging]

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "staging" {
  bucket = aws_s3_bucket.staging.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_s3_bucket_policy" "staging" {
  bucket = aws_s3_bucket.staging.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSSLRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.staging.arn,
          "${aws_s3_bucket.staging.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# KMS Key (for S3 encryption)
################################################################################

resource "aws_kms_key" "this" {
  description             = "CDK bootstrap key for ${local.qualifier}"
  enable_key_rotation     = true
  deletion_window_in_days = var.kms_key_deletion_window

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "KeyAdministration"
        Effect    = "Allow"
        Principal = { AWS = "arn:${local.partition}:iam::${local.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid    = "AllowS3Encryption"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${local.partition}:iam::${local.account_id}:root"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_kms_key
  }
}

resource "aws_kms_alias" "this" {
  name          = "alias/cdk-${local.qualifier}-assets-key"
  target_key_id = aws_kms_key.this.key_id

  lifecycle {
    enabled = local.enabled && var.create_kms_key
  }
}

################################################################################
# ECR Repository
################################################################################

resource "aws_ecr_repository" "this" {
  name                 = local.ecr_name
  image_tag_mutability = "IMMUTABLE"
  force_delete         = var.force_destroy

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = var.create_kms_key ? "KMS" : "AES256"
    kms_key         = var.create_kms_key ? aws_kms_key.this.arn : null
  }

  tags = merge(local.tags, { Name = local.ecr_name })

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 30 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# IAM Roles
################################################################################

# CloudFormation Execution Role — assumed by CloudFormation service
resource "aws_iam_role" "cfn_exec" {
  name = "cdk-${local.qualifier}-cfn-exec-role-${local.account_id}-${local.region}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "cloudformation.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_iam_role_policy_attachment" "cfn_exec" {
  for_each = { for idx, arn in local.cfn_execution_policies : idx => arn if local.enabled }

  role       = aws_iam_role.cfn_exec.name
  policy_arn = each.value
}

# Deployment Action Role — assumed by CDK CLI / CI pipelines
resource "aws_iam_role" "deploy" {
  name = "cdk-${local.qualifier}-deploy-role-${local.account_id}-${local.region}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = local.trusted_account_arns }
        Action    = ["sts:AssumeRole", "sts:TagSession"]
      }
    ]
  })

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_iam_role_policy" "deploy" {
  name = "cdk-deploy-policy"
  role = aws_iam_role.deploy.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudFormationAccess"
        Effect = "Allow"
        Action = [
          "cloudformation:CreateStack",
          "cloudformation:CreateChangeSet",
          "cloudformation:DeleteChangeSet",
          "cloudformation:DescribeChangeSet",
          "cloudformation:DescribeStacks",
          "cloudformation:DescribeStackEvents",
          "cloudformation:ExecuteChangeSet",
          "cloudformation:GetTemplate",
          "cloudformation:DeleteStack",
          "cloudformation:UpdateStack",
          "cloudformation:RollbackStack",
          "cloudformation:ContinueUpdateRollback",
        ]
        Resource = "arn:${local.partition}:cloudformation:${local.region}:${local.account_id}:stack/CDK*"
      },
      {
        Sid      = "S3Access"
        Effect   = "Allow"
        Action   = ["s3:GetObject*", "s3:GetBucket*", "s3:List*"]
        Resource = [aws_s3_bucket.staging.arn, "${aws_s3_bucket.staging.arn}/*"]
      },
      {
        Sid      = "KmsAccess"
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:DescribeKey"]
        Resource = var.create_kms_key ? [aws_kms_key.this.arn] : ["*"]
        Condition = var.create_kms_key ? {} : {
          StringEquals = { "kms:ViaService" = "s3.${local.region}.amazonaws.com" }
        }
      },
      {
        Sid      = "PassRole"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = aws_iam_role.cfn_exec.arn
      },
      {
        Sid      = "SSMRead"
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = "arn:${local.partition}:ssm:${local.region}:${local.account_id}:parameter/cdk-bootstrap/${local.qualifier}/*"
      },
      {
        Sid      = "CFNReadOnly"
        Effect   = "Allow"
        Action   = ["cloudformation:DescribeStacks"]
        Resource = "*"
      }
    ]
  })

  lifecycle {
    enabled = local.enabled
  }
}

# File Publishing Role — assumed by CDK CLI to upload assets to S3
resource "aws_iam_role" "file_publishing" {
  name = "cdk-${local.qualifier}-file-publishing-role-${local.account_id}-${local.region}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = local.trusted_account_arns }
        Action    = ["sts:AssumeRole", "sts:TagSession"]
      }
    ]
  })

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_iam_role_policy" "file_publishing" {
  name = "cdk-file-publishing-policy"
  role = aws_iam_role.file_publishing.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject*",
          "s3:GetBucket*",
          "s3:GetEncryptionConfiguration",
          "s3:List*",
          "s3:DeleteObject*",
          "s3:PutObject*",
          "s3:Abort*",
        ]
        Resource = [aws_s3_bucket.staging.arn, "${aws_s3_bucket.staging.arn}/*"]
      },
      {
        Sid    = "KmsAccess"
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
        ]
        Resource = var.create_kms_key ? [aws_kms_key.this.arn] : ["*"]
        Condition = var.create_kms_key ? {} : {
          StringEquals = { "kms:ViaService" = "s3.${local.region}.amazonaws.com" }
        }
      }
    ]
  })

  lifecycle {
    enabled = local.enabled
  }
}

# Image Publishing Role — assumed by CDK CLI to push Docker images to ECR
resource "aws_iam_role" "image_publishing" {
  name = "cdk-${local.qualifier}-image-publishing-role-${local.account_id}-${local.region}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = local.trusted_account_arns }
        Action    = ["sts:AssumeRole", "sts:TagSession"]
      }
    ]
  })

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_iam_role_policy" "image_publishing" {
  name = "cdk-image-publishing-policy"
  role = aws_iam_role.image_publishing.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAccess"
        Effect = "Allow"
        Action = [
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:BatchCheckLayerAvailability",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
        ]
        Resource = aws_ecr_repository.this.arn
      },
      {
        Sid      = "ECRAuth"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      }
    ]
  })

  lifecycle {
    enabled = local.enabled
  }
}

# Lookup Role — assumed by CDK CLI for context lookups (VPCs, AZs, etc.)
resource "aws_iam_role" "lookup" {
  name = "cdk-${local.qualifier}-lookup-role-${local.account_id}-${local.region}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = concat(local.trusted_account_arns, [for id in var.trust_account_ids_for_lookup : "arn:${local.partition}:iam::${id}:root"]) }
        Action    = ["sts:AssumeRole", "sts:TagSession"]
      }
    ]
  })

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_iam_role_policy_attachment" "lookup_readonly" {
  role       = aws_iam_role.lookup.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/ReadOnlyAccess"

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_iam_role_policy" "lookup_deny_kms" {
  name = "cdk-lookup-deny-kms"
  role = aws_iam_role.lookup.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyKMSDecrypt"
        Effect   = "Deny"
        Action   = ["kms:Decrypt"]
        Resource = "*"
      }
    ]
  })

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# SSM Parameter (bootstrap version)
################################################################################

resource "aws_ssm_parameter" "version" {
  name  = "/cdk-bootstrap/${local.qualifier}/version"
  type  = "String"
  value = tostring(var.bootstrap_version)

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# OpenTofu Check Blocks
################################################################################

check "bucket_encryption_enabled" {
  assert {
    condition     = !var.enabled || aws_s3_bucket_public_access_block.staging.block_public_acls
    error_message = "CDK staging bucket must have public access blocked."
  }
}
