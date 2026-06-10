name = "terratest-plan"

vpc_attachments = {
  app = {
    transit_gateway_id = "tgw-0123456789abcdef0"
    vpc_id             = "vpc-12345678"
    subnet_ids         = ["subnet-11111111", "subnet-22222222"]
  }
}
