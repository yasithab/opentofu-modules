# Must fail: create_role = true with both name and role_name null leaves the
# IAM role without a valid name.
destination                           = "extended_s3"
s3_bucket_arn                         = "arn:aws:s3:::terratest-firehose-dest"
vpc_create_destination_security_group = false

create_role = true
# name and role_name intentionally omitted (both default to null)
