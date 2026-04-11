run "validate" {
  command = plan

  variables {
    enabled = false
    firehose_arn = "test-value"
    role_arn = "test-value"
    output_format = "test-value"
  }
}
