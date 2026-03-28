<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.11.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.38.0 |
| <a name="requirement_cloudinit"></a> [cloudinit](#requirement\_cloudinit) | ~> 2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_cloudinit"></a> [cloudinit](#provider\_cloudinit) | ~> 2.0 |
| <a name="provider_null"></a> [null](#provider\_null) | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_cluster_dns_ips"></a> [additional\_cluster\_dns\_ips](#input\_additional\_cluster\_dns\_ips) | Additional DNS IP addresses to add to the cluster DNS configuration. | `list(string)` | `[]` | no |
| <a name="input_ami_type"></a> [ami\_type](#input\_ami\_type) | Type of Amazon Machine Image (AMI) associated with the EKS Node Group. | `string` | `null` | no |
| <a name="input_bootstrap_extra_args"></a> [bootstrap\_extra\_args](#input\_bootstrap\_extra\_args) | Additional arguments to pass to the EKS bootstrap script. | `string` | `null` | no |
| <a name="input_cloudinit_post_nodeadm"></a> [cloudinit\_post\_nodeadm](#input\_cloudinit\_post\_nodeadm) | Additional `cloud-init` configuration in MIME multi-part format to merge after nodeadm bootstrap. | <pre>list(object({<br/>    content      = string<br/>    content_type = optional(string, "text/x-shellscript")<br/>    filename     = optional(string)<br/>    merge_type   = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_cloudinit_pre_nodeadm"></a> [cloudinit\_pre\_nodeadm](#input\_cloudinit\_pre\_nodeadm) | Additional `cloud-init` configuration in MIME multi-part format to merge before nodeadm bootstrap. | <pre>list(object({<br/>    content      = string<br/>    content_type = optional(string, "text/x-shellscript")<br/>    filename     = optional(string)<br/>    merge_type   = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_cluster_auth_base64"></a> [cluster\_auth\_base64](#input\_cluster\_auth\_base64) | Base64 encoded CA of associated EKS cluster. | `string` | `null` | no |
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | Endpoint of the EKS cluster. | `string` | `null` | no |
| <a name="input_cluster_ip_family"></a> [cluster\_ip\_family](#input\_cluster\_ip\_family) | The IP family used to assign Kubernetes pod and service addresses. | `string` | `"ipv4"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster. | `string` | `null` | no |
| <a name="input_cluster_service_cidr"></a> [cluster\_service\_cidr](#input\_cluster\_service\_cidr) | The CIDR block (IPv4 or IPv6) used to assign Kubernetes pod and service IP addresses. | `string` | `null` | no |
| <a name="input_enable_bootstrap_user_data"></a> [enable\_bootstrap\_user\_data](#input\_enable\_bootstrap\_user\_data) | Determines whether the provided user data will be merged with the EKS bootstrap user data. | `bool` | `false` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources or generating user data. | `bool` | `true` | no |
| <a name="input_is_eks_managed_node_group"></a> [is\_eks\_managed\_node\_group](#input\_is\_eks\_managed\_node\_group) | Determines whether the user data is used on nodes in an EKS managed node group. | `bool` | `true` | no |
| <a name="input_platform"></a> [platform](#input\_platform) | Identifies the OS platform as `bottlerocket`, `linux`, `al2023`, or `windows`. Used as a fallback when ami\_type cannot be determined. | `string` | `null` | no |
| <a name="input_post_bootstrap_user_data"></a> [post\_bootstrap\_user\_data](#input\_post\_bootstrap\_user\_data) | User data that is appended to the user data script after the EKS bootstrap script. | `string` | `null` | no |
| <a name="input_pre_bootstrap_user_data"></a> [pre\_bootstrap\_user\_data](#input\_pre\_bootstrap\_user\_data) | User data that is injected into the user data script ahead of the EKS bootstrap script. | `string` | `null` | no |
| <a name="input_user_data_template_path"></a> [user\_data\_template\_path](#input\_user\_data\_template\_path) | Path to a local, custom user data template file to use when rendering user data. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_platform"></a> [platform](#output\_platform) | [DEPRECATED - Will be removed in `v21.0`] Identifies the OS platform as `bottlerocket`, `linux` (AL2), `al2023, or `windows |
| <a name="output_user_data"></a> [user\_data](#output\_user\_data) | Base64 encoded user data rendered for the provided inputs |
<!-- END_TF_DOCS -->