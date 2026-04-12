broker_name        = "terratest-plan"
engine_type        = "RabbitMQ"
engine_version     = "3.13"
host_instance_type = "mq.t3.micro"
subnet_ids         = ["subnet-12345678"]
users = [
  {
    username = "admin"
    password = "TerratestPlan123!"
  }
]
