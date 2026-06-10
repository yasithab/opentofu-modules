name = "terratest-plan"

service_accounts = {
  terratest-automation = {
    grafana_role = "VIEWER"
    tokens = {
      ci = {
        seconds_to_live = 3600
      }
    }
  }
}
