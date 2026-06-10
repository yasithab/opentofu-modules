name                         = "terratest.local"
namespace_description        = "Terratest plan namespace"
create_private_dns_namespace = true
vpc_id                       = "vpc-12345678"

services = {
  app = {
    name            = "app"
    description     = "Terratest service"
    dns_ttl         = 10
    dns_record_type = "A"
  }
}
