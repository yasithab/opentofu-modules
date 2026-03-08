<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.34 |
| <a name="requirement_docker"></a> [docker](#requirement\_docker) | >= 3.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.35.1 |
| <a name="provider_docker"></a> [docker](#provider\_docker) | 3.9.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_build_args"></a> [build\_args](#input\_build\_args) | A map of Docker build arguments. | `map(string)` | `{}` | no |
| <a name="input_create_ecr_repo"></a> [create\_ecr\_repo](#input\_create\_ecr\_repo) | Controls whether ECR repository for Lambda image should be created | `bool` | `false` | no |
| <a name="input_create_sam_metadata"></a> [create\_sam\_metadata](#input\_create\_sam\_metadata) | Controls whether the SAM metadata null resource should be created | `bool` | `false` | no |
| <a name="input_docker_file_path"></a> [docker\_file\_path](#input\_docker\_file\_path) | Path to Dockerfile in source package | `string` | `"Dockerfile"` | no |
| <a name="input_ecr_address"></a> [ecr\_address](#input\_ecr\_address) | Address of ECR repository for cross-account container image pulling (optional). Option `create_ecr_repo` must be `false` | `string` | `null` | no |
| <a name="input_ecr_force_delete"></a> [ecr\_force\_delete](#input\_ecr\_force\_delete) | If true, will delete the repository even if it contains images. | `bool` | `true` | no |
| <a name="input_ecr_repo"></a> [ecr\_repo](#input\_ecr\_repo) | Name of ECR repository to use or to create | `string` | `null` | no |
| <a name="input_ecr_repo_lifecycle_policy"></a> [ecr\_repo\_lifecycle\_policy](#input\_ecr\_repo\_lifecycle\_policy) | A JSON formatted ECR lifecycle policy to automate the cleaning up of unused images. | `string` | `null` | no |
| <a name="input_ecr_repo_tags"></a> [ecr\_repo\_tags](#input\_ecr\_repo\_tags) | A map of tags to assign to ECR repository | `map(string)` | `{}` | no |
| <a name="input_encryption_configuration"></a> [encryption\_configuration](#input\_encryption\_configuration) | Encryption configuration block for the ECR repository. Supports encryption\_type (AES256 or KMS) and kms\_key (ARN). | `any` | `null` | no |
| <a name="input_force_remove"></a> [force\_remove](#input\_force\_remove) | Whether to remove image forcibly when the resource is destroyed. | `bool` | `false` | no |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | Image tag to use. If not specified current timestamp in format 'YYYYMMDDhhmmss' will be used. This can lead to unnecessary rebuilds. | `string` | `null` | no |
| <a name="input_image_tag_mutability"></a> [image\_tag\_mutability](#input\_image\_tag\_mutability) | The tag mutability setting for the repository. Must be one of: `MUTABLE`, `IMMUTABLE`, `MUTABLE_WITH_EXCLUSION`, or `IMMUTABLE_WITH_EXCLUSION` | `string` | `"MUTABLE"` | no |
| <a name="input_image_tag_mutability_exclusion_filter"></a> [image\_tag\_mutability\_exclusion\_filter](#input\_image\_tag\_mutability\_exclusion\_filter) | Configuration block for tag mutability exclusion filter. Required when image\_tag\_mutability is MUTABLE\_WITH\_EXCLUSION or IMMUTABLE\_WITH\_EXCLUSION. Contains filter (pattern string) and filter\_type (WILDCARD). | `any` | `null` | no |
| <a name="input_keep_locally"></a> [keep\_locally](#input\_keep\_locally) | Whether to delete the Docker image locally on destroy operation. | `bool` | `false` | no |
| <a name="input_keep_remotely"></a> [keep\_remotely](#input\_keep\_remotely) | Whether to keep Docker image in the remote registry on destroy operation. | `bool` | `false` | no |
| <a name="input_platform"></a> [platform](#input\_platform) | The target architecture platform to build the image for. | `string` | `null` | no |
| <a name="input_scan_on_push"></a> [scan\_on\_push](#input\_scan\_on\_push) | Indicates whether images are scanned after being pushed to the repository | `bool` | `false` | no |
| <a name="input_source_path"></a> [source\_path](#input\_source\_path) | Path to folder containing application code | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_triggers"></a> [triggers](#input\_triggers) | A map of arbitrary strings that, when changed, will force the docker\_image resource to be replaced. This can be used to rebuild an image when contents of source code folders change | `map(string)` | `{}` | no |
| <a name="input_use_image_tag"></a> [use\_image\_tag](#input\_use\_image\_tag) | Controls whether to use image tag in ECR repository URI or not. Disable this to deploy latest image using ID (sha256:...) | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_image_id"></a> [image\_id](#output\_image\_id) | The ID of the Docker image |
| <a name="output_image_uri"></a> [image\_uri](#output\_image\_uri) | The ECR image URI for deploying lambda |
<!-- END_TF_DOCS -->