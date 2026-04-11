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
