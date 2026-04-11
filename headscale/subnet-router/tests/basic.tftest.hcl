run "validate" {
  command = plan

  variables {
    enabled = false
    name = "test-value"
    vpc_id = "test-value"
    subnet_id = "test-value"
    headscale_server_url = "test-value"
    advertise_routes = []
  }
}
