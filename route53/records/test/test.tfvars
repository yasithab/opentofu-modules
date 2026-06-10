zone_id = "Z0123456789ABCDEFGHIJ"

records = [
  {
    name    = "www"
    type    = "A"
    ttl     = 300
    records = ["10.0.0.10"]
  },
  {
    name = "app"
    type = "A"
    alias = {
      name    = "d-1234567890.execute-api.us-east-1.amazonaws.com"
      zone_id = "Z1UJRXOUMOOFQ8"
    }
  },
]
