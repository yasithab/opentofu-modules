create_cluster           = false
create_replication_group = true

name        = "terratest-plan"
description = "Terratest plan replication group"

engine         = "redis"
engine_version = "7.1"
node_type      = "cache.t4g.micro"

cluster_mode_enabled = false
num_cache_clusters   = 2

transit_encryption_enabled = true
at_rest_encryption_enabled = true

create_parameter_group = false
create_subnet_group    = false
create_security_group  = false
