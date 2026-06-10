name        = "terratest-plan"
vpc_id      = "vpc-12345678"
description = "Terratest plan security group"

ingress_rules = {
  # Multi-CIDR fan-out: one rule per IPv4 CIDR
  https = {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    description = "HTTPS from app subnets"
    cidr_ipv4   = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  }

  # Mixed IPv4 + IPv6 sources on a single rule
  postgres = {
    from_port   = 5432
    to_port     = 5432
    ip_protocol = "tcp"
    description = "PostgreSQL from app tier"
    cidr_ipv4   = ["10.0.20.0/24", "10.0.21.0/24"]
    cidr_ipv6   = ["2001:db8::/64"]
  }

  # Referenced security group source
  app-from-alb = {
    from_port                    = 8080
    to_port                      = 8080
    ip_protocol                  = "tcp"
    description                  = "App traffic from ALB security group"
    referenced_security_group_id = "sg-0aaaa11111111111a"
  }

  # Prefix-list fan-out: one rule per prefix list ID
  endpoints = {
    from_port       = 443
    to_port         = 443
    ip_protocol     = "tcp"
    description     = "HTTPS from VPC endpoint prefix lists"
    prefix_list_ids = ["pl-12345678", "pl-87654321"]
  }

  # Self-referencing rule, protocol "-1" so ports are omitted
  intra = {
    ip_protocol = "-1"
    description = "Allow all traffic within the security group"
    self        = true
  }
}

egress_rules = {
  # Explicit open egress (opt-in, nothing is opened implicitly)
  https-anywhere = {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    description = "HTTPS to anywhere"
    cidr_ipv4   = ["0.0.0.0/0"]
    cidr_ipv6   = ["::/0"]
  }

  dns-udp = {
    from_port   = 53
    to_port     = 53
    ip_protocol = "udp"
    description = "DNS to VPC resolver"
    cidr_ipv4   = ["10.0.0.0/16"]
  }

  dns-tcp = {
    from_port   = 53
    to_port     = 53
    ip_protocol = "tcp"
    description = "DNS to VPC resolver"
    cidr_ipv4   = ["10.0.0.0/16"]
  }

  s3-endpoint = {
    from_port       = 443
    to_port         = 443
    ip_protocol     = "tcp"
    description     = "HTTPS to S3 gateway endpoint"
    prefix_list_ids = ["pl-0aaaa11111111111a"]
  }

  replication = {
    from_port                    = 9300
    to_port                      = 9300
    ip_protocol                  = "tcp"
    description                  = "Cluster replication to peer security group"
    referenced_security_group_id = "sg-0bbbb22222222222b"
  }
}

tags = {
  Environment = "test"
}
