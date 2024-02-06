#tfsec:ignore:aws-s3-encryption-customer-key
#tfsec:ignore:aws-s3-enable-bucket-logging
module "aws_s3" {
  #checkov:skip=CKV_AWS_300:Example bucket
  #checkov:skip=CKV_AWS_145:Example bucket
  source = "../../"

  bucket_prefix = "test-bucket"
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

  default_expiration = {
    enabled = true
    days    = 50
  }

  lifecycle_rule = [
    {
      "prefix" : "staged/",
      "enabled" : true,
      "abort_incomplete_multipart_upload_days" : 1,
      "expiration_days" : 30
    },
    {
      "enabled" : true,
      "noncurrent_version_transition" : [{
        "days" : 15
      }],
      "noncurrent_version_expiration_days" : 20,
      "transition_storage_class" : [
        {
          "days" : 50,
          "storage_class" : "STANDARD_IA"
        },
        {
          "days" : 81,
          "storage_class" : "GLACIER"
        }
      ]
    }
  ]
}
