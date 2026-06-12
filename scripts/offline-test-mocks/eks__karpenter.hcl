mock_resource "aws_iam_policy" {
  defaults = {
    arn = "arn:aws:iam::123456789012:policy/mock"
  }
}

mock_resource "aws_iam_role" {
  defaults = {
    arn = "arn:aws:iam::123456789012:role/mock"
  }
}

mock_resource "aws_sqs_queue" {
  defaults = {
    arn = "arn:aws:sqs:us-east-1:123456789012:mock"
  }
}
