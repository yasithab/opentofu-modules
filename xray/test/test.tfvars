enabled = true

sampling_rules = {
  terratest-rule = {
    priority       = 100
    reservoir_size = 1
    fixed_rate     = 0.05
    service_name   = "terratest-service"
  }
}

groups = {
  terratest-group = {
    filter_expression = "service(\"terratest-service\")"
    insights_configuration = {
      insights_enabled      = true
      notifications_enabled = false
    }
  }
}
