# Terraform S3 Bucket

## Input Variables

 | Name               | Type         | Default  | Example                               | Notes                                         |
 | ------------------ | ------------ | -------- | ------------------------------------- | --------------------------------------------- |
 | bucket_prefix      | string       |          | test-bucket-                          |  Creates a unique bucket name                 |
 | force_destroy      | bool         |          | false                                 |                                               |
 | lifecycle_rule     | list(object) |          | `see below`                           |                                               |

For `lifecycle_rule` need to set in terraform.tfvars.json. Set the variable as

```bash
variable "lifecycle_rule" {
  type = list(object({
    prefix = string
    enabled = bool
    abort_incomplete_multipart_upload_days = number
    transition_storage_class = object({
      days = number
      storage_class = string
    })
    noncurrent_version_transition = object({
      days = number
      storage_class = string
    })
    noncurrent_version_expiration_days = number
  }))
  description = "A configuration of object lifecycle management"
  default = []
}
```

## Examples

```terraform
module "aws_s3" {
  source = "github.com/variant-inc/terraform-aws-s3//s3?ref=v1"

  bucket_prefix  = "test-bucket-"

  force_destroy  = false

  lifecycle_rule = [{
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

## Files

terraform.tfvars.json

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

provider.tf

```bash
provider "aws" {
  region = "us-west-2"
  default_tags {
    tags = {
        team: "DevOps",
        purpose: "s3",
        owner: "Bob"
      }
  }
}
```
