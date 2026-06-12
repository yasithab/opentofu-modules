cluster_identifier = "terratest-plan"
node_type          = "dc2.large"
master_username    = "admin"
logging = {
  log_destination_type = "cloudwatch"
  log_exports          = ["connectionlog"]
}
port = 5439
