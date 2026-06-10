prefix_lists = {
  corp = {
    name        = "terratest-corp-cidrs"
    max_entries = 10
    cidr_list = [
      { cidr = "10.0.0.0/16", description = "corp network" },
      { cidr = "10.1.0.0/16" },
    ]
  }
}
