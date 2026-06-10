parameter_write = [
  {
    name        = "/terratest/plan/config"
    value       = "terratest-value"
    type        = "String"
    description = "Terratest plan parameter"
  },
  {
    name             = "/terratest/plan/secret"
    type             = "SecureString"
    value_wo         = "terratest-write-only-value"
    value_wo_version = "1"
  },
]
