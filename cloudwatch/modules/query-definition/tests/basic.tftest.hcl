run "validate" {
  command = plan

  variables {
    enabled = false
    name = "test-value"
    query_string = "test-value"
  }
}
