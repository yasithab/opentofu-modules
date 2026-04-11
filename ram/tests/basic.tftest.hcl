run "validate" {
  command = plan

  variables {
    enabled = false
    ram_resource_share_name = "test-value"
    ram_resource_arn = "test-value"
  }
}
