# Karpenter Module

Configuration in this directory creates the AWS resources required by Karpenter

## Usage

### All Resources (Default)

In the following example, the Karpenter module will create:
- An IAM role for use with Pod Identity and a scoped IAM policy for the Karpenter controller
- A Pod Identity association to grant Karpenter controller access provided by the IAM Role
- A Node IAM role that Karpenter will use to create an Instance Profile for the nodes to receive IAM permissions
- An access entry for the Node IAM role to allow nodes to join the cluster
- SQS queue and EventBridge event rules for Karpenter to utilize for spot termination handling, capacity re-balancing, etc.

```hcl
module "eks" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks?depth=1&ref=master"

  ...
}

module "karpenter" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/karpenter?depth=1&ref=master"

  cluster_name = module.eks.cluster_name

  # Attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
```

### Re-Use Existing Node IAM Role

In the following example, the Karpenter module will create:
- An IAM role for use with Pod Identity and a scoped IAM policy for the Karpenter controller
- SQS queue and EventBridge event rules for Karpenter to utilize for spot termination handling, capacity re-balancing, etc.

In this scenario, Karpenter will re-use an existing Node IAM role from the EKS managed node group which already has the necessary access entry permissions:

```hcl
module "eks" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks?depth=1&ref=master"

  # Shown just for connection between cluster and Karpenter sub-module below
  eks_managed_node_groups = {
    initial = {
      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 1
    }
  }
  ...
}

module "karpenter" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/karpenter?depth=1&ref=master"

  cluster_name = module.eks.cluster_name

  create_node_iam_role = false
  node_iam_role_arn    = module.eks.eks_managed_node_groups["initial"].iam_role_arn

  # Since the node group role will already have an access entry
  create_access_entry = false

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
```

## Examples

## Basic Usage

Create Karpenter IAM role and SQS queue for spot termination handling using Pod Identity.

```hcl
module "karpenter" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/karpenter?depth=1&ref=master"

  create       = true
  cluster_name = "my-cluster"

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## With Pod Identity Association

Karpenter with Pod Identity association and Karpenter v1 permissions enabled.

```hcl
module "karpenter" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/karpenter?depth=1&ref=master"

  create       = true
  cluster_name = "app-cluster"

  enable_pod_identity           = true
  create_pod_identity_association = true
  enable_v1_permissions         = true

  namespace       = "kube-system"
  service_account = "karpenter"

  enable_spot_termination = true

  node_iam_role_name            = "KarpenterNodeRole-app-cluster"
  node_iam_role_use_name_prefix = false
  create_instance_profile       = true

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## With IRSA (Legacy / Non-Pod-Identity Clusters)

Karpenter using IRSA instead of Pod Identity for older EKS clusters.

```hcl
module "karpenter" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/karpenter?depth=1&ref=master"

  create       = true
  cluster_name = "legacy-cluster"

  enable_pod_identity = false
  enable_irsa         = true

  irsa_oidc_provider_arn          = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.ap-southeast-1.amazonaws.com/id/ABCD1234"
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  node_iam_role_name      = "KarpenterNodeRole-legacy-cluster"
  create_instance_profile = true

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Advanced - Cross-Account with Custom SQS and Event Bridge

Karpenter with a custom SQS queue name, KMS encryption, and cross-account role chaining.

```hcl
module "karpenter" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/karpenter?depth=1&ref=master"

  create       = true
  cluster_name = "prod-cluster"

  enable_pod_identity             = true
  create_pod_identity_association = true
  enable_v1_permissions           = true

  iam_role_name            = "KarpenterController-prod"
  iam_role_use_name_prefix = false
  iam_role_description     = "Karpenter controller role for prod-cluster"

  iam_role_permissions_boundary_arn = "arn:aws:iam::123456789012:policy/BoundaryPolicy"

  pod_identity_target_role_arn = "arn:aws:iam::987654321098:role/KarpenterCrossAccountRole"

  enable_spot_termination                    = true
  queue_name                                 = "KarpenterInterruptionQueue-prod"
  queue_managed_sse_enabled                  = false
  queue_kms_master_key_id                    = "arn:aws:kms:ap-southeast-1:123456789012:key/mrk-abc123"
  queue_kms_data_key_reuse_period_seconds    = 300
  queue_visibility_timeout_seconds           = 60

  node_iam_role_name                 = "KarpenterNodeRole-prod"
  node_iam_role_use_name_prefix      = false
  node_iam_role_permissions_boundary = "arn:aws:iam::123456789012:policy/BoundaryPolicy"
  create_instance_profile            = true
  node_iam_role_additional_policies = {
    ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  ami_id_ssm_parameter_arns = [
    "arn:aws:ssm:ap-southeast-1::parameter/aws/service/eks/optimized-ami/*"
  ]

  event_rule_state    = "ENABLED"
  rule_name_prefix    = "Karpenter-prod"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    CostCenter  = "platform"
  }
}
```

## Reference

<details>
<summary>Requirements, providers, inputs and outputs (generated by terraform-docs)</summary>

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11.0 |
| aws | >= 6.49, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| access\_entry\_type | Type of the access entry. `EC2_LINUX`, `FARGATE_LINUX`, or `EC2_WINDOWS`; defaults to `EC2_LINUX` | `string` | `"EC2_LINUX"` | no |
| ami\_id\_ssm\_parameter\_arns | List of SSM Parameter ARNs that Karpenter controller is allowed read access (for retrieving AMI IDs) | `list(string)` | `[]` | no |
| cluster\_ip\_family | The IP family used to assign Kubernetes pod and service addresses. Valid values are `ipv4` (default) and `ipv6`. Note: If `ipv6` is specified, the `AmazonEKS_CNI_IPv6_Policy` must exist in the account. This policy is created by the EKS module with `create_cni_ipv6_iam_policy = true` | `string` | `"ipv4"` | no |
| cluster\_name | The name of the EKS cluster | `string` | `null` | no |
| create\_access\_entry | Determines whether an access entry is created for the IAM role used by the node IAM role | `bool` | `true` | no |
| create\_iam\_role | Determines whether an IAM role is created | `bool` | `true` | no |
| create\_instance\_profile | Whether to create an IAM instance profile | `bool` | `false` | no |
| create\_node\_iam\_role | Determines whether an IAM role is created or to use an existing IAM role | `bool` | `true` | no |
| create\_pod\_identity\_association | Determines whether to create pod identity association | `bool` | `true` | no |
| enable\_irsa | Determines whether to enable support for IAM role for service accounts | `bool` | `false` | no |
| enable\_pod\_identity | Determines whether to enable support for EKS pod identity | `bool` | `true` | no |
| enable\_spot\_termination | Determines whether to enable native spot termination handling | `bool` | `true` | no |
| enable\_v1\_permissions | Determines whether to enable permissions suitable for v1+ (`true`) or for v0.33.x-v0.37.x (`false`) | `bool` | `true` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| event\_bus\_name | The name or ARN of the event bus to associate with EventBridge rules and targets. Defaults to the default event bus | `string` | `null` | no |
| event\_rule\_force\_destroy | Used to delete managed rules created by AWS. Defaults to `false` | `bool` | `null` | no |
| event\_rule\_role\_arn | The Amazon Resource Name (ARN) associated with the IAM role used for target invocation of the EventBridge rule | `string` | `null` | no |
| event\_rule\_state | State of the EventBridge rule. Valid values are `DISABLED`, `ENABLED`, and `ENABLED_WITH_ALL_CLOUDTRAIL_MANAGEMENT_EVENTS`. Defaults to `ENABLED` | `string` | `null` | no |
| iam\_policy\_description | IAM policy description | `string` | `"Karpenter controller IAM policy"` | no |
| iam\_policy\_name | Name of the IAM policy | `string` | `"KarpenterController"` | no |
| iam\_policy\_path | Path of the IAM policy | `string` | `"/"` | no |
| iam\_policy\_statements | A list of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) - used for adding specific IAM permissions as needed | <pre>list(object({<br/>    sid           = optional(string)<br/>    actions       = optional(list(string))<br/>    not_actions   = optional(list(string))<br/>    effect        = optional(string)<br/>    resources     = optional(list(string))<br/>    not_resources = optional(list(string))<br/>    principals = optional(list(object({<br/>      type        = string<br/>      identifiers = list(string)<br/>    })), [])<br/>    not_principals = optional(list(object({<br/>      type        = string<br/>      identifiers = list(string)<br/>    })), [])<br/>    conditions = optional(list(object({<br/>      test     = string<br/>      values   = list(string)<br/>      variable = string<br/>    })), [])<br/>  }))</pre> | `[]` | no |
| iam\_policy\_use\_name\_prefix | Determines whether the name of the IAM policy (`iam_policy_name`) is used as a prefix | `bool` | `true` | no |
| iam\_role\_description | IAM role description | `string` | `"Karpenter controller IAM role"` | no |
| iam\_role\_max\_session\_duration | Maximum API session duration in seconds between 3600 and 43200 | `number` | `null` | no |
| iam\_role\_name | Name of the IAM role | `string` | `"KarpenterController"` | no |
| iam\_role\_path | Path of the IAM role | `string` | `"/"` | no |
| iam\_role\_permissions\_boundary\_arn | Permissions boundary ARN to use for the IAM role | `string` | `null` | no |
| iam\_role\_policies | Policies to attach to the IAM role in `{'static_name' = 'policy_arn'}` format | `map(string)` | `{}` | no |
| iam\_role\_tags | A map of additional tags to add the the IAM role | `map(string)` | `{}` | no |
| iam\_role\_use\_name\_prefix | Determines whether the name of the IAM role (`iam_role_name`) is used as a prefix | `bool` | `true` | no |
| irsa\_assume\_role\_condition\_test | Name of the [IAM condition operator](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_condition_operators.html) to evaluate when assuming the role | `string` | `"StringEquals"` | no |
| irsa\_namespace\_service\_accounts | List of `namespace:serviceaccount`pairs to use in trust policy for IAM role for service accounts | `list(string)` | <pre>[<br/>  "karpenter:karpenter"<br/>]</pre> | no |
| irsa\_oidc\_provider\_arn | OIDC provider arn used in trust policy for IAM role for service accounts | `string` | `""` | no |
| namespace | Namespace to associate with the Karpenter Pod Identity | `string` | `"kube-system"` | no |
| node\_iam\_role\_additional\_policies | Additional policies to be added to the IAM role | `map(string)` | `{}` | no |
| node\_iam\_role\_arn | Existing IAM role ARN for the IAM instance profile. Required if `create_node_iam_role` is set to `false` | `string` | `null` | no |
| node\_iam\_role\_attach\_cni\_policy | Whether to attach the `AmazonEKS_CNI_Policy`/`AmazonEKS_CNI_IPv6_Policy` IAM policy to the IAM IAM role. WARNING: If set `false` the permissions must be assigned to the `aws-node` DaemonSet pods via another method or nodes will not be able to join the cluster | `bool` | `true` | no |
| node\_iam\_role\_description | Description of the role | `string` | `null` | no |
| node\_iam\_role\_max\_session\_duration | Maximum API session duration in seconds between 3600 and 43200 | `number` | `null` | no |
| node\_iam\_role\_name | Name to use on IAM role created | `string` | `null` | no |
| node\_iam\_role\_path | IAM role path | `string` | `"/"` | no |
| node\_iam\_role\_permissions\_boundary | ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| node\_iam\_role\_tags | A map of additional tags to add to the IAM role created | `map(string)` | `{}` | no |
| node\_iam\_role\_use\_name\_prefix | Determines whether the Node IAM role name (`node_iam_role_name`) is used as a prefix | `bool` | `true` | no |
| pod\_identity\_disable\_session\_tags | Whether to disable automatic session tags for the Pod Identity association | `bool` | `null` | no |
| pod\_identity\_target\_role\_arn | The ARN of an IAM role to chain to the Karpenter role via assume role. Used for cross-account role chaining | `string` | `null` | no |
| queue\_delay\_seconds | Time in seconds that the delivery of all messages in the queue will be delayed. An integer from 0 to 900. Defaults to 0 | `number` | `null` | no |
| queue\_kms\_data\_key\_reuse\_period\_seconds | The length of time, in seconds, for which Amazon SQS can reuse a data key to encrypt or decrypt messages before calling AWS KMS again | `number` | `null` | no |
| queue\_kms\_master\_key\_id | The ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK | `string` | `null` | no |
| queue\_managed\_sse\_enabled | Boolean to enable server-side encryption (SSE) of message content with SQS-owned encryption keys | `bool` | `true` | no |
| queue\_max\_message\_size | Limit of how many bytes a message can contain before Amazon SQS rejects it. An integer from 1024 bytes (1 KiB) up to 262144 bytes (256 KiB). Defaults to 262144 | `number` | `null` | no |
| queue\_name | Name of the SQS queue | `string` | `null` | no |
| queue\_receive\_wait\_time\_seconds | Time for which a ReceiveMessage call will wait for a message to arrive (long polling) before returning. An integer from 0 to 20. Defaults to 0 | `number` | `null` | no |
| queue\_visibility\_timeout\_seconds | Visibility timeout for the queue. An integer from 0 to 43200 (12 hours). Defaults to 30 | `number` | `null` | no |
| rule\_name\_prefix | Prefix used for all event bridge rules | `string` | `"Karpenter"` | no |
| service\_account | Service account to associate with the Karpenter Pod Identity | `string` | `"karpenter"` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| event\_rules | Map of the event rules created and their attributes |
| iam\_role\_arn | The Amazon Resource Name (ARN) specifying the controller IAM role |
| iam\_role\_name | The name of the controller IAM role |
| iam\_role\_unique\_id | Stable and unique string identifying the controller IAM role |
| instance\_profile\_arn | ARN assigned by AWS to the instance profile |
| instance\_profile\_id | Instance profile's ID |
| instance\_profile\_name | Name of the instance profile |
| instance\_profile\_unique | Stable and unique string identifying the IAM instance profile |
| namespace | Namespace associated with the Karpenter Pod Identity |
| node\_access\_entry\_arn | Amazon Resource Name (ARN) of the node Access Entry |
| node\_iam\_role\_arn | The Amazon Resource Name (ARN) specifying the node IAM role |
| node\_iam\_role\_name | The name of the node IAM role |
| node\_iam\_role\_unique\_id | Stable and unique string identifying the node IAM role |
| queue\_arn | The ARN of the SQS queue |
| queue\_name | The name of the created Amazon SQS queue |
| queue\_url | The URL for the created Amazon SQS queue |
| service\_account | Service Account associated with the Karpenter Pod Identity |
<!-- END_TF_DOCS -->

</details>
