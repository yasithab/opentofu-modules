# Must fail: authentication_mode must be one of CONFIG_MAP, API or API_AND_CONFIG_MAP.
name            = "terratest-plan"
cluster_version = "1.31"
vpc_id          = "vpc-12345678"
subnet_ids      = ["subnet-12345678", "subnet-87654321"]

authentication_mode = "IAM_ONLY"
