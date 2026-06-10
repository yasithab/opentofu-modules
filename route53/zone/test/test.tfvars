zones = {
  "test.example.com" = {}

  "signed.example.com" = {
    dnssec = {
      kms_key_arn = "arn:aws:kms:us-east-1:111111111111:key/00000000-0000-0000-0000-000000000000"
    }
    query_logging = {
      log_group_retention_in_days = 90
    }
  }
}

create_query_log_resource_policy = true
