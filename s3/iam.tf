locals {
  replication_role_name = substr("s3-repl-${aws_s3_bucket.this.id}", 0, 64)
}

resource "aws_iam_role" "replication" {
  name = local.replication_role_name

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY

  tags = local.tags

  lifecycle {
    enabled = var.create_bucket_replication_role == true
  }
}

resource "aws_iam_policy" "replication" {
  name = local.replication_role_name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.this.id}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersion",
        "s3:GetObjectVersionAcl"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.this.id}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.destination_bucket_name}/*"
    }
  ]
}
POLICY

  lifecycle {
    enabled = var.create_bucket_replication_role == true
  }
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn

  lifecycle {
    enabled = var.create_bucket_replication_role == true
  }
}
