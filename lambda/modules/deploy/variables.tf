variable "enabled" {
  description = "Controls whether resources should be created"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to resources."
  type        = map(string)
  default     = {}
}

variable "alias_name" {
  description = "Name for the alias"
  type        = string
  default     = null
}

variable "function_name" {
  description = "The name of the Lambda function to deploy"
  type        = string
  default     = null

  validation {
    condition     = var.function_name == null || length(var.function_name) > 0
    error_message = "function_name must not be empty when provided."
  }
}

variable "current_version" {
  description = "Current version of Lambda function version to deploy (can't be $LATEST)"
  type        = string
  default     = null
}

variable "target_version" {
  description = "Target version of Lambda function version to deploy"
  type        = string
  default     = null
}

variable "before_allow_traffic_hook_arn" {
  description = "ARN of Lambda function to execute before allow traffic during deployment. This function should be named CodeDeployHook_, to match the managed AWSCodeDeployForLambda policy, unless you're using a custom role"
  type        = string
  default     = null

  validation {
    condition     = var.before_allow_traffic_hook_arn == null || can(regex("^arn:", var.before_allow_traffic_hook_arn))
    error_message = "before_allow_traffic_hook_arn must be a valid ARN starting with 'arn:'."
  }
}

variable "after_allow_traffic_hook_arn" {
  description = "ARN of Lambda function to execute after allow traffic during deployment. This function should be named CodeDeployHook_, to match the managed AWSCodeDeployForLambda policy, unless you're using a custom role"
  type        = string
  default     = null

  validation {
    condition     = var.after_allow_traffic_hook_arn == null || can(regex("^arn:", var.after_allow_traffic_hook_arn))
    error_message = "after_allow_traffic_hook_arn must be a valid ARN starting with 'arn:'."
  }
}

variable "interpreter" {
  description = "List of interpreter arguments used to execute deploy script, first arg is path"
  type        = list(string)
  default     = ["/bin/bash", "-c"]
}

variable "description" {
  description = "Description to use for the deployment"
  type        = string
  default     = ""
}

#########################
# CodeDeploy Application
#########################

variable "create_app" {
  description = "Whether to create new AWS CodeDeploy app"
  type        = bool
  default     = false
}

variable "use_existing_app" {
  description = "Whether to use existing AWS CodeDeploy app"
  type        = bool
  default     = false
}

variable "app_name" {
  description = "Name of AWS CodeDeploy application"
  type        = string
  default     = null
}

##############################
# CodeDeploy Deployment Group
##############################

variable "create_deployment_group" {
  description = "Whether to create new AWS CodeDeploy Deployment Group"
  type        = bool
  default     = false
}

variable "use_existing_deployment_group" {
  description = "Whether to use existing AWS CodeDeploy Deployment Group"
  type        = bool
  default     = false
}

variable "deployment_group_name" {
  description = "Name of deployment group to use"
  type        = string
  default     = null
}

variable "deployment_config_name" {
  description = "Name of deployment config to use"
  type        = string
  default     = "CodeDeployDefault.LambdaAllAtOnce"
}

variable "outdated_instances_strategy" {
  description = "Indicates what happens when new Amazon EC2 instances are launched mid-deployment and do not receive the deployed application revision. Valid values are UPDATE and IGNORE."
  type        = string
  default     = null

  validation {
    condition     = var.outdated_instances_strategy == null || contains(["UPDATE", "IGNORE"], var.outdated_instances_strategy)
    error_message = "outdated_instances_strategy must be either 'UPDATE' or 'IGNORE'."
  }
}

variable "termination_hook_enabled" {
  description = "Indicates whether the deployment group was configured to have CodeDeploy install a termination hook into an Auto Scaling group."
  type        = bool
  default     = null
}

variable "ec2_tag_filter" {
  description = "List of EC2 tag filters for the deployment group. Each filter has key, type (KEY_ONLY, VALUE_ONLY, KEY_AND_VALUE), and value."
  type        = list(any)
  default     = []
}

variable "ec2_tag_set" {
  description = "List of EC2 tag set filter groups. Each group contains a list of ec2_tag_filter objects."
  type        = list(any)
  default     = []
}

variable "auto_rollback_enabled" {
  description = "Indicates whether a defined automatic rollback configuration is currently enabled for this Deployment Group."
  type        = bool
  default     = true
}

variable "auto_rollback_events" {
  description = "List of event types that trigger a rollback. Supported types are DEPLOYMENT_FAILURE and DEPLOYMENT_STOP_ON_ALARM."
  type        = list(string)
  default     = ["DEPLOYMENT_STOP_ON_ALARM"]
}

variable "alarm_enabled" {
  description = "Indicates whether the alarm configuration is enabled. This option is useful when you want to temporarily deactivate alarm monitoring for a deployment group without having to add the same alarms again later."
  type        = bool
  default     = false
}

variable "alarms" {
  description = "A list of alarms configured for the deployment group. A maximum of 10 alarms can be added to a deployment group."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.alarms) <= 10
    error_message = "alarms supports a maximum of 10 entries."
  }
}

variable "alarm_ignore_poll_alarm_failure" {
  description = "Indicates whether a deployment should continue if information about the current state of alarms cannot be retrieved from CloudWatch."
  type        = bool
  default     = false
}

variable "triggers" {
  description = "Map of triggers which will be notified when event happens. Valid options for event types are DeploymentStart, DeploymentSuccess, DeploymentFailure, DeploymentStop, DeploymentRollback, DeploymentReady (Applies only to replacement instances in a blue/green deployment), InstanceStart, InstanceSuccess, InstanceFailure, InstanceReady. Note that not all are applicable for Lambda deployments."
  type        = map(any)
  default     = {}
}

########################
# CodeDeploy Deployment
########################

variable "aws_cli_command" {
  description = "Command to run as AWS CLI. May include extra arguments like region and profile."
  type        = string
  default     = "aws"
}

variable "save_deploy_script" {
  description = "Save deploy script locally"
  type        = bool
  default     = false
}

variable "create_deployment" {
  description = "Create the AWS resources and script for CodeDeploy"
  type        = bool
  default     = false
}

variable "run_deployment" {
  description = "Run AWS CLI command to start the deployment"
  type        = bool
  default     = false
}

variable "force_deploy" {
  description = "Force deployment every time (even when nothing changes)"
  type        = bool
  default     = false
}

variable "wait_deployment_completion" {
  description = "Wait until deployment completes. It can take a lot of time and your terraform process may lock execution for long time."
  type        = bool
  default     = false
}

######################
# CodeDeploy IAM role
######################

variable "create_codedeploy_role" {
  description = "Whether to create new AWS CodeDeploy IAM role"
  type        = bool
  default     = true
}

variable "codedeploy_role_name" {
  description = "IAM role name to create or use by CodeDeploy"
  type        = string
  default     = null
}

variable "codedeploy_principals" {
  description = "List of CodeDeploy service principals to allow. The list can include global or regional endpoints."
  type        = list(string)
  default     = ["codedeploy.amazonaws.com"]
}

variable "attach_hooks_policy" {
  description = "Whether to attach Invoke policy to CodeDeploy role when before allow traffic or after allow traffic hooks are defined."
  type        = bool
  default     = true
}

variable "attach_triggers_policy" {
  description = "Whether to attach SNS policy to CodeDeploy role when triggers are defined"
  type        = bool
  default     = false
}

variable "get_deployment_sleep_timer" {
  description = "Adds additional sleep time to get-deployment command to avoid the service throttling"
  type        = number
  default     = 5

  validation {
    condition     = var.get_deployment_sleep_timer >= 0
    error_message = "get_deployment_sleep_timer must be 0 or a positive number."
  }
}
