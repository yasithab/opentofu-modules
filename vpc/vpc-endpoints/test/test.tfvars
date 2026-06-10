vpc_id     = "vpc-12345678"
subnet_ids = ["subnet-11111111", "subnet-22222222"]

endpoints = {
  s3 = {
    service         = "s3"
    service_type    = "Gateway"
    route_table_ids = ["rtb-12345678"]
  }
  ssm = {
    service             = "ssm"
    private_dns_enabled = true
  }
}

create_security_group      = true
security_group_name        = "terratest-vpc-endpoints"
security_group_description = "Terratest VPC endpoints security group"

security_group_rules = {
  ingress_https = {
    type        = "ingress"
    description = "HTTPS from VPC"
    cidr_ipv4   = "10.99.0.0/16"
  }
  egress_all = {
    type        = "egress"
    ip_protocol = "-1"
    description = "Allow all egress"
    cidr_ipv4   = "0.0.0.0/0"
  }
}
