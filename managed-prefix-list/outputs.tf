################################################################################
# Prefix Lists
################################################################################

output "prefix_list_ids" {
  description = "Map of prefix list names to their IDs"
  value = {
    for name, prefix_list in aws_ec2_managed_prefix_list.this :
    name => prefix_list.id
  }
}

output "prefix_list_arns" {
  description = "Map of prefix list names to their ARNs"
  value = {
    for name, prefix_list in aws_ec2_managed_prefix_list.this :
    name => prefix_list.arn
  }
}

################################################################################
# Resource Access Manager
################################################################################

output "ram_resource_share_arns" {
  description = "Map of prefix list names to their RAM resource share ARNs"
  value = local.enabled && var.enable_ram_share ? {
    for name, share in aws_ram_resource_share.this :
    name => share.arn
  } : {}
}

################################################################################
