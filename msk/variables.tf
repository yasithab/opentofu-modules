variable "enabled" {
  description = "Controls if MSK cluster and associated resources are created"
  type        = bool
  default     = true
}


variable "name" {
  description = "Name of the MSK cluster"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Cluster Configuration
################################################################################

variable "kafka_version" {
  description = "Version of Apache Kafka to deploy (e.g., '3.6.0')"
  type        = string
  default     = "3.6.0"
}

variable "number_of_broker_nodes" {
  description = "Total number of broker nodes across all AZs. Must be a multiple of the number of AZs"
  type        = number
  default     = 3
}

variable "serverless_enabled" {
  description = "Whether to create a serverless MSK cluster instead of a provisioned one"
  type        = bool
  default     = false
}

################################################################################
# Broker Node Group
################################################################################

variable "broker_instance_type" {
  description = "EC2 instance type for the Kafka broker nodes"
  type        = string
  default     = "kafka.m5.large"
}

variable "broker_subnets" {
  description = "List of subnet IDs for the broker nodes. Must be in at least 2 AZs"
  type        = list(string)
  default     = []
}

variable "broker_security_groups" {
  description = "List of security group IDs to associate with the broker ENIs"
  type        = list(string)
  default     = []
}

variable "broker_ebs_volume_size" {
  description = "Size in GiB of the EBS volume for each broker node"
  type        = number
  default     = 100
}

variable "broker_ebs_provisioned_throughput" {
  description = "Provisioned throughput configuration for EBS volumes. Object with 'enabled' (bool) and 'volume_throughput' (number in MiB/s)"
  type = object({
    enabled           = optional(bool, true)
    volume_throughput = optional(number)
  })
  default = null
}

variable "broker_az_distribution" {
  description = "Distribution of broker nodes across AZs. Currently only DEFAULT is supported"
  type        = string
  default     = "DEFAULT"
}

variable "broker_public_access_type" {
  description = "Public access type for the cluster. Valid values: DISABLED, SERVICE_PROVIDED_EIPS"
  type        = string
  default     = null
}

variable "broker_vpc_connectivity" {
  description = "VPC connectivity configuration for multi-VPC private connectivity"
  type        = any
  default     = {}
}

################################################################################
# Encryption
################################################################################

variable "encryption_at_rest_kms_key_arn" {
  description = "KMS key ARN for encrypting data at rest. Uses AWS managed key if not specified"
  type        = string
  default     = null
}

variable "encryption_in_transit_client_broker" {
  description = "Encryption setting for data in transit between clients and brokers. Valid values: TLS, TLS_PLAINTEXT, PLAINTEXT"
  type        = string
  default     = "TLS"

  validation {
    condition     = contains(["TLS", "TLS_PLAINTEXT", "PLAINTEXT"], var.encryption_in_transit_client_broker)
    error_message = "encryption_in_transit_client_broker must be TLS, TLS_PLAINTEXT, or PLAINTEXT."
  }
}

variable "encryption_in_transit_in_cluster" {
  description = "Whether data communication between brokers is encrypted"
  type        = bool
  default     = true
}

################################################################################
# Client Authentication
################################################################################

variable "client_authentication_enabled" {
  description = "Whether to enable client authentication configuration"
  type        = bool
  default     = true
}

variable "client_authentication_unauthenticated" {
  description = "Whether to allow unauthenticated access"
  type        = bool
  default     = false
}

variable "client_authentication_sasl_iam" {
  description = "Whether IAM authentication is enabled for the cluster"
  type        = bool
  default     = true
}

variable "client_authentication_sasl_scram" {
  description = "Whether SASL/SCRAM authentication is enabled for the cluster"
  type        = bool
  default     = false
}

variable "client_authentication_tls_certificate_authority_arns" {
  description = "List of ACM Private CA ARNs for TLS client authentication"
  type        = list(string)
  default     = []
}

################################################################################
# MSK Configuration
################################################################################

variable "configuration_description" {
  description = "Description of the MSK configuration"
  type        = string
  default     = "MSK cluster configuration managed by OpenTofu"
}

variable "server_properties" {
  description = "Contents of the server.properties file for Kafka broker configuration"
  type        = string
  default     = null
}

################################################################################
# Monitoring
################################################################################

variable "enhanced_monitoring" {
  description = "Monitoring level for the MSK cluster. Valid values: DEFAULT, PER_BROKER, PER_TOPIC_PER_BROKER, PER_TOPIC_PER_PARTITION"
  type        = string
  default     = "PER_BROKER"

  validation {
    condition     = contains(["DEFAULT", "PER_BROKER", "PER_TOPIC_PER_BROKER", "PER_TOPIC_PER_PARTITION"], var.enhanced_monitoring)
    error_message = "enhanced_monitoring must be DEFAULT, PER_BROKER, PER_TOPIC_PER_BROKER, or PER_TOPIC_PER_PARTITION."
  }
}

variable "prometheus_jmx_exporter_enabled" {
  description = "Whether to enable Prometheus JMX Exporter for open monitoring"
  type        = bool
  default     = true
}

variable "prometheus_node_exporter_enabled" {
  description = "Whether to enable Prometheus Node Exporter for open monitoring"
  type        = bool
  default     = true
}

################################################################################
# Logging
################################################################################

variable "logging_enabled" {
  description = "Whether to enable broker log delivery configuration"
  type        = bool
  default     = false
}

variable "cloudwatch_log_group" {
  description = "CloudWatch Log Group name for broker logs"
  type        = string
  default     = null
}

variable "firehose_delivery_stream" {
  description = "Kinesis Data Firehose delivery stream name for broker logs"
  type        = string
  default     = null
}

variable "s3_logs_bucket" {
  description = "S3 bucket name for broker logs"
  type        = string
  default     = null
}

variable "s3_logs_prefix" {
  description = "S3 key prefix for broker logs"
  type        = string
  default     = null
}

################################################################################
# Serverless
################################################################################

variable "serverless_vpc_configs" {
  description = "List of VPC configurations for the serverless cluster. Each item requires 'subnet_ids' and optionally 'security_group_ids'"
  type = list(object({
    subnet_ids         = list(string)
    security_group_ids = optional(list(string), [])
  }))
  default = []
}

################################################################################
# SCRAM Secret Association
################################################################################

variable "scram_secret_arns" {
  description = "List of Secrets Manager secret ARNs to associate with the MSK cluster for SASL/SCRAM authentication"
  type        = list(string)
  default     = []
}
