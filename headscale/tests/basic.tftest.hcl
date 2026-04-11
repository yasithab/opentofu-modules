run "validate" {
  command = plan

  variables {
    enabled = false
    name = "test-value"
    vpc_id = "test-value"
    subnet_id = "test-value"
    server_url = "test-value"
  }
}
