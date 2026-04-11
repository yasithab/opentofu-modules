run "validate" {
  command = plan

  variables {
    enabled = false
    cluster_name = "test-value"
  }
}
