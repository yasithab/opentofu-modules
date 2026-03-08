output "customer_gateway_id" {
  description = "The ID of the Customer Gateway"
  value       = try(aws_customer_gateway.this.id, null)
}

output "customer_gateway_arn" {
  description = "The ARN of the Customer Gateway"
  value       = try(aws_customer_gateway.this.arn, null)
}

output "vpn_gateway_id" {
  description = "The ID of the VPN Gateway"
  value       = try(aws_vpn_gateway.this.id, null)
}

output "vpn_connection_id" {
  description = "The ID of the VPN Connection"
  value       = try(aws_vpn_connection.this.id, null)
}

output "vpn_connection_arn" {
  description = "Amazon Resource Name (ARN) value of the connection"
  value       = try(aws_vpn_connection.this.arn, null)
}

output "vpn_connection_customer_gateway_configuration" {
  description = "The configuration information for the VPN connection's customer gateway (in the native XML format)"
  sensitive   = true
  value       = try(aws_vpn_connection.this.customer_gateway_configuration, null)
}

output "vpn_connection_tunnel1_address" {
  description = "The public IP address of the first VPN tunnel"
  value       = try(aws_vpn_connection.this.tunnel1_address, null)
}

output "vpn_connection_tunnel2_address" {
  description = "The public IP address of the second VPN tunnel"
  value       = try(aws_vpn_connection.this.tunnel2_address, null)
}

output "vpn_connection_tunnel1_cgw_inside_address" {
  description = "The RFC 6890 link-local address of the first VPN tunnel (Customer Gateway Side)"
  value       = try(aws_vpn_connection.this.tunnel1_cgw_inside_address, null)
}

output "vpn_connection_tunnel2_cgw_inside_address" {
  description = "The RFC 6890 link-local address of the second VPN tunnel (Customer Gateway Side)"
  value       = try(aws_vpn_connection.this.tunnel2_cgw_inside_address, null)
}

output "vpn_connection_tunnel1_vgw_inside_address" {
  description = "The RFC 6890 link-local address of the first VPN tunnel (VPN Gateway Side)"
  value       = try(aws_vpn_connection.this.tunnel1_vgw_inside_address, null)
}

output "vpn_connection_tunnel2_vgw_inside_address" {
  description = "The RFC 6890 link-local address of the second VPN tunnel (VPN Gateway Side)"
  value       = try(aws_vpn_connection.this.tunnel2_vgw_inside_address, null)
}

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group for VPN connection logs"
  value       = try(aws_cloudwatch_log_group.this.arn, null)
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch Log Group for VPN connection logs"
  value       = try(aws_cloudwatch_log_group.this.name, null)
}
