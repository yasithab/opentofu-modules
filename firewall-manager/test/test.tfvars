enabled = true

waf_v2_policies = [
  {
    name          = "terratest-plan-waf-policy"
    resource_type = "AWS::ElasticLoadBalancingV2::LoadBalancer"

    policy_data = {
      default_action           = "ALLOW"
      pre_process_rule_groups  = []
      post_process_rule_groups = []
    }
  }
]
