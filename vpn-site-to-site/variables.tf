variable "customer_gateway_bgp_asn" {
  description = "(Optional) The ASN of your customer gateway device. Valid values are in the range 1-2,147,483,647. Conflicts with bgp_asn_extended."
  type        = number
  default     = null
}

variable "customer_gateway_ip_address" {
  description = "Specify the internet-routable IP address for your gateway's external interface; the address must be static and may be behind a device performing network address translation (NAT)."
  type        = string
  default     = null
}

variable "customer_gateway_type" {
  description = "(Required) The type of customer gateway. The only type AWS supports at this time is \"ipsec.1\"."
  type        = string
  default     = "ipsec.1"
}

variable "customer_gateway_device_name" {
  description = "(Optional) Enter a name for the customer gateway device."
  type        = string
  default     = null
}

variable "customer_gateway_bgp_asn_extended" {
  description = "(Optional, Forces new resource) The gateway's Border Gateway Protocol (BGP) Autonomous System Number (ASN). Valid values are from 2147483648 to 4294967295. Conflicts with bgp_asn."
  type        = number
  default     = null
}

variable "customer_gateway_certificate_arn" {
  description = "(Optional) The ARN of a private certificate provisioned in AWS Certificate Manager (ACM)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "enabled" {
  description = "Controls if resources should be created."
  type        = bool
  default     = true
}

variable "virtual_private_gateway_vpc_id" {
  description = "(Optional) The VPC to attach to the virtual private gateway. Required when not using a Transit Gateway."
  type        = string
  default     = null
}

variable "virtual_private_gateway_amazon_side_asn" {
  description = "(Optional) The Autonomous System Number (ASN) for the Amazon side of the gateway. If you don't specify an ASN, the virtual private gateway is created with the default ASN."
  type        = number
  default     = null
}

variable "virtual_private_gateway_availability_zone" {
  description = "(Optional) The Availability Zone for the virtual private gateway."
  type        = string
  default     = null
}

variable "vpn_connection_transit_gateway_id" {
  description = "(Optional) The ID of the EC2 Transit Gateway."
  type        = string
  default     = null
}

variable "route_propagation_route_table_ids" {
  description = "(Optional)The IDs of the route tables for which routes from the Virtual Private Gateway will be propagated"
  type        = list(string)
  default     = []
}

variable "vpn_connection_cloudwatch_log_group_name" {
  description = "(Optional, Forces new resource) The name of the log group. If omitted, Terraform will assign a random, unique name."
  type        = string
  default     = null
}

variable "vpn_connection_cloudwatch_log_group_name_prefix" {
  description = "(Optional, Forces new resource) Creates a unique name beginning with the specified prefix. Conflicts with name."
  type        = string
  default     = null
}

variable "vpn_connection_cloudwatch_log_group_skip_destroy" {
  description = "(Optional) Set to true if you do not wish the log group (and any logs it may contain) to be deleted at destroy time, and instead just remove the log group from the Terraform state."
  type        = bool
  default     = true
}

variable "vpn_connection_cloudwatch_log_retention_in_days" {
  description = "(Optional) Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653, and 0. If you select 0, the events in the log group are always retained and never expire."
  type        = number
  default     = 30
}

variable "vpn_connection_cloudwatch_log_group_kms_key_id" {
  description = "(Optional) The ARN of the KMS Key to use when encrypting log data. Please note, after the AWS KMS CMK is disassociated from the log group, AWS CloudWatch Logs stops encrypting newly ingested data for the log group. All previously ingested data remains encrypted, and AWS CloudWatch Logs requires permissions for the CMK whenever the encrypted data is requested."
  type        = string
  default     = null
}

variable "vpn_connection_cloudwatch_log_group_class" {
  description = "(Optional) Specifies the log class of the log group. Possible values are: STANDARD or INFREQUENT_ACCESS."
  type        = string
  default     = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "INFREQUENT_ACCESS"], var.vpn_connection_cloudwatch_log_group_class)
    error_message = "Log group class must be one of: STANDARD, INFREQUENT_ACCESS."
  }
}

variable "vpn_connection_cloudwatch_log_group_deletion_protection_enabled" {
  description = "(Optional) Whether to enable deletion protection for the CloudWatch log group."
  type        = bool
  default     = false
}

variable "vpn_connection_preshared_key_storage" {
  description = "(Optional) Storage location for VPN tunnel pre-shared keys. Valid values are Standard or SecretsManager."
  type        = string
  default     = null
  validation {
    condition     = var.vpn_connection_preshared_key_storage == null || contains(["Standard", "SecretsManager"], var.vpn_connection_preshared_key_storage)
    error_message = "preshared_key_storage must be Standard or SecretsManager."
  }
}

variable "vpn_connection_tunnel_bandwidth" {
  description = "(Optional) The bandwidth of the VPN tunnels. Valid values are standard or large."
  type        = string
  default     = null
  validation {
    condition     = var.vpn_connection_tunnel_bandwidth == null || contains(["standard", "large"], var.vpn_connection_tunnel_bandwidth)
    error_message = "tunnel_bandwidth must be standard or large."
  }
}

variable "vpn_connection_static_routes_only" {
  description = "(Optional, Default false) Whether the VPN connection uses static routes exclusively. Static routes must be used for devices that don't support BGP."
  type        = bool
  default     = false
}

variable "vpn_connection_enable_acceleration" {
  description = "(Optional, Default false) Indicate whether to enable acceleration for the VPN connection. Supports only EC2 Transit Gateway."
  type        = bool
  default     = false
}

variable "vpn_connection_local_ipv4_network_cidr" {
  description = "(Optional, Default 0.0.0.0/0) The IPv4 CIDR on the customer gateway (on-premises) side of the VPN connection."
  type        = string
  default     = null
}

variable "vpn_connection_local_ipv6_network_cidr" {
  description = "(Optional, Default ::/0) The IPv6 CIDR on the customer gateway (on-premises) side of the VPN connection."
  type        = string
  default     = null
}

variable "vpn_connection_outside_ip_address_type" {
  description = "(Optional, Default PublicIpv4) Indicates if a Public S2S VPN or Private S2S VPN over AWS Direct Connect. Valid values are PublicIpv4 | PrivateIpv4"
  type        = string
  default     = "PublicIpv4"
  validation {
    condition     = can(regex("^(PublicIpv4|PrivateIpv4)$", var.vpn_connection_outside_ip_address_type))
    error_message = "Invalid input, options: \"PublicIpv4\", \"PrivateIpv4\"."
  }
}

variable "vpn_connection_remote_ipv4_network_cidr" {
  description = "(Optional, Default 0.0.0.0/0) The IPv4 CIDR on the AWS side of the VPN connection."
  type        = string
  default     = null
}

variable "vpn_connection_remote_ipv6_network_cidr" {
  description = "(Optional, Default ::/0) The IPv6 CIDR on the customer gateway (on-premises) side of the VPN connection."
  type        = string
  default     = null
}

variable "vpn_connection_transport_transit_gateway_attachment_id" {
  description = "(Required when outside_ip_address_type is set to PrivateIpv4). The attachment ID of the Transit Gateway attachment to Direct Connect Gateway. The ID is obtained through a data source only."
  type        = string
  default     = null
}

variable "vpn_connection_tunnel_inside_ip_version" {
  description = "(Optional, Default ipv4) Indicate whether the VPN tunnels process IPv4 or IPv6 traffic. Valid values are ipv4 | ipv6. ipv6 Supports only EC2 Transit Gateway."
  type        = string
  default     = "ipv4"
  validation {
    condition     = can(regex("^(ipv4|ipv6)$", var.vpn_connection_tunnel_inside_ip_version))
    error_message = "Invalid input, options: \"ipv4\", \"ipv6\"."
  }
}

variable "vpn_connection_tunnel1_inside_cidr" {
  description = " (Optional) The CIDR block of the inside IP addresses for the first VPN tunnel. Valid value is a size /30 CIDR block from the 169.254.0.0/16 range."
  type        = string
  default     = null
}

variable "vpn_connection_tunnel2_inside_cidr" {
  description = "(Optional) The CIDR block of the inside IP addresses for the second VPN tunnel. Valid value is a size /30 CIDR block from the 169.254.0.0/16 range."
  type        = string
  default     = null
}

variable "vpn_connection_tunnel1_inside_ipv6_cidr" {
  description = "(Optional) The range of inside IPv6 addresses for the first VPN tunnel. Supports only EC2 Transit Gateway. Valid value is a size /126 CIDR block from the local fd00::/8 range."
  type        = string
  default     = null
}

variable "vpn_connection_tunnel2_inside_ipv6_cidr" {
  description = "(Optional) The range of inside IPv6 addresses for the second VPN tunnel. Supports only EC2 Transit Gateway. Valid value is a size /126 CIDR block from the local fd00::/8 range."
  type        = string
  default     = null
}

variable "vpn_connection_tunnel1_preshared_key" {
  description = "(Optional) The preshared key of the first VPN tunnel. The preshared key must be between 8 and 64 characters in length and cannot start with zero(0). Allowed characters are alphanumeric characters, periods(.) and underscores(_)."
  type        = string
  default     = null
  sensitive   = true
}

variable "vpn_connection_tunnel2_preshared_key" {
  description = " (Optional) The preshared key of the second VPN tunnel. The preshared key must be between 8 and 64 characters in length and cannot start with zero(0). Allowed characters are alphanumeric characters, periods(.) and underscores(_)."
  type        = string
  default     = null
  sensitive   = true
}

variable "vpn_connection_tunnel1_dpd_timeout_action" {
  description = "(Optional, Default clear) The action to take after DPD timeout occurs for the first VPN tunnel. Specify restart to restart the IKE initiation. Specify clear to end the IKE session. Valid values are clear | none | restart."
  type        = string
  default     = "restart"
  validation {
    condition     = can(regex("^(clear|none|restart)$", var.vpn_connection_tunnel1_dpd_timeout_action))
    error_message = "Invalid input, options: \"clear\", \"none\", \"restart\"."
  }
}

variable "vpn_connection_tunnel2_dpd_timeout_action" {
  description = "(Optional, Default clear) The action to take after DPD timeout occurs for the second VPN tunnel. Specify restart to restart the IKE initiation. Specify clear to end the IKE session. Valid values are clear | none | restart."
  type        = string
  default     = "restart"
  validation {
    condition     = can(regex("^(clear|none|restart)$", var.vpn_connection_tunnel2_dpd_timeout_action))
    error_message = "Invalid input, options: \"clear\", \"none\", \"restart\"."
  }
}

variable "vpn_connection_tunnel1_dpd_timeout_seconds" {
  description = "(Optional, Default 30) The number of seconds after which a DPD timeout occurs for the second VPN tunnel. Valid value is equal or higher than 30."
  type        = number
  default     = 30
}

variable "vpn_connection_tunnel2_dpd_timeout_seconds" {
  description = "(Optional, Default 30) The number of seconds after which a DPD timeout occurs for the second VPN tunnel. Valid value is equal or higher than 30."
  type        = number
  default     = 30
}

variable "vpn_connection_tunnel1_ike_versions" {
  description = "(Optional) The IKE versions that are permitted for the first VPN tunnel. Valid values are ikev1 | ikev2."
  type        = set(string)
  default     = []
  validation {
    condition     = length(var.vpn_connection_tunnel1_ike_versions) == 0 || can([for i in var.vpn_connection_tunnel1_ike_versions : regex("^(ikev1|ikev2)$", i)])
    error_message = "Invalid input, options: \"ikev1\",\"ikev2\"."
  }
}

variable "vpn_connection_tunnel2_ike_versions" {
  description = "(Optional) The IKE versions that are permitted for the second VPN tunnel. Valid values are ikev1 | ikev2."
  type        = set(string)
  default     = []
  validation {
    condition     = length(var.vpn_connection_tunnel2_ike_versions) == 0 || can([for i in var.vpn_connection_tunnel2_ike_versions : regex("^(ikev1|ikev2)$", i)])
    error_message = "Invalid input, options: \"ikev1\",\"ikev2\"."
  }
}

variable "vpn_connection_tunnel1_log_enabled" {
  description = "(Optional) Enable logs for VPN tunnel activity."
  type        = bool
  default     = false
}

variable "vpn_connection_tunnel1_log_output_format" {
  description = "(Optional) Enable logs for VPN tunnel activity."
  type        = string
  default     = "json"
  validation {
    condition     = can(regex("^(json|text)$", var.vpn_connection_tunnel1_log_output_format))
    error_message = "Invalid input, options: \"json\",\"text\"."
  }
}

variable "vpn_connection_tunnel2_log_enabled" {
  description = "(Optional) Enable logs for VPN tunnel activity."
  type        = bool
  default     = false
}

variable "vpn_connection_tunnel2_log_output_format" {
  description = "(Optional) Enable logs for VPN tunnel activity."
  type        = string
  default     = "json"
  validation {
    condition     = can(regex("^(json|text)$", var.vpn_connection_tunnel2_log_output_format))
    error_message = "Invalid input, options: \"json\",\"text\"."
  }
}

variable "vpn_connection_tunnel1_phase1_dh_group_numbers" {
  description = "(Optional) List of one or more Diffie-Hellman group numbers that are permitted for the first VPN tunnel for phase 1 IKE negotiations. Valid values are 2 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24."
  type        = set(number)
  default     = [2, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel1_phase1_dh_group_numbers : regex("^(2|14|15|16|17|18|19|20|21|22|23|24)$", i)])
    error_message = "Invalid input, options: \"2|14|15|16|17|18|19|20|21|22|23|24\"."
  }
}

variable "vpn_connection_tunnel2_phase1_dh_group_numbers" {
  description = "(Optional) List of one or more Diffie-Hellman group numbers that are permitted for the second VPN tunnel for phase 1 IKE negotiations. Valid values are 2 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24."
  type        = set(number)
  default     = [2, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel2_phase1_dh_group_numbers : regex("^(2|14|15|16|17|18|19|20|21|22|23|24)$", i)])
    error_message = "Invalid input, options: \"2|14|15|16|17|18|19|20|21|22|23|24\"."
  }
}

variable "vpn_connection_tunnel1_phase1_encryption_algorithms" {
  description = "(Optional) List of one or more encryption algorithms that are permitted for the first VPN tunnel for phase 1 IKE negotiations. Valid values are AES128 | AES256 | AES128-GCM-16 | AES256-GCM-16."
  type        = set(string)
  default     = ["AES128", "AES256", "AES128-GCM-16", "AES256-GCM-16"]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel1_phase1_encryption_algorithms : regex("^(AES128|AES256|AES128-GCM-16|AES256-GCM-16)$", i)])
    error_message = "Invalid input, options: \"AES128|AES256|AES128-GCM-16|AES256-GCM-16\"."
  }
}

variable "vpn_connection_tunnel2_phase1_encryption_algorithms" {
  description = "(Optional) List of one or more encryption algorithms that are permitted for the second VPN tunnel for phase 1 IKE negotiations. Valid values are AES128 | AES256 | AES128-GCM-16 | AES256-GCM-16."
  type        = set(string)
  default     = ["AES128", "AES256", "AES128-GCM-16", "AES256-GCM-16"]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel2_phase1_encryption_algorithms : regex("^(AES128|AES256|AES128-GCM-16|AES256-GCM-16)$", i)])
    error_message = "Invalid input, options: \"AES128|AES256|AES128-GCM-16|AES256-GCM-16\"."
  }
}

variable "vpn_connection_tunnel1_phase1_integrity_algorithms" {
  description = "(Optional) One or more integrity algorithms that are permitted for the first VPN tunnel for phase 1 IKE negotiations. Valid values are SHA1 | SHA2-256 | SHA2-384 | SHA2-512."
  type        = set(string)
  default     = ["SHA1", "SHA2-256", "SHA2-384", "SHA2-512"]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel1_phase1_integrity_algorithms : regex("^(SHA1|SHA2-256|SHA2-384|SHA2-512)$", i)])
    error_message = "Invalid input, options: \"SHA1|SHA2-256|SHA2-384|SHA2-512\"."
  }
}

variable "vpn_connection_tunnel2_phase1_integrity_algorithms" {
  description = "(Optional) One or more integrity algorithms that are permitted for the second VPN tunnel for phase 1 IKE negotiations. Valid values are SHA1 | SHA2-256 | SHA2-384 | SHA2-512."
  type        = set(string)
  default     = ["SHA1", "SHA2-256", "SHA2-384", "SHA2-512"]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel2_phase1_integrity_algorithms : regex("^(SHA1|SHA2-256|SHA2-384|SHA2-512)$", i)])
    error_message = "Invalid input, options: \"SHA1|SHA2-256|SHA2-384|SHA2-512\"."
  }
}

variable "vpn_connection_tunnel1_phase1_lifetime_seconds" {
  description = " (Optional, Default 28800) The lifetime for phase 1 of the IKE negotiation for the first VPN tunnel, in seconds. Valid value is between 900 and 28800."
  type        = number
  default     = 28800
  validation {
    condition     = var.vpn_connection_tunnel1_phase1_lifetime_seconds <= 28800 && var.vpn_connection_tunnel1_phase1_lifetime_seconds >= 900
    error_message = "Invalid input, options: Valid value is between 900 and 28800."
  }
}

variable "vpn_connection_tunnel2_phase1_lifetime_seconds" {
  description = "(Optional, Default 28800) The lifetime for phase 1 of the IKE negotiation for the second VPN tunnel, in seconds. Valid value is between 900 and 28800."
  type        = number
  default     = 28800
  validation {
    condition     = var.vpn_connection_tunnel2_phase1_lifetime_seconds <= 28800 && var.vpn_connection_tunnel2_phase1_lifetime_seconds >= 900
    error_message = "Invalid input, options: Valid value is between 900 and 28800."
  }
}

variable "vpn_connection_tunnel2_phase2_dh_group_numbers" {
  description = "(Optional) List of one or more Diffie-Hellman group numbers that are permitted for the second VPN tunnel for phase 2 IKE negotiations. Valid values are 2 | 5 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24."
  type        = set(number)
  default     = [2, 5, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel2_phase2_dh_group_numbers : regex("^(2|5|14|15|16|17|18|19|20|21|22|23|24)$", i)])
    error_message = "Invalid input, options: \"2|5|14|15|16|17|18|19|20|21|22|23|24\"."
  }
}

variable "vpn_connection_tunnel1_phase2_dh_group_numbers" {
  description = "(Optional) List of one or more Diffie-Hellman group numbers that are permitted for the first VPN tunnel for phase 2 IKE negotiations. Valid values are 2 | 5 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24."
  type        = set(number)
  default     = [2, 5, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel1_phase2_dh_group_numbers : regex("^(2|5|14|15|16|17|18|19|20|21|22|23|24)$", i)])
    error_message = "Invalid input, options: \"2|5|14|15|16|17|18|19|20|21|22|23|24\"."
  }
}

variable "vpn_connection_tunnel1_phase2_encryption_algorithms" {
  description = " (Optional) List of one or more encryption algorithms that are permitted for the first VPN tunnel for phase 2 IKE negotiations. Valid values are AES128 | AES256 | AES128-GCM-16 | AES256-GCM-16."
  type        = list(string)
  default     = ["AES128", "AES256", "AES128-GCM-16", "AES256-GCM-16"]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel1_phase2_encryption_algorithms : regex("^(AES128|AES256|AES128-GCM-16|AES256-GCM-16)$", i)])
    error_message = "Invalid input, options: \"AES128|AES256|AES128-GCM-16|AES256-GCM-16\"."
  }
}

variable "vpn_connection_tunnel2_phase2_encryption_algorithms" {
  description = "(Optional) List of one or more encryption algorithms that are permitted for the second VPN tunnel for phase 2 IKE negotiations. Valid values are AES128 | AES256 | AES128-GCM-16 | AES256-GCM-16."
  type        = list(string)
  default     = ["AES128", "AES256", "AES128-GCM-16", "AES256-GCM-16"]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel2_phase2_encryption_algorithms : regex("^(AES128|AES256|AES128-GCM-16|AES256-GCM-16)$", i)])
    error_message = "Invalid input, options: \"AES128|AES256|AES128-GCM-16|AES256-GCM-16\"."
  }
}

variable "vpn_connection_tunnel1_phase2_integrity_algorithms" {
  description = "(Optional) List of one or more integrity algorithms that are permitted for the first VPN tunnel for phase 2 IKE negotiations. Valid values are SHA1 | SHA2-256 | SHA2-384 | SHA2-512."
  type        = list(string)
  default     = ["SHA1", "SHA2-256", "SHA2-384", "SHA2-512"]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel1_phase2_integrity_algorithms : regex("^(SHA1|SHA2-256|SHA2-384|SHA2-512)$", i)])
    error_message = "Invalid input, options: \"SHA1|SHA2-256|SHA2-384|SHA2-512\"."
  }
}

variable "vpn_connection_tunnel2_phase2_integrity_algorithms" {
  description = "(Optional) List of one or more integrity algorithms that are permitted for the second VPN tunnel for phase 2 IKE negotiations. Valid values are SHA1 | SHA2-256 | SHA2-384 | SHA2-512."
  type        = list(string)
  default     = ["SHA1", "SHA2-256", "SHA2-384", "SHA2-512"]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel2_phase2_integrity_algorithms : regex("^(SHA1|SHA2-256|SHA2-384|SHA2-512)$", i)])
    error_message = "Invalid input, options: \"SHA1|SHA2-256|SHA2-384|SHA2-512\"."
  }
}

variable "vpn_connection_tunnel1_phase2_lifetime_seconds" {
  description = " (Optional, Default 3600) The lifetime for phase 2 of the IKE negotiation for the first VPN tunnel, in seconds. Valid value is between 900 and 3600."
  type        = number
  default     = 3600
  validation {
    condition     = var.vpn_connection_tunnel1_phase2_lifetime_seconds <= 3600 && var.vpn_connection_tunnel1_phase2_lifetime_seconds >= 900 || var.vpn_connection_tunnel1_phase2_lifetime_seconds == null
    error_message = "Invalid input, options: Valid value is between 900 and 3600."
  }
}

variable "vpn_connection_tunnel2_phase2_lifetime_seconds" {
  description = "(Optional, Default 3600) The lifetime for phase 2 of the IKE negotiation for the second VPN tunnel, in seconds. Valid value is between 900 and 3600."
  type        = number
  default     = 3600
  validation {
    condition     = var.vpn_connection_tunnel2_phase2_lifetime_seconds <= 3600 && var.vpn_connection_tunnel2_phase2_lifetime_seconds >= 900 || var.vpn_connection_tunnel2_phase2_lifetime_seconds == null
    error_message = "Invalid input, options: Valid value is between 900 and 3600."
  }
}

variable "vpn_connection_tunnel1_rekey_fuzz_percentage" {
  description = "(Optional, Default 100) The percentage of the rekey window for the first VPN tunnel (determined by tunnel1_rekey_margin_time_seconds) during which the rekey time is randomly selected. Valid value is between 0 and 100."
  type        = number
  default     = 100
  validation {
    condition     = var.vpn_connection_tunnel1_rekey_fuzz_percentage <= 100 && var.vpn_connection_tunnel1_rekey_fuzz_percentage >= 0
    error_message = "Invalid input, options: Valid value is between 0 and 100."
  }
}

variable "vpn_connection_tunnel2_rekey_fuzz_percentage" {
  description = "(Optional, Default 100) The percentage of the rekey window for the second VPN tunnel (determined by tunnel2_rekey_margin_time_seconds) during which the rekey time is randomly selected. Valid value is between 0 and 100."
  type        = number
  default     = 100
  validation {
    condition     = var.vpn_connection_tunnel2_rekey_fuzz_percentage <= 100 && var.vpn_connection_tunnel2_rekey_fuzz_percentage >= 0
    error_message = "Invalid input, options: Valid value is between 0 and 100."
  }
}

variable "vpn_connection_tunnel1_rekey_margin_time_seconds" {
  description = "(Optional, Default 540) The margin time, in seconds, before the phase 2 lifetime expires, during which the AWS side of the first VPN connection performs an IKE rekey. The exact time of the rekey is randomly selected based on the value for tunnel1_rekey_fuzz_percentage. Valid value is between 60 and half of tunnel1_phase2_lifetime_seconds."
  type        = number
  default     = 540
}

variable "vpn_connection_tunnel2_rekey_margin_time_seconds" {
  description = "(Optional, Default 540) The margin time, in seconds, before the phase 2 lifetime expires, during which the AWS side of the second VPN connection performs an IKE rekey. The exact time of the rekey is randomly selected based on the value for tunnel2_rekey_fuzz_percentage. Valid value is between 60 and half of tunnel2_phase2_lifetime_seconds."
  type        = number
  default     = 540
}

variable "vpn_connection_tunnel1_replay_window_size" {
  description = "(Optional, Default 1024) The number of packets in an IKE replay window for the first VPN tunnel. Valid value is between 64 and 2048."
  type        = number
  default     = 1024
  validation {
    condition     = var.vpn_connection_tunnel1_replay_window_size <= 2048 && var.vpn_connection_tunnel1_replay_window_size >= 64
    error_message = "Invalid input, options:  Valid value is between 64 and 2048."
  }
}

variable "vpn_connection_tunnel2_replay_window_size" {
  description = "(Optional, Default 1024) The number of packets in an IKE replay window for the second VPN tunnel. Valid value is between 64 and 2048."
  type        = number
  default     = 1024
  validation {
    condition     = var.vpn_connection_tunnel2_replay_window_size <= 2048 && var.vpn_connection_tunnel2_replay_window_size >= 64
    error_message = "Invalid input, options:  Valid value is between 64 and 2048."
  }
}

variable "vpn_connection_tunnel1_startup_action" {
  description = "(Optional, Default add) The action to take when the establishing the tunnel for the first VPN connection. By default, your customer gateway device must initiate the IKE negotiation and bring up the tunnel. Specify start for AWS to initiate the IKE negotiation. Valid values are add | start."
  type        = string
  default     = "add"
  validation {
    condition     = can(regex("^(add|start)$", var.vpn_connection_tunnel1_startup_action))
    error_message = "Invalid input, options: \"add|start\"."
  }
}

variable "vpn_connection_tunnel2_startup_action" {
  description = "(Optional, Default add) The action to take when the establishing the tunnel for the second VPN connection. By default, your customer gateway device must initiate the IKE negotiation and bring up the tunnel. Specify start for AWS to initiate the IKE negotiation. Valid values are add | start."
  type        = string
  default     = "add"
  validation {
    condition     = can(regex("^(add|start)$", var.vpn_connection_tunnel2_startup_action))
    error_message = "Invalid input, options: \"add|start\"."
  }
}

variable "vpn_connection_tunnel1_enable_tunnel_lifecycle_control" {
  description = "(Optional) Turn on or off tunnel endpoint lifecycle control feature for the first VPN tunnel."
  type        = bool
  default     = false
}

variable "vpn_connection_tunnel2_enable_tunnel_lifecycle_control" {
  description = "(Optional) Turn on or off tunnel endpoint lifecycle control feature for the second VPN tunnel."
  type        = bool
  default     = false
}

variable "vpn_connection_route_destination_cidr_block" {
  description = "(Required) The CIDR block associated with the local subnet of the customer network."
  type        = list(string)
  default     = []
}

variable "vpn_connection_tunnel1_log_bgp_enabled" {
  description = "Enable BGP log delivery to CloudWatch for tunnel 1"
  type        = bool
  default     = null
}

variable "vpn_connection_tunnel1_log_bgp_group_arn" {
  description = "ARN of the CloudWatch log group for BGP logs for tunnel 1"
  type        = string
  default     = null
}

variable "vpn_connection_tunnel1_log_bgp_output_format" {
  description = "The output format for BGP logs for tunnel 1. Valid values are json or text."
  type        = string
  default     = null
}

variable "vpn_connection_tunnel2_log_bgp_enabled" {
  description = "Enable BGP log delivery to CloudWatch for tunnel 2"
  type        = bool
  default     = null
}

variable "vpn_connection_tunnel2_log_bgp_group_arn" {
  description = "ARN of the CloudWatch log group for BGP logs for tunnel 2"
  type        = string
  default     = null
}

variable "vpn_connection_tunnel2_log_bgp_output_format" {
  description = "The output format for BGP logs for tunnel 2. Valid values are json or text."
  type        = string
  default     = null
}