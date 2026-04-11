run "validate" {
  command = plan

  variables {
    enabled = false
    name = "test-value"
    destination_arn = "test-value"
    log_group_name = "test-value"
  }
}
