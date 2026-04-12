name                         = "terratest-plan"
destination                  = "extended_s3"
s3_bucket_arn                = "arn:aws:s3:::terratest-firehose-dest"
role_arn                     = "arn:aws:iam::928430096450:role/terratest-firehose"
create_destination_vpc_sg    = false
vpc_create_destination_group = false
