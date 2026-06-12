mock_data "aws_ssoadmin_instances" {
  defaults = {
    arns = ["arn:aws:sso:::instance/ssoins-1234567890abcdef"]
    identity_store_ids = ["d-1234567890"]
  }
}
