mock_resource "aws_iam_instance_profile" {
  defaults = {
    arn = "arn:aws:iam::123456789012:policy/mock"
  }
}

mock_resource "aws_iam_role" {
  defaults = {
    arn = "arn:aws:iam::123456789012:role/mock"
  }
}

mock_resource "aws_launch_template" {
  defaults = {
    id = "lt-1234567890abcdef0"
  }
}
