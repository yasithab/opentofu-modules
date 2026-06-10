env_name                 = "terratest"
repository_name          = "test-repo"
github_organization_name = "test-org"
vpc_id                   = "vpc-0123456789abcdef0"
codebuild_subnets        = ["subnet-12345678", "subnet-87654321"]

create_iam_role      = true
codebuild_iam_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"logs:CreateLogStream\",\"logs:PutLogEvents\"],\"Resource\":\"*\"}]}"

create_security_group = true

codebuild_runner_repository_url = "123456789012.dkr.ecr.us-east-1.amazonaws.com/codebuild-runner"
