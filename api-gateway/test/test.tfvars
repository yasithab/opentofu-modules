name = "terratest-plan"

usage_plans = {
  standard = {
    description = "Standard tier"
    quota_settings = {
      limit  = 10000
      period = "MONTH"
    }
    throttle_settings = {
      burst_limit = 100
      rate_limit  = 50
    }
  }
}

api_keys = {
  partner = {
    description    = "Partner integration key"
    usage_plan_key = "standard"
  }
}

waf_web_acl_arn = "arn:aws:wafv2:eu-west-1:111111111111:regional/webacl/terratest-plan/00000000-0000-0000-0000-000000000000"
