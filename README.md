# Terraform S3 Bucket module

- [Terraform S3 Bucket module](#terraform-s3-bucket-module)
  - [Input Variables](#input-variables)
  - [Variable definitions](#variable-definitions)
      - [lifecycle_rule](#lifecycle_rule)
      - [replication_configuration](#replication_configuration)
      - [versioning](#versioning)
      - [server_side_encryption_configuration](#server_side_encryption_configuration)
      - [public_access_block](#public_access_block)
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

## Variable definitions
#### lifecycle_rule
Controlling bucket lifecycle rules, zero or more supported.
Each rule object has to have at least one of actions specified, others can be ommited: `expiration`, `abort_incomplete_multipart_upload_days`, `transition_storage_class`, `noncurrent_version_transition`, `noncurrent_version_expiration_days`.
Storage classes for transition: `STANDARD`, `REDUCED_REDUNDANCY`, `ONEZONE_IA`, `INTELLIGENT_TIERING`, `GLACIER`, `DEEP_ARCHIVE` or `STANDARD_IA`.

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

Default:
```json
"lifecycle_rule": []
```

#### replication_configuration
Controlling bucket replication configuration, zero or one configuration supported.
`filter` can be ommited or leave prefix as `""` for replication of whole bucket.
TODO: `role` will be able to ommit once code is ready to automatically create role.
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

Default:
```json
"replication_configuration": []
```
#### versioning
Controll bucket versioning.
```json
"versioning": {
  "enabled": <true or false>,
  "mfa_delete": <true or false>
}
```

Default:
```json
"versioning": {
  "enabled": true,
  "mfa_delete": false
}
```

#### server_side_encryption_configuration
Controlling bucket encryption.
If `sse_algorithm` is `aws:kms`, `kms_master_key_id` can be specified or ommited.
If `kms_master_key_id` is ommited it defaults to `aws/s3`.
```json
"server_side_encryption_configuration": {
  "rule": {
    "apply_server_side_encryption_by_default": {
      "sse_algorithm": "<AES-256 or aws:kms>",
      "kms_master_key_id": "<has to be set if sse_algorithm is aws:kms>"
    },
    "bucket_key_enabled": <true or false>
  }
}
```

Default:
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

#### public_access_block
Controlling public access of a bucket.
```json
"public_access_block": {
  "block_public_acls": <true or false>,
  "block_public_policy": <true or false>,
  "ignore_public_acls": <true or false>,
  "restrict_public_buckets": <true or false>
}
```

Default:
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
```terraform
module "aws_s3" {
  source = "github.com/variant-inc/terraform-aws-s3?ref=v2"

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
    "prefix": "staged/",
    "enabled": true,
    "abort_incomplete_multipart_upload_days": 1,
    "expiration": {
      "days": 183,
      "expired_object_delete_marker": true
    },
    "transition_storage_class": {
      "days": 7,
      "storage_class": "INTELLIGENT_TIERING"
    },
    "noncurrent_version_transition": {
      "days": 15,
      "storage_class": "STANDARD_IA"
    },
    "noncurrent_version_expiration_days": 92
  }],
  "replication_configuration": [{
    "role": "arn:aws:iam::319244236588:role/service-role/s3-replication-test-role",
    "rules": {
      "delete_marker_replication_status": "Enabled",
      "destination": {
        "bucket": "test-bucket-replica"
      },
      "filter": {
        "prefix": "some_prefix/"
      },
      "status": "Enabled"
    }
  }],
  "versioning": {
    "enabled": true,
    "mfa_delete": false
  },
  "server_side_encryption_configuration": {
    "rule": {
      "apply_server_side_encryption_by_default": {
        "sse_algorithm": "AES-256"
      },
      "bucket_key_enabled": false
    }
  },
  "public_access_block": {
    "block_public_acls": true,
    "block_public_policy": true,
    "ignore_public_acls": true,
    "restrict_public_buckets": true
  }
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