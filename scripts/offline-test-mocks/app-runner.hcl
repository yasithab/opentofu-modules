mock_resource "aws_apprunner_observability_configuration" {
  defaults = {
    arn = "arn:aws:apprunner:us-east-1:123456789012:mock"
  }
}

mock_resource "aws_iam_role" {
  defaults = {
    arn = "arn:aws:iam::123456789012:role/mock"
  }
}
