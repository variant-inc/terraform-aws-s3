# Terraform S3 Bucket

- [Terraform S3 Bucket](#terraform-s3-bucket)
  - [Input Variables](#input-variables)
  - [Variable definitions](#variable-definitions)
      - [bucket_prefix](#bucket_prefix)
      - [force_destroy](#force_destroy)
      - [lifecycle_rule](#lifecycle_rule)
      - [bucket_policy](#bucket_policy)
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
| force_destroy | bool | `false` | `true` | |
| lifecycle_rule | list(object) | [] | `see below` | |
| bucket_policy | list(any) | [] | `see below` | additional bucket policy statement |

## Variable definitions
#### bucket_prefix
Prefix for bucket name, AWS will append it with creation time and serial number.
```json
"bucket_prefix": "<bucket prefix>"
```

#### force_destroy
Allow force destruction of bucket, allows destroy even when bucket is not empty.
```json
"force_destroy": <true or false>
```

Default:
```json
"force_destroy": false
```

#### lifecycle_rule
Controlling bucket lifecycle rules, zero or more supported.
Each rule object has to have at least one of actions specified, others can be ommited: `expiration`, `abort_incomplete_multipart_upload_days`, `transition_storage_class`, `noncurrent_version_transition`, `noncurrent_version_expiration_days`.
Storage classes for transition: `STANDARD`, `REDUCED_REDUNDANCY`, `ONEZONE_IA`, `INTELLIGENT_TIERING`, `GLACIER`, `DEEP_ARCHIVE` or `STANDARD_IA`.

```json
"lifecycle_rule": [{
  "prefix": "<prefix on which to apply rule>",
  "enabled": <true or false>,
  "abort_incomplete_multipart_upload_days": <days for deletion of failed multipar uploads, minimum 1>,
  "expiration": [{
    "days": <days for current version expiration>,
    "expired_object_delete_marker": <true or false>
  }],
  "transition_storage_class": [{
    "days": <days for current version transition>,
    "storage_class": "<storage class for current version transition>"
  }],
  "noncurrent_version_transition": [{
    "days": <days for noncurrent version transition>,
    "storage_class": "<storage class for noncurrent version transition>"
  }],
  "noncurrent_version_expiration_days": <days for noncurrent version expiration>
}]
```

Default:
```json
"lifecycle_rule": []
```

#### bucket_policy
> **WARNING**: Do not use for now, further investigation needed.

Additional bucket policy statements.
Default policy allows only SSL requests.
```json
"bucket_policy": [
  {
    "Sid" : "<policy SID>",
    "Effect" : "<Allow or Deny>",
    "Principal" : "<single or list of principals>",
    "Action" : "<single action or list of actions>",
    "Condition" : {
      <any kind of supported condition or remove this block>
    }
  }
]
```

Default:
```json
"bucket_policy": []
```

## Examples
#### `main.tf`
```terraform
module "aws_s3" {
  source = "github.com/variant-inc/terraform-aws-s3?ref=v1"

  bucket_prefix   = var.bucket_prefix
  force_destroy   = var.force_destroy
  bucket_policy   = var.bucket_policy
  lifecycle_rule  = var.lifecycle_rule
}
```

#### `terraform.tfvars.json`

```json
{
  "bucket_prefix":"test-bucket-",
  "force_destroy": false,
  "lifecycle_rule": [{
    "prefix": "staged/",
    "enabled": true,
    "abort_incomplete_multipart_upload_days": 1,
    "expiration": [{
      "days": 183,
      "expired_object_delete_marker": true
    }],
    "transition_storage_class": [{
      "days": 7,
      "storage_class": "INTELLIGENT_TIERING"
    }],
    "noncurrent_version_transition": [{
      "days": 15,
      "storage_class": "STANDARD_IA"
    }],
    "noncurrent_version_expiration_days": 92
  }],
  "bucket_policy": [
    {
      "Sid" : "test_allow",
      "Effect" : "Allow",
      "Principal" : "*",
      "Action" : "s3:*"
    },
    {
      "Sid" : "test_deny",
      "Effect" : "Deny",
      "Principal" : "*",
      "Action" : "s3:GetObject"
    }
  ]
}
```

Basic
#####
```json
{
  "bucket_prefix":"test-bucket-"
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