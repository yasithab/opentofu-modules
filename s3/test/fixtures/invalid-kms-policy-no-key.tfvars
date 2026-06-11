# Must fail: attach_deny_incorrect_kms_key_sse = true requires allowed_kms_key_arn.
name                              = "terratest-plan-bucket"
attach_deny_incorrect_kms_key_sse = true
# allowed_kms_key_arn intentionally omitted (defaults to null)
