# Terraform S3 Bucket

- [Terraform S3 Bucket](#terraform-s3-bucket)
  - [Examples](#examples)
  - [Requirements](#requirements)
  - [Resources](#resources)
  - [Inputs](#inputs)
  - [Outputs](#outputs)

## Examples

[examples](examples/)

<!-- markdownlint-disable line-length no-inline-html-->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0, <6.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_notification.bucket_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_policy.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_policy"></a> [bucket\_policy](#input\_bucket\_policy) | Additional bucket policy statements. Default policy allows only SSL requests | `any` | `[]` | no |
| <a name="input_bucket_prefix"></a> [bucket\_prefix](#input\_bucket\_prefix) | Prefix for bucket name, AWS will append it with creation time and serial number | `string` | n/a | yes |
| <a name="input_default_expiration"></a> [default\_expiration](#input\_default\_expiration) | Enable or disable default lifecycle policy for expiring objects and set days, enabled by default and expire objects after 180 days | `any` | <pre>{<br>  "days": 180,<br>  "enabled": true<br>}</pre> | no |
| <a name="input_external_accounts"></a> [external\_accounts](#input\_external\_accounts) | List of external account for bucket read only access | `list(string)` | `[]` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Allow force destruction of bucket, allows destroy even when bucket is not empty | `bool` | `false` | no |
| <a name="input_lifecycle_rule"></a> [lifecycle\_rule](#input\_lifecycle\_rule) | Controlling bucket lifecycle rules, zero or more supported [doc](docs/lifecycle\_rule.md) | `any` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for S3 bucket | `map(string)` | `{}` | no |
| <a name="input_versioning_status"></a> [versioning\_status](#input\_versioning\_status) | Control versioning status of bucket. Default: Enabled, Options: Enabled, Suspended, or Disabled | `string` | `"Enabled"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the bucket name + prefix |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the bucket name + prefix |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
