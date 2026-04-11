################################################################################
# Security Group
################################################################################

output "security_group_id" {
  description = "ID of the security group created for the file system"
  value       = try(aws_security_group.this.id, "")
}

output "security_group_arn" {
  description = "ARN of the security group created for the file system"
  value       = try(aws_security_group.this.arn, "")
}

################################################################################
# FSx for Lustre
################################################################################

output "lustre_id" {
  description = "ID of the Lustre file system"
  value       = try(aws_fsx_lustre_file_system.this.id, "")
}

output "lustre_arn" {
  description = "ARN of the Lustre file system"
  value       = try(aws_fsx_lustre_file_system.this.arn, "")
}

output "lustre_dns_name" {
  description = "DNS name of the Lustre file system"
  value       = try(aws_fsx_lustre_file_system.this.dns_name, "")
}

output "lustre_mount_name" {
  description = "Mount name of the Lustre file system"
  value       = try(aws_fsx_lustre_file_system.this.mount_name, "")
}

output "lustre_network_interface_ids" {
  description = "Network interface IDs of the Lustre file system"
  value       = try(aws_fsx_lustre_file_system.this.network_interface_ids, [])
}

output "lustre_owner_id" {
  description = "AWS account ID that owns the Lustre file system"
  value       = try(aws_fsx_lustre_file_system.this.owner_id, "")
}

output "lustre_vpc_id" {
  description = "VPC ID of the Lustre file system"
  value       = try(aws_fsx_lustre_file_system.this.vpc_id, "")
}

output "lustre_data_repository_associations" {
  description = "Map of data repository association attributes"
  value = {
    for k, v in aws_fsx_data_repository_association.this : k => {
      id                   = try(v.id, "")
      arn                  = try(v.arn, "")
      association_id       = try(v.association_id, "")
      data_repository_path = try(v.data_repository_path, "")
      file_system_path     = try(v.file_system_path, "")
    }
  }
}

################################################################################
# FSx for NetApp ONTAP
################################################################################

output "ontap_id" {
  description = "ID of the ONTAP file system"
  value       = try(aws_fsx_ontap_file_system.this.id, "")
}

output "ontap_arn" {
  description = "ARN of the ONTAP file system"
  value       = try(aws_fsx_ontap_file_system.this.arn, "")
}

output "ontap_dns_name" {
  description = "DNS name of the ONTAP file system"
  value       = try(aws_fsx_ontap_file_system.this.dns_name, "")
}

output "ontap_endpoints" {
  description = "Endpoints of the ONTAP file system"
  value       = try(aws_fsx_ontap_file_system.this.endpoints, [])
}

output "ontap_network_interface_ids" {
  description = "Network interface IDs of the ONTAP file system"
  value       = try(aws_fsx_ontap_file_system.this.network_interface_ids, [])
}

output "ontap_owner_id" {
  description = "AWS account ID that owns the ONTAP file system"
  value       = try(aws_fsx_ontap_file_system.this.owner_id, "")
}

output "ontap_vpc_id" {
  description = "VPC ID of the ONTAP file system"
  value       = try(aws_fsx_ontap_file_system.this.vpc_id, "")
}

output "ontap_svm_id" {
  description = "ID of the ONTAP Storage Virtual Machine"
  value       = try(aws_fsx_ontap_storage_virtual_machine.this.id, "")
}

output "ontap_svm_endpoints" {
  description = "Endpoints of the ONTAP Storage Virtual Machine"
  value       = try(aws_fsx_ontap_storage_virtual_machine.this.endpoints, [])
}

output "ontap_volumes" {
  description = "Map of ONTAP volume attributes"
  value = {
    for k, v in aws_fsx_ontap_volume.this : k => {
      id            = try(v.id, "")
      arn           = try(v.arn, "")
      uuid          = try(v.uuid, "")
      junction_path = try(v.junction_path, "")
    }
  }
}

################################################################################
# FSx for OpenZFS
################################################################################

output "openzfs_id" {
  description = "ID of the OpenZFS file system"
  value       = try(aws_fsx_openzfs_file_system.this.id, "")
}

output "openzfs_arn" {
  description = "ARN of the OpenZFS file system"
  value       = try(aws_fsx_openzfs_file_system.this.arn, "")
}

output "openzfs_dns_name" {
  description = "DNS name of the OpenZFS file system"
  value       = try(aws_fsx_openzfs_file_system.this.dns_name, "")
}

output "openzfs_root_volume_id" {
  description = "Root volume ID of the OpenZFS file system"
  value       = try(aws_fsx_openzfs_file_system.this.root_volume_id, "")
}

output "openzfs_network_interface_ids" {
  description = "Network interface IDs of the OpenZFS file system"
  value       = try(aws_fsx_openzfs_file_system.this.network_interface_ids, [])
}

output "openzfs_owner_id" {
  description = "AWS account ID that owns the OpenZFS file system"
  value       = try(aws_fsx_openzfs_file_system.this.owner_id, "")
}

output "openzfs_vpc_id" {
  description = "VPC ID of the OpenZFS file system"
  value       = try(aws_fsx_openzfs_file_system.this.vpc_id, "")
}

output "openzfs_volumes" {
  description = "Map of OpenZFS volume attributes"
  value = {
    for k, v in aws_fsx_openzfs_volume.this : k => {
      id   = try(v.id, "")
      arn  = try(v.arn, "")
      name = try(v.name, "")
    }
  }
}

################################################################################
# FSx for Windows File Server
################################################################################

output "windows_id" {
  description = "ID of the Windows file system"
  value       = try(aws_fsx_windows_file_system.this.id, "")
}

output "windows_arn" {
  description = "ARN of the Windows file system"
  value       = try(aws_fsx_windows_file_system.this.arn, "")
}

output "windows_dns_name" {
  description = "DNS name of the Windows file system"
  value       = try(aws_fsx_windows_file_system.this.dns_name, "")
}

output "windows_preferred_file_server_ip" {
  description = "IP address of the preferred Windows file server"
  value       = try(aws_fsx_windows_file_system.this.preferred_file_server_ip, "")
}

output "windows_remote_administration_endpoint" {
  description = "Remote administration endpoint for the Windows file system"
  value       = try(aws_fsx_windows_file_system.this.remote_administration_endpoint, "")
}

output "windows_network_interface_ids" {
  description = "Network interface IDs of the Windows file system"
  value       = try(aws_fsx_windows_file_system.this.network_interface_ids, [])
}

output "windows_owner_id" {
  description = "AWS account ID that owns the Windows file system"
  value       = try(aws_fsx_windows_file_system.this.owner_id, "")
}

output "windows_vpc_id" {
  description = "VPC ID of the Windows file system"
  value       = try(aws_fsx_windows_file_system.this.vpc_id, "")
}
