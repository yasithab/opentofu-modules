# Must fail: provisioned MSK cluster requires broker_subnets with >= 2 subnet IDs.
name                   = "terratest-plan"
kafka_version          = "3.6.0"
number_of_broker_nodes = 2
broker_instance_type   = "kafka.t3.small"
broker_subnets         = ["subnet-12345678"]
