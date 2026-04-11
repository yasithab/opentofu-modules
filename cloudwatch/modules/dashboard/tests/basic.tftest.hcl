run "validate" {
  command = plan

  variables {
    enabled = false
    dashboard_name = "test-value"
    dashboard_body = "test-value"
  }
}
