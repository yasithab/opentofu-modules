run "validate" {
  command = plan

  variables {
    enabled = false
    name = "test-value"
    storage_capacity = 1
  }
}
