mock_data "aws_iam_session_context" {
  defaults = {
    issuer_arn = "arn:aws:iam::123456789012:policy/mock"
  }
}

mock_resource "aws_cloudwatch_log_group" {
  defaults = {
    arn = "arn:aws:logs:us-east-1:123456789012:mock"
  }
}
