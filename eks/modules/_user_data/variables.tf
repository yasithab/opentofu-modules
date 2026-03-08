variable "enabled" {
  description = "Set to false to prevent the module from creating any resources or generating user data."
  type        = bool
  default     = true
}

variable "platform" {
  description = "Identifies the OS platform as `bottlerocket`, `linux`, `al2023`, or `windows`. Used as a fallback when ami_type cannot be determined."
  type        = string
  default     = null
}

variable "ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group."
  type        = string
  default     = null
}

variable "is_eks_managed_node_group" {
  description = "Determines whether the user data is used on nodes in an EKS managed node group."
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = null
}

variable "cluster_endpoint" {
  description = "Endpoint of the EKS cluster."
  type        = string
  default     = null
}

variable "cluster_auth_base64" {
  description = "Base64 encoded CA of associated EKS cluster."
  type        = string
  default     = null
}

variable "cluster_ip_family" {
  description = "The IP family used to assign Kubernetes pod and service addresses."
  type        = string
  default     = "ipv4"
}

variable "cluster_service_cidr" {
  description = "The CIDR block (IPv4 or IPv6) used to assign Kubernetes pod and service IP addresses."
  type        = string
  default     = null
}

variable "additional_cluster_dns_ips" {
  description = "Additional DNS IP addresses to add to the cluster DNS configuration."
  type        = list(string)
  default     = []
}

variable "enable_bootstrap_user_data" {
  description = "Determines whether the provided user data will be merged with the EKS bootstrap user data."
  type        = bool
  default     = false
}

variable "pre_bootstrap_user_data" {
  description = "User data that is injected into the user data script ahead of the EKS bootstrap script."
  type        = string
  default     = null
}

variable "post_bootstrap_user_data" {
  description = "User data that is appended to the user data script after the EKS bootstrap script."
  type        = string
  default     = null
}

variable "bootstrap_extra_args" {
  description = "Additional arguments to pass to the EKS bootstrap script."
  type        = string
  default     = null
}

variable "user_data_template_path" {
  description = "Path to a local, custom user data template file to use when rendering user data."
  type        = string
  default     = null
}

variable "cloudinit_pre_nodeadm" {
  description = "Additional `cloud-init` configuration in MIME multi-part format to merge before nodeadm bootstrap."
  type = list(object({
    content      = string
    content_type = optional(string, "text/x-shellscript")
    filename     = optional(string)
    merge_type   = optional(string)
  }))
  default = []
}

variable "cloudinit_post_nodeadm" {
  description = "Additional `cloud-init` configuration in MIME multi-part format to merge after nodeadm bootstrap."
  type = list(object({
    content      = string
    content_type = optional(string, "text/x-shellscript")
    filename     = optional(string)
    merge_type   = optional(string)
  }))
  default = []
}

