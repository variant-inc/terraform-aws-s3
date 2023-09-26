#tfsec:ignore:aws-s3-encryption-customer-key
#tfsec:ignore:aws-s3-enable-bucket-logging
module "aws_s3" {
  #checkov:skip=CKV_AWS_300:Example bucket
  #checkov:skip=CKV_AWS_145:Example bucket
  source = "../../"

  bucket_prefix = "test-bucket-"
  force_destroy = false

  tags = {
    "environment" : "prod"
  }

  bucket_policy = [
    {
      "Sid" : "testpolicy",
      "Effect" : "Allow",
      "Principal" : { "Service" : "cloudtrail.amazonaws.com" },
      "Action" : "s3:GetBucketAcl"
    }
  ]

  lifecycle_rule = [{
    "prefix" : "staged/",
    "enabled" : true,
    "abort_incomplete_multipart_upload_days" : 1,
    "expiration" : [{
      "days" : 183,
      "expired_object_delete_marker" : true
    }],
    "transition_storage_class" : [{
      "days" : 7,
      "storage_class" : "INTELLIGENT_TIERING"
    }],
    "noncurrent_version_transition" : [{
      "days" : 15,
      "storage_class" : "STANDARD_IA"
    }],
    "noncurrent_version_expiration_days" : 92
    },
    {
      "prefix" : "staged2/",
      "enabled" : false,
      "expiration" : [{
        "days" : 30,
        "expired_object_delete_marker" : true
      }]
  }]
  enable_bucket_notification = true
}
