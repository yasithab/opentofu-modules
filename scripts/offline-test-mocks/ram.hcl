mock_data "aws_organizations_organization" {
  defaults = {
    arn = "arn:aws:organizations::123456789012:organization/o-abcdef1234"
  }
}

mock_resource "aws_ram_resource_share" {
  defaults = {
    id = "arn:aws:ram:us-east-1:123456789012:resource-share/mock"
  }
}
