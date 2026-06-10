enabled = true
name    = "terratest-plan"

ipsets = {
  trusted-ips = {
    format   = "TXT"
    location = "https://s3.amazonaws.com/terratest-plan-bucket/ipset.txt"
  }
}

threat_intel_sets = {
  known-threats = {
    format   = "TXT"
    location = "https://s3.amazonaws.com/terratest-plan-bucket/threats.txt"
  }
}

filters = {
  archive-low-severity = {
    action = "ARCHIVE"
    criteria = [
      {
        field     = "severity"
        less_than = "4"
      }
    ]
  }
}
