locals {
  enabled = var.enabled
  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# MSK Configuration
################################################################################

resource "aws_msk_configuration" "this" {
  name              = "${var.name}-config"
  description       = var.configuration_description
  kafka_versions    = [var.kafka_version]
  server_properties = var.server_properties

  lifecycle {
    enabled = local.enabled && var.server_properties != null
  }
}

################################################################################
# MSK Cluster (Provisioned)
################################################################################

resource "aws_msk_cluster" "this" {
  cluster_name           = var.name
  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.number_of_broker_nodes

  broker_node_group_info {
    instance_type   = var.broker_instance_type
    client_subnets  = var.broker_subnets
    security_groups = var.broker_security_groups

    storage_info {
      ebs_storage_info {
        volume_size = var.broker_ebs_volume_size

        dynamic "provisioned_throughput" {
          for_each = var.broker_ebs_provisioned_throughput != null ? [var.broker_ebs_provisioned_throughput] : []

          content {
            enabled           = try(provisioned_throughput.value.enabled, true)
            volume_throughput = try(provisioned_throughput.value.volume_throughput, null)
          }
        }
      }
    }

    connectivity_info {
      dynamic "public_access" {
        for_each = var.broker_public_access_type != null ? [1] : []

        content {
          type = var.broker_public_access_type
        }
      }

      dynamic "vpc_connectivity" {
        for_each = length(var.broker_vpc_connectivity) > 0 ? [var.broker_vpc_connectivity] : []

        content {
          dynamic "client_authentication" {
            for_each = try([vpc_connectivity.value.client_authentication], [])

            content {
              sasl {
                iam   = try(client_authentication.value.sasl_iam, null)
                scram = try(client_authentication.value.sasl_scram, null)
              }
              tls = try(client_authentication.value.tls, null)
            }
          }
        }
      }
    }

    az_distribution = var.broker_az_distribution
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = var.encryption_at_rest_kms_key_arn

    encryption_in_transit {
      client_broker = var.encryption_in_transit_client_broker
      in_cluster    = var.encryption_in_transit_in_cluster
    }
  }

  dynamic "client_authentication" {
    for_each = var.client_authentication_enabled ? [1] : []

    content {
      unauthenticated = var.client_authentication_unauthenticated

      dynamic "sasl" {
        for_each = var.client_authentication_sasl_iam || var.client_authentication_sasl_scram ? [1] : []

        content {
          iam   = var.client_authentication_sasl_iam
          scram = var.client_authentication_sasl_scram
        }
      }

      dynamic "tls" {
        for_each = length(var.client_authentication_tls_certificate_authority_arns) > 0 ? [1] : []

        content {
          certificate_authority_arns = var.client_authentication_tls_certificate_authority_arns
        }
      }
    }
  }

  dynamic "configuration_info" {
    for_each = var.server_properties != null ? [1] : []
    content {
      arn      = aws_msk_configuration.this.arn
      revision = aws_msk_configuration.this.latest_revision
    }
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = var.prometheus_jmx_exporter_enabled
      }
      node_exporter {
        enabled_in_broker = var.prometheus_node_exporter_enabled
      }
    }
  }

  dynamic "logging_info" {
    for_each = var.logging_enabled ? [1] : []

    content {
      broker_logs {
        dynamic "cloudwatch_logs" {
          for_each = var.cloudwatch_log_group != null ? [1] : []

          content {
            enabled   = true
            log_group = var.cloudwatch_log_group
          }
        }

        dynamic "firehose" {
          for_each = var.firehose_delivery_stream != null ? [1] : []

          content {
            enabled         = true
            delivery_stream = var.firehose_delivery_stream
          }
        }

        dynamic "s3" {
          for_each = var.s3_logs_bucket != null ? [1] : []

          content {
            enabled = true
            bucket  = var.s3_logs_bucket
            prefix  = var.s3_logs_prefix
          }
        }
      }
    }
  }

  enhanced_monitoring = var.enhanced_monitoring

  tags = merge(local.tags, { Name = var.name })

  lifecycle {
    enabled = local.enabled && !var.serverless_enabled
  }
}

################################################################################
# MSK Serverless Cluster
################################################################################

resource "aws_msk_serverless_cluster" "this" {
  cluster_name = var.name

  dynamic "vpc_config" {
    for_each = var.serverless_vpc_configs

    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = try(vpc_config.value.security_group_ids, [])
    }
  }

  client_authentication {
    sasl {
      iam {
        enabled = true
      }
    }
  }

  tags = merge(local.tags, { Name = var.name })

  lifecycle {
    enabled = local.enabled && var.serverless_enabled
  }
}

################################################################################
# SCRAM Secret Association
################################################################################

resource "aws_msk_scram_secret_association" "this" {
  cluster_arn     = aws_msk_cluster.this.arn
  secret_arn_list = var.scram_secret_arns

  lifecycle {
    enabled = local.enabled && !var.serverless_enabled && length(var.scram_secret_arns) > 0
  }
}
