resource "aws_s3_bucket" "bucket" {
  #ts:skip=AWS.S3Bucket.LM.MEDIUM.0078 need to skip this rule

  bucket_prefix = var.bucket_prefix
  acl           = "private"

  force_destroy = var.force_destroy

  lifecycle {
    ignore_changes = [
      replication_configuration
    ]
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rule
    content {
      enabled = lookup(lifecycle_rule.value, "enabled", null)

      prefix = lookup(lifecycle_rule.value, "prefix", null)

      abort_incomplete_multipart_upload_days = lookup(lifecycle_rule.value, "abort_incomplete_multipart_upload_days", null)

      transition {
        days          = lookup(lookup(lifecycle_rule.value, "transition_storage_class", {}), "days", null)
        storage_class = lookup(lookup(lifecycle_rule.value, "transition_storage_class", {}), "storage_class", null)
      }

      noncurrent_version_transition {
        days          = lookup(lookup(lifecycle_rule.value, "noncurrent_version_transition", {}), "days", null)
        storage_class = lookup(lookup(lifecycle_rule.value, "noncurrent_version_transition", {}), "storage_class", null)
      }

      noncurrent_version_expiration {
        days = lookup(lifecycle_rule.value, "noncurrent_version_expiration_days", null)
      }
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }

}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "bucket" {
  depends_on = ["aws_s3_bucket_public_access_block.bucket"]
  bucket = aws_s3_bucket.bucket.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression's result to valid JSON syntax.
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "S3BucketPolicy",
    "Statement" : [
      {
        "Sid" : "AllowSSLRequestsOnly",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          join("", ["arn:aws:s3:::", aws_s3_bucket.bucket.id, ""]),
          join("", ["arn:aws:s3:::", aws_s3_bucket.bucket.id, "/*"])
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      }
    ]
  })
}
