run "validate" {
  command = plan

  variables {
    enabled = false
    log_group_name = "test-value"
  }
}
