name = "terratest-plan"

canaries = {
  # Exercises the default-fallback paths: no artifact_s3_location,
  # create_alarm unset (falls back to create_canary_alarms),
  # all alarm_* attributes unset (fall back to module defaults).
  defaults = {
    name                = "terratest-defaults"
    handler             = "index.handler"
    runtime_version     = "syn-nodejs-puppeteer-9.1"
    schedule_expression = "rate(5 minutes)"
    zip_file            = "test/canary.zip"
  }

  # Exercises explicit overrides.
  overrides = {
    name                     = "terratest-overrides"
    handler                  = "index.handler"
    runtime_version          = "syn-nodejs-puppeteer-9.1"
    schedule_expression      = "rate(10 minutes)"
    zip_file                 = "test/canary.zip"
    artifact_s3_location     = "s3://my-existing-bucket/custom-prefix"
    success_retention_period = 7
    failure_retention_period = 14
    create_alarm             = true
    alarm_name               = "terratest-overrides-custom-alarm"
    alarm_evaluation_periods = 2
    alarm_period             = 600
    alarm_threshold          = 90
    alarm_actions            = ["arn:aws:sns:us-east-1:123456789012:alerts"]
    run_config = {
      timeout_in_seconds = 120
      memory_in_mb       = 1024
    }
  }
}

canary_groups = {
  terratest-group = {
    canary_keys = ["defaults", "overrides"]
  }
}
