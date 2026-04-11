run "validate" {
  command = plan

  variables {
    enabled = false
    name = "test-value"
    bucket = "test-value"
    key = "test-value"
  }
}
