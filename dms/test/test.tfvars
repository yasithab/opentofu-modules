create_repl_instance     = false
create_repl_subnet_group = false
create_iam_roles         = false
create_access_iam_role   = false

endpoints = {
  source = {
    endpoint_id                     = "terratest-source"
    endpoint_type                   = "source"
    engine_name                     = "aurora-postgresql"
    database_name                   = "appdb"
    secrets_manager_arn             = "arn:aws:secretsmanager:us-east-1:123456789012:secret:dms-source-AbCdEf"
    secrets_manager_access_role_arn = "arn:aws:iam::123456789012:role/dms-secrets-access"
    ssl_mode                        = "require"
  }
}
