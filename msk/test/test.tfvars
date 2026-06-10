name                   = "terratest-plan"
kafka_version          = "3.6.0"
number_of_broker_nodes = 2
broker_instance_type   = "kafka.t3.small"
broker_subnets         = ["subnet-12345678", "subnet-87654321"]

cluster_policy = <<-EOT
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowConsumerAccount",
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::123456789012:root"
        },
        "Action": [
          "kafka:GetBootstrapBrokers",
          "kafka:DescribeCluster",
          "kafka:DescribeClusterV2"
        ],
        "Resource": "*"
      }
    ]
  }
EOT
