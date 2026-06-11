mock_resource "aws_iam_policy" {
  defaults = {
    arn = "arn:aws:iam::123456789012:policy/mock"
  }
}

mock_resource "aws_launch_template" {
  defaults = {
    id = "lt-1234567890abcdef0"
  }
}
