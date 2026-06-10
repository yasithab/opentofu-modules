# EKS Fargate Profile Module

Configuration in this directory creates a Fargate EKS Profile

## Usage

```hcl
module "fargate_profile" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/fargate-profile?depth=1&ref=master"

  name         = "separate-fargate-profile"
  cluster_name = "my-cluster"

  subnet_ids = ["subnet-abcde012", "subnet-bcde012a", "subnet-fghi345a"]
  selectors = [{
    namespace = "kube-system"
  }]

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
```


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
| cluster\_ip\_family | The IP family used to assign Kubernetes pod and service addresses. Valid values are `ipv4` (default) and `ipv6` | `string` | `"ipv4"` | no |
| cluster\_name | Name of the EKS cluster | `string` | `null` | no |
| create\_iam\_role | Determines whether an IAM role is created or to use an existing IAM role | `bool` | `true` | no |
| create\_iam\_role\_policy | Determines whether an IAM role policy is created or not | `bool` | `true` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| iam\_role\_additional\_policies | Additional policies to be added to the IAM role | `map(string)` | `{}` | no |
| iam\_role\_arn | Existing IAM role ARN for the Fargate profile. Required if `create_iam_role` is set to `false` | `string` | `null` | no |
| iam\_role\_attach\_cni\_policy | Whether to attach the `AmazonEKS_CNI_Policy`/`AmazonEKS_CNI_IPv6_Policy` IAM policy to the IAM IAM role. WARNING: If set `false` the permissions must be assigned to the `aws-node` DaemonSet pods via another method or nodes will not be able to join the cluster | `bool` | `true` | no |
| iam\_role\_description | Description of the role | `string` | `null` | no |
| iam\_role\_name | Name to use on IAM role created | `string` | `null` | no |
| iam\_role\_path | IAM role path | `string` | `null` | no |
| iam\_role\_permissions\_boundary | ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| iam\_role\_policy\_statements | A list of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) - used for adding specific IAM permissions as needed | <pre>list(object({<br/>    sid           = optional(string)<br/>    actions       = optional(list(string))<br/>    not_actions   = optional(list(string))<br/>    effect        = optional(string)<br/>    resources     = optional(list(string))<br/>    not_resources = optional(list(string))<br/>    principals = optional(list(object({<br/>      type        = string<br/>      identifiers = list(string)<br/>    })), [])<br/>    not_principals = optional(list(object({<br/>      type        = string<br/>      identifiers = list(string)<br/>    })), [])<br/>    conditions = optional(list(object({<br/>      test     = string<br/>      values   = list(string)<br/>      variable = string<br/>    })), [])<br/>  }))</pre> | `[]` | no |
| iam\_role\_tags | A map of additional tags to add to the IAM role created | `map(string)` | `{}` | no |
| iam\_role\_use\_name\_prefix | Determines whether the IAM role name (`iam_role_name`) is used as a prefix | `bool` | `true` | no |
| name | Name of the EKS Fargate Profile | `string` | `null` | no |
| selectors | Configuration block(s) for selecting Kubernetes Pods to execute with this Fargate Profile | <pre>list(object({<br/>    namespace = string<br/>    labels    = optional(map(string), {})<br/>  }))</pre> | `[]` | no |
| subnet\_ids | A list of subnet IDs for the EKS Fargate Profile | `list(string)` | `[]` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| timeouts | Create and delete timeout configurations for the Fargate Profile | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| fargate\_profile\_arn | Amazon Resource Name (ARN) of the EKS Fargate Profile |
| fargate\_profile\_id | EKS Cluster name and EKS Fargate Profile name separated by a colon (`:`) |
| fargate\_profile\_pod\_execution\_role\_arn | Amazon Resource Name (ARN) of the EKS Fargate Profile Pod execution role ARN |
| fargate\_profile\_status | Status of the EKS Fargate Profile |
| iam\_role\_arn | The Amazon Resource Name (ARN) specifying the IAM role |
| iam\_role\_name | The name of the IAM role |
| iam\_role\_unique\_id | Stable and unique string identifying the IAM role |
<!-- END_TF_DOCS -->

## Examples

## Basic Usage

Fargate profile for the `kube-system` namespace.

```hcl
module "fargate_profile" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/fargate-profile?depth=1&ref=master"

  enabled      = true
  name         = "kube-system"
  cluster_name = "my-cluster"

  subnet_ids = ["subnet-0aaa111", "subnet-0bbb222"]

  selectors = [
    { namespace = "kube-system" }
  ]

  tags = {
    Environment = "production"
  }
}
```

## With Label Selectors

Fargate profile for an application namespace with pod label filtering.

```hcl
module "fargate_profile_app" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/fargate-profile?depth=1&ref=master"

  enabled      = true
  name         = "app-services"
  cluster_name = "serverless-cluster"

  subnet_ids = ["subnet-0aaa111", "subnet-0bbb222", "subnet-0ccc333"]

  selectors = [
    {
      namespace = "app"
      labels = {
        "fargate" = "true"
      }
    },
    {
      namespace = "workers"
      labels = {
        "compute-type" = "fargate"
      }
    }
  ]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## With Existing IAM Role

Fargate profile using a pre-existing IAM execution role.

```hcl
module "fargate_profile_monitoring" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/fargate-profile?depth=1&ref=master"

  enabled      = true
  name         = "monitoring"
  cluster_name = "prod-cluster"

  subnet_ids = ["subnet-0aaa111", "subnet-0bbb222"]

  create_iam_role = false
  iam_role_arn    = "arn:aws:iam::123456789012:role/existing-fargate-execution-role"

  selectors = [
    { namespace = "monitoring" },
    { namespace = "logging" }
  ]

  timeouts = {
    create = "30m"
    delete = "30m"
  }

  tags = {
    Environment = "production"
    Component   = "observability"
  }
}
```
