run "validate" {
  command = plan

  variables {
    enabled = false
    broker_name = "test-value"
    subnet_ids = []
    users = []
  }
}
