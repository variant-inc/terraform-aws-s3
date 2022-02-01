module "aws_s3" {
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
  }]
}
