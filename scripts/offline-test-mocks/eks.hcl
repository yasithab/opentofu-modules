mock_resource "aws_eks_cluster" {
  defaults = {
    certificate_authority = [{ data = "bW9jay1jZXJ0aWZpY2F0ZS1kYXRh" }]
    identity = [{ oidc = [{ issuer = "https://oidc.eks.us-east-1.amazonaws.com/id/MOCK1234567890" }] }]
  }
}

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
