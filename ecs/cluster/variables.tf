variable "enabled" {
  description = "Determines whether resources will be created (affects all resources)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

################################################################################################################
# Cluster
################################################################################################################

variable "cluster_name" {
  description = "Name of the cluster (up to 255 letters, numbers, hyphens, and underscores)"
  type        = string
  default     = null
}

variable "cluster_configuration" {
  description = "The execute command configuration for the cluster"
  type        = any
  default     = {}
}

variable "cluster_settings" {
  description = "List of configuration block(s) with cluster settings. For example, this can be used to enable CloudWatch Container Insights for a cluster"
  type        = any
  default = [
    {
      name  = "containerInsights"
      value = "enabled"
    }
  ]
}

variable "cluster_service_connect_defaults" {
  description = "Configures a default Service Connect namespace"
  type        = map(string)
  default     = {}
}

################################################################################################################
# CloudWatch Log Group
################################################################################################################

variable "create_cloudwatch_log_group" {
  description = "Determines whether a log group is created by this module for the cluster logs. If not, AWS will automatically create one if logging is enabled"
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_name" {
  description = "Custom name of CloudWatch Log Group for ECS cluster"
  type        = string
  default     = null
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain log events"
  type        = number
  default     = 60

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_log_group_retention_in_days)
    error_message = "cloudwatch_log_group_retention_in_days must be one of the allowed CloudWatch Logs retention values: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653."
  }
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "If a KMS Key ARN is set, this key will be used to encrypt the corresponding log group. Please be sure that the KMS Key has an appropriate key policy (https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html)"
  type        = string
  default     = null
}

variable "cloudwatch_log_group_class" {
  description = "Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT_ACCESS"
  type        = string
  default     = null
}

variable "cloudwatch_log_group_skip_destroy" {
  description = "Set to true to prevent the log group from being deleted on module destroy. Preserves audit and execute-command logs."
  type        = bool
  default     = false
}

variable "cloudwatch_log_group_deletion_protection_enabled" {
  description = "Whether to enable deletion protection on the CloudWatch log group. If enabled, the log group cannot be deleted."
  type        = bool
  default     = null
}

variable "cloudwatch_log_group_tags" {
  description = "A map of additional tags to add to the log group created"
  type        = map(string)
  default     = {}
}

################################################################################################################
# Capacity Providers
################################################################################################################

variable "default_capacity_provider_use_fargate" {
  description = "Determines whether to use Fargate or autoscaling for default capacity provider strategy"
  type        = bool
  default     = true
}

variable "fargate_capacity_providers" {
  description = "Map of Fargate capacity provider definitions to use for the cluster"
  type        = any
  default     = {}
}

variable "autoscaling_capacity_providers" {
  description = "Map of autoscaling capacity provider definitions to create for the cluster"
  type        = any
  default     = {}
}

################################################################################################################
# Task Execution - IAM Role
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
################################################################################################################

variable "create_task_exec_iam_role" {
  description = "Determines whether the ECS task definition IAM role should be created"
  type        = bool
  default     = false
}

variable "task_exec_iam_role_name" {
  description = "Name to use on IAM role created"
  type        = string
  default     = null
}

variable "task_exec_iam_role_use_name_prefix" {
  description = "Determines whether the IAM role name (`task_exec_iam_role_name`) is used as a prefix"
  type        = bool
  default     = true
}

variable "task_exec_iam_role_path" {
  description = "IAM role path"
  type        = string
  default     = null
}

variable "task_exec_iam_role_description" {
  description = "Description of the role"
  type        = string
  default     = null
}

variable "task_exec_iam_role_permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the IAM role"
  type        = string
  default     = null
}

variable "task_exec_iam_role_tags" {
  description = "A map of additional tags to add to the IAM role created"
  type        = map(string)
  default     = {}
}

variable "task_exec_iam_role_policies" {
  description = "Map of IAM role policy ARNs to attach to the IAM role"
  type        = map(string)
  default     = {}
}

variable "create_task_exec_policy" {
  description = "Determines whether the ECS task definition IAM policy should be created. This includes permissions included in AmazonECSTaskExecutionRolePolicy as well as access to secrets and SSM parameters"
  type        = bool
  default     = true
}

variable "task_exec_ssm_param_arns" {
  description = "List of SSM parameter ARNs the task execution role will be permitted to get/read. Provide specific ARNs instead of wildcards to follow least-privilege"
  type        = list(string)
  default     = []
}

variable "task_exec_secret_arns" {
  description = "List of SecretsManager secret ARNs the task execution role will be permitted to get/read. Provide specific ARNs instead of wildcards to follow least-privilege"
  type        = list(string)
  default     = []
}

variable "task_exec_iam_statements" {
  description = "A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage"
  type        = any
  default     = {}
}

################################################################################################################
# Node - IAM Role + Instance Profile
################################################################################################################

variable "create_node_iam_role" {
  description = "Determines whether the ECS node IAM role and instance profile should be created. Required for EC2 launch type"
  type        = bool
  default     = false
}

variable "node_iam_role_name" {
  description = "Name to use on the node IAM role created"
  type        = string
  default     = null
}

variable "node_iam_role_use_name_prefix" {
  description = "Determines whether the node IAM role name is used as a prefix"
  type        = bool
  default     = true
}

variable "node_iam_role_path" {
  description = "IAM role path for the node role"
  type        = string
  default     = null
}

variable "node_iam_role_description" {
  description = "Description of the node IAM role"
  type        = string
  default     = null
}

variable "node_iam_role_permissions_boundary" {
  description = "ARN of the policy used as permissions boundary for the node IAM role"
  type        = string
  default     = null
}

variable "node_iam_role_tags" {
  description = "A map of additional tags to add to the node IAM role created"
  type        = map(string)
  default     = {}
}

variable "node_iam_role_policies" {
  description = "Map of IAM policy ARNs to attach to the node IAM role in addition to the defaults"
  type        = map(string)
  default     = {}
}

variable "node_iam_role_attach_ssm_policy" {
  description = "Whether to attach the AmazonSSMManagedInstanceCore policy to the node IAM role, enabling SSM Session Manager on EC2 nodes"
  type        = bool
  default     = true
}

################################################################################################################
# Security Group
################################################################################################################

variable "create_security_group" {
  description = "Determines whether a security group is created for the cluster (used with EC2 launch type)"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "ID of the VPC where the security group will be created"
  type        = string
  default     = null
}

variable "security_group_name" {
  description = "Name to use on the security group created"
  type        = string
  default     = null
}

variable "security_group_use_name_prefix" {
  description = "Determines whether the security group name is used as a prefix"
  type        = bool
  default     = true
}

variable "security_group_description" {
  description = "Description of the security group"
  type        = string
  default     = null
}

variable "security_group_rules" {
  description = "Map of security group rule objects to add to the security group. Keys are rule names, values accept type (ingress/egress), ip_protocol, from_port, to_port, and cidr_ipv4/cidr_ipv6/referenced_security_group_id"
  type        = any
  default     = {}
}

variable "security_group_tags" {
  description = "A map of additional tags to add to the security group created"
  type        = map(string)
  default     = {}
}

################################################################################################################
