run "validate" {
  command = plan

  variables {
    enabled = false
    name = "test-value"
    s3_bucket_name = "test-value"
  }
}
