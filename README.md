# Terraform S3 Bucket
- [Terraform S3 Bucket](#terraform-s3-bucket)
  - [Input Variables](#input-variables)
  - [Vars definitions](#vars-definitions)
      - [Lifecycle](#lifecycle)
      - [Replication](#replication)
      - [Versioning](#versioning)
      - [Encryption](#encryption)
      - [Public access](#public-access)
  - [Examples](#examples)
      - [`main.tf`](#maintf)
      - [`terraform.tfvars.json`](#terraformtfvarsjson)
      - [`provider.tf`](#providertf)
      - [`variables.tf`](#variablestf)
      - [`outputs.tf`](#outputstf)

## Input Variables

| Name       | Type      | Default     | Example         | Notes     |
| ---------- | --------- | ------------| --------------- | --------- |
| bucket_prefix | string | N/A | test-bucket- | Creates a unique bucket name |
| force_destroy | bool | false | true | |
| lifecycle_rule | list(object) | [] | `see below` | |
| replication_configuration | list(any) | [] | `see below` |  |
| versioning | object | `see vars.tf` | `see below` |  |
| server_side_encryption_configuration | object | `see vars.tf` | `see below` |  |
| acl | string | `private` | `authenticated-read` | https://docs.aws.amazon.com/AmazonS3/latest/userguide/acl-overview.html#canned-acl |
| public_access_block | object | `see vars.tf` | `see below` |  |
| bucket_policy | list(any) | [] | `see below` | additional bucket policy statement |

## Vars definitions
#### Lifecycle
For `lifecycle_rule` set variable in `terraform.tfvars.json` as:

```json
"lifecycle_rule": [{
  "prefix": "<prefix on which to apply rule>",
  "enabled": <true or false>,
  "abort_incomplete_multipart_upload_days": <days for deletion of failed multipar uploads, minimum 1>,
  "expiration": {
    "days": <days for current version expiration>,
    "expired_object_delete_marker": <true or false>
  },
  "transition_storage_class": {
    "days": <days for current version transition>,
    "storage_class": "<storage class for current version transition>"
  },
  "noncurrent_version_transition": {
    "days": <days for noncurrent version transition>,
    "storage_class": "<storage class for noncurrent version transition>"
  },
  "noncurrent_version_expiration_days": <days for noncurrent version expiration>
}]
```
#### Replication
For `replication_configuration` set variable in `terraform.tfvars.json` as:
```json
"replication_configuration": [{
  "role": "<ARN of Replication role>",
  "rules": {
    "delete_marker_replication_status": "<Enabled or Disabled>",
    "destination": {
      "bucket": "<destination bucket name>"
    },
    "filter": {
      "prefix": "<prefix to replicate>"
    },
    "status": "<Enabled or Disabled>"
  }
}]
```
#### Versioning
For `versioning` set variable in `terraform.tfvars.json` or ignore it as this is set to be default as:
```json
"versioning": {
  "enabled": true,
  "mfa_delete": false
}
```
#### Encryption
For `server_side_encryption_configuration` set variable in `terraform.tfvars.json` or ignore it as this is set to be default:
```json
"server_side_encryption_configuration": {
  "rule": {
    "apply_server_side_encryption_by_default": {
      "sse_algorithm": "AES-256"
    },
    "bucket_key_enabled": false
  }
}
```

#### Public access
Customize public access block
```json
"public_access_block": {
  "block_public_acls": true,
  "block_public_policy": true,
  "ignore_public_acls": true,
  "restrict_public_buckets": true
}
```

## Examples
#### `main.tf`
```hcl
module "aws_s3" {
  source = "github.com/variant-inc/terraform-aws-s3//s3?ref=v1"

  bucket_prefix       = var.bucket_prefix
  acl                 = var.acl
  force_destroy       = var.force_destroy
  bucket_policy       = var.bucket_policy
  public_access_block = var.public_access_block

  lifecycle_rule                       = var.lifecycle_rule
  replication_configuration            = var.replication_configuration
  versioning                           = var.versioning
  server_side_encryption_configuration = var.server_side_encryption_configuration
}
```

#### `terraform.tfvars.json`

```json
{
    "bucket_prefix":"test-bucket-",
    "force_destroy": false,
    "lifecycle_rule": [{
       "prefix":"config/",
       "enabled":true,
       "abort_incomplete_multipart_upload_days":30,
       "transition_storage_class":{
        "days":30,
        "storage_class":"STANDARD_IA"
     },
       "noncurrent_version_transition":{
          "days":60,
          "storage_class":"GLACIER"
       },
       "noncurrent_version_expiration_days": 90
    }]
 }
```

#### `provider.tf`

```terraform
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
        team: "DataOps",
        purpose: "s3",
        owner: "Luka"
      }
  }
}
```
#### `variables.tf`
copy ones from module

#### `outputs.tf`
```terraform
output "bucket_name" {
  value       = module.aws_s3.bucket_name
  description = "Name of the bucket name + prefix"
}

output "bucket_arn" {
  value       = module.aws_s3.bucket_arn
  description = "ARN of the bucket name + prefix"
}
```