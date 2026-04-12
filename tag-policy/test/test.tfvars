name          = "terratest-plan"
attach_to_org = true
description   = "Terratest plan test"
tag_policy = {
  environment = {
    tag_key = "Environment"
    values  = ["production", "staging", "development"]
  }
}
