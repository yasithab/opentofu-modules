mock_resource "aws_batch_compute_environment" {
  defaults = {
    arn = "arn:aws:batch:us-east-1:123456789012:mock"
  }
}

mock_resource "aws_iam_role" {
  defaults = {
    arn = "arn:aws:iam::123456789012:role/mock"
  }
}
