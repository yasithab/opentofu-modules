iam_role_name            = "terratest-plan"
github_organization_name = "test-org"
repo_names               = ["test-repo"]
enabled                  = true
github_oidc_arn          = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
iam_policy_document      = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"s3:GetObject\"],\"Resource\":[\"*\"]}]}"
