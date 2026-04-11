output "cluster_arn" {
  description = "ARN of the MSK cluster"
  value       = try(aws_msk_cluster.this.arn, aws_msk_serverless_cluster.this.arn, "")
}

output "cluster_name" {
  description = "Name of the MSK cluster"
  value       = try(aws_msk_cluster.this.cluster_name, aws_msk_serverless_cluster.this.cluster_name, "")
}

output "bootstrap_brokers" {
  description = "Comma-separated list of one or more hostname:port pairs of Kafka brokers for plaintext connections"
  value       = try(aws_msk_cluster.this.bootstrap_brokers, "")
}

output "bootstrap_brokers_tls" {
  description = "Comma-separated list of one or more hostname:port pairs of Kafka brokers for TLS connections"
  value       = try(aws_msk_cluster.this.bootstrap_brokers_tls, "")
}

output "bootstrap_brokers_sasl_iam" {
  description = "Comma-separated list of one or more hostname:port pairs of Kafka brokers for SASL/IAM connections"
  value       = try(aws_msk_cluster.this.bootstrap_brokers_sasl_iam, "")
}

output "bootstrap_brokers_sasl_scram" {
  description = "Comma-separated list of one or more hostname:port pairs of Kafka brokers for SASL/SCRAM connections"
  value       = try(aws_msk_cluster.this.bootstrap_brokers_sasl_scram, "")
}

output "zookeeper_connect_string" {
  description = "Comma-separated list of one or more hostname:port pairs of Apache Zookeeper nodes"
  value       = try(aws_msk_cluster.this.zookeeper_connect_string, "")
}

output "zookeeper_connect_string_tls" {
  description = "Comma-separated list of one or more hostname:port pairs of Apache Zookeeper nodes for TLS connections"
  value       = try(aws_msk_cluster.this.zookeeper_connect_string_tls, "")
}

output "current_version" {
  description = "Current version of the MSK cluster (used for updates)"
  value       = try(aws_msk_cluster.this.current_version, "")
}

output "configuration_arn" {
  description = "ARN of the MSK configuration"
  value       = try(aws_msk_configuration.this.arn, "")
}

output "configuration_latest_revision" {
  description = "Latest revision of the MSK configuration"
  value       = try(aws_msk_configuration.this.latest_revision, "")
}

output "serverless_cluster_arn" {
  description = "ARN of the MSK serverless cluster"
  value       = try(aws_msk_serverless_cluster.this.arn, "")
}
