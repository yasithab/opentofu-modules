# Must fail: ingress rule defines no source (no cidr_ipv4/cidr_ipv6/prefix_list_ids,
# no referenced_security_group_id, self = false).
name   = "terratest-plan"
vpc_id = "vpc-12345678"

ingress_rules = {
  no-source = {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    description = "Rule with no source - targeted validation must reject this"
  }
}
