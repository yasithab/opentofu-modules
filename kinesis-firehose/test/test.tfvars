name                                  = "terratest-plan"
destination                           = "extended_s3"
s3_bucket_arn                         = "arn:aws:s3:::terratest-firehose-dest"
firehose_role                         = "arn:aws:iam::123456789012:role/terratest-firehose"
vpc_create_destination_security_group = false
