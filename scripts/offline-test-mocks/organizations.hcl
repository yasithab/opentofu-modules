mock_resource "aws_organizations_organization" {
  defaults = {
    roots = [{ id = "r-mock", arn = "arn:aws:organizations::123456789012:root/o-abcdef1234/r-mock", name = "Root", policy_types = [] }]
  }
}

mock_resource "aws_organizations_organizational_unit" {
  defaults = {
    id = "ou-abcd-12345678"
  }
}
