mock_resource "aws_appconfig_application" {
  defaults = {
    id = "a1b2c3d"
  }
}

mock_resource "aws_appconfig_configuration_profile" {
  defaults = {
    configuration_profile_id = "c1d2e3f"
  }
}

mock_resource "aws_appconfig_environment" {
  defaults = {
    environment_id = "e1f2g3d"
  }
}
