run "validate" {
  command = plan

  variables {
    enabled = false
    alarm_name = "test-value"
    alarm_rule = "test-value"
  }
}
