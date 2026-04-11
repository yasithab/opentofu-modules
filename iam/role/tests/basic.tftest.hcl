run "validate" {
  command = plan

  variables {
    enabled = false
    role_description = "test-value"
  }
}
