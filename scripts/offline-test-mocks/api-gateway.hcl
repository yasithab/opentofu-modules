mock_resource "aws_api_gateway_stage" {
  defaults = {
    arn = "arn:aws:api:us-east-1:123456789012:mock"
  }
}

mock_resource "aws_cloudwatch_log_group" {
  defaults = {
    arn = "arn:aws:logs:us-east-1:123456789012:mock"
  }
}
