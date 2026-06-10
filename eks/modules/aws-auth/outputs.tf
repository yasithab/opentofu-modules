output "aws_auth_configmap_name" {
  description = "Name of the aws-auth ConfigMap"
  value       = "aws-auth"
}

output "aws_auth_configmap_data" {
  description = "Map of data applied to the aws-auth ConfigMap (mapRoles, mapUsers and mapAccounts as YAML strings)"
  value       = local.aws_auth_configmap_data
}
