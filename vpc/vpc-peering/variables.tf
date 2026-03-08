variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "requestor_vpc_id" {
  type        = string
  description = "Requestor VPC ID"
  default     = null
}

variable "requestor_vpc_tags" {
  type        = map(string)
  description = "Requestor VPC tags"
  default     = {}
}

variable "requestor_route_table_tags" {
  type        = map(string)
  description = "Only add peer routes to requestor VPC route tables matching these tags"
  default     = {}
}

variable "acceptor_aws_account_id" {
  type        = string
  description = "The AWS account id of the acceptor"
  default     = null
}

variable "acceptor_aws_region" {
  type        = string
  description = "The AWS account id of the acceptor"
  default     = null
}

variable "acceptor_vpc_id" {
  type        = string
  description = "Acceptor VPC ID"
  default     = null
}

variable "acceptor_cidr_blocks" {
  type        = list(string)
  default     = []
  description = "accepter cidr blocks"
}

variable "requestor_allow_remote_vpc_dns_resolution" {
  type        = bool
  default     = true
  description = "Allow requestor VPC to resolve public DNS hostnames to private IP addresses when queried from instances in the acceptor VPC"
}

variable "acceptor_allow_remote_vpc_dns_resolution" {
  type        = bool
  default     = true
  description = "Allow acceptor VPC to resolve public DNS hostnames to private IP addresses when queried from instances in the requestor VPC"
}

variable "create_timeout" {
  type        = string
  description = "VPC peering connection create timeout. For more details, see https://www.terraform.io/docs/configuration/resources.html#operation-timeouts"
  default     = "3m"
}

variable "update_timeout" {
  type        = string
  description = "VPC peering connection update timeout. For more details, see https://www.terraform.io/docs/configuration/resources.html#operation-timeouts"
  default     = "3m"
}

variable "delete_timeout" {
  type        = string
  description = "VPC peering connection delete timeout. For more details, see https://www.terraform.io/docs/configuration/resources.html#operation-timeouts"
  default     = "5m"
}

