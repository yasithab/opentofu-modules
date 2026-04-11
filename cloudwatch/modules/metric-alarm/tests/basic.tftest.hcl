run "validate" {
  command = plan

  variables {
    enabled = false
    alarm_name = "test-value"
    comparison_operator = "test-value"
    evaluation_periods = 1
  }
}
