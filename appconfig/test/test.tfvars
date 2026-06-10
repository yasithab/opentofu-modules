name = "terratest-plan"

environments = {
  production = {
    description = "Terratest production environment"
  }
}

configuration_profiles = {
  app-settings = {
    description = "Terratest application settings"
  }
}

hosted_configuration_versions = {
  app-settings = {
    content = "{\"feature_enabled\":true}"
  }
}

deployment_strategies = {
  fast = {
    deployment_duration_in_minutes = 5
    growth_factor                  = 25
  }
}
