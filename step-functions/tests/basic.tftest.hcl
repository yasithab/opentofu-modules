run "validate" {
  command = plan

  variables {
    enabled = false
    name = "test-value"
    definition = "test-value"
  }
}
