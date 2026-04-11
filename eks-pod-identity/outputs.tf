################################################################################
# IAM Role
################################################################################

output "role_arn" {
  description = "ARN of the IAM role"
  value       = try(aws_iam_role.this.arn, "")
}

output "role_name" {
  description = "Name of the IAM role"
  value       = try(aws_iam_role.this.name, "")
}

output "role_id" {
  description = "ID of the IAM role"
  value       = try(aws_iam_role.this.id, "")
}

output "role_unique_id" {
  description = "Unique ID of the IAM role"
  value       = try(aws_iam_role.this.unique_id, "")
}

output "role_path" {
  description = "Path of the IAM role"
  value       = try(aws_iam_role.this.path, "")
}

output "role_create_date" {
  description = "Creation date of the IAM role"
  value       = try(aws_iam_role.this.create_date, "")
}

################################################################################
# Pod Identity Associations
################################################################################

output "associations" {
  description = "Map of pod identity association attributes"
  value = {
    for k, v in aws_eks_pod_identity_association.this : k => {
      association_arn = try(v.association_arn, "")
      association_id  = try(v.association_id, "")
      cluster_name    = try(v.cluster_name, "")
      namespace       = try(v.namespace, "")
      service_account = try(v.service_account, "")
      role_arn        = try(v.role_arn, "")
    }
  }
}
