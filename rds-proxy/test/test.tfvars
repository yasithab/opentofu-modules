name           = "terratest-plan"
engine_family  = "MYSQL"
vpc_subnet_ids = ["subnet-12345678"]
auth = {
  iam = { auth_scheme = "SECRETS", iam_auth = "REQUIRED", secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:test" }
}
