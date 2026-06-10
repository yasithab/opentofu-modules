aws_service_access_principals = ["sso.amazonaws.com"]
enabled_policy_types          = ["SERVICE_CONTROL_POLICY"]

organizational_units = {
  security  = { name = "Security" }
  workloads = { name = "Workloads" }
  prod      = { name = "Production", parent_key = "workloads" }
}

tags = {
  Environment = "test"
}
