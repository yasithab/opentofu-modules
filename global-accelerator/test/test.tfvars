name = "terratest-plan"

listeners = {
  http = {
    protocol = "TCP"
    port_ranges = [
      { from_port = 80, to_port = 80 },
    ]
  }
}

endpoint_groups = {
  http = {
    listener_key          = "http"
    endpoint_group_region = "us-east-1"
    endpoint_configurations = [
      {
        endpoint_id = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/test/0123456789abcdef"
        weight      = 100
      },
    ]
  }
}
