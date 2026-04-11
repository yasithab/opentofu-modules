run "validate" {
  command = plan

  variables {
    enabled = false
    name = "test-value"
    pattern = "test-value"
    log_group_name = "test-value"
    metric_transformation_name = "test-value"
    metric_transformation_namespace = "test-value"
  }
}
