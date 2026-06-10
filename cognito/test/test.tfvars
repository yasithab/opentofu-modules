name   = "terratest-plan"
domain = "terratest-plan"

resource_servers = {
  orders-api = {
    identifier = "https://orders.terratest-plan.example.com"
    scopes = [
      {
        scope_name        = "read"
        scope_description = "Read access to the orders API"
      },
      {
        scope_name        = "write"
        scope_description = "Write access to the orders API"
      },
    ]
  }
}

user_groups = {
  admins = {
    description = "Administrators"
    precedence  = 1
  }
  readers = {
    description = "Read-only users"
    precedence  = 10
  }
}
