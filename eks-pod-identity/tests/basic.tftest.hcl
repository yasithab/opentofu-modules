run "validate" {
  command = plan

  variables {
    enabled = false
    name = "test-value"
    cluster_name = "test-value"
  }
}
