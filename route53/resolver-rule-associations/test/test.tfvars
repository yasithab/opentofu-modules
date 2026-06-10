vpc_id = "vpc-12345678"

resolver_rules = {
  onprem = {
    domain_name          = "corp.example.com"
    rule_type            = "FORWARD"
    resolver_endpoint_id = "rslvr-out-0123456789abcdef0"
    target_ips = [
      { ip = "10.10.0.10" },
      { ip = "10.10.1.10" },
    ]
  }
}

resolver_rule_associations = {
  onprem = {}
}
