name      = "terratest-plan"
direction = "INBOUND"
vpc_id    = "vpc-12345678"
ip_addresses = [
  {
    subnet_id = "subnet-12345678"
  },
  {
    subnet_id = "subnet-87654321"
  }
]
