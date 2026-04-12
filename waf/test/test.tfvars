name           = "terratest-plan"
scope          = "REGIONAL"
default_action = "ALLOW"
visibility_config = {
  cloudwatch_metrics_enabled = true
  metric_name                = "terratest-plan"
  sampled_requests_enabled   = true
}
