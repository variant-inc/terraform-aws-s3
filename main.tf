resource "aws_s3_bucket" "bucket" {
  #ts:skip=AWS.S3Bucket.LM.MEDIUM.0078 need to skip this rule

  bucket_prefix = var.bucket_prefix
  acl           = var.acl

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

      expiration {
        days                          = lookup(lookup(lifecycle_rule.value, "expiration", {}), "days", null)
        expired_object_delete_marker  = lookup(lookup(lifecycle_rule.value, "expiration", {}), "expired_object_delete_marker", null)
      }
      transition {
        days          = lookup(lookup(lifecycle_rule.value, "transition_storage_class", {}), "days", null)
        storage_class = lookup(lookup(lifecycle_rule.value, "transition_storage_class", {}), "storage_class", "INTELLIGENT_TIERING")
      }

      noncurrent_version_transition {
        days          = lookup(lookup(lifecycle_rule.value, "noncurrent_version_transition", {}), "days", null)
        storage_class = lookup(lookup(lifecycle_rule.value, "noncurrent_version_transition", {}), "storage_class", "INTELLIGENT_TIERING")
      }

      noncurrent_version_expiration {
        days = lookup(lifecycle_rule.value, "noncurrent_version_expiration_days", null)
      }
    }
  }

  dynamic "replication_configuration" {
    for_each = var.replication_configuration
    
    content {
      # TODO: create replication role automatically if not specified in config
      role = lookup(replication_configuration.value, "role", null)
      rules {
        delete_marker_replication_status = lookup(lookup(replication_configuration.value, "rules", {}), "delete_marker_replication_status", null)
        destination {
          bucket = lookup(lookup(lookup(replication_configuration.value, "rules", {}), "destination", {}), "bucket", null)
        }
        filter {
          prefix = lookup(lookup(lookup(replication_configuration.value, "rules", {}), "filter", {}), "prefix", null)
        }
        status = lookup(lookup(replication_configuration.value, "rules", {}), "status", null)
      }
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = lookup(var.server_side_encryption_configuration["rule"]["apply_server_side_encryption_by_default"], "sse_algorythm", "AES256")
        kms_master_key_id = lookup(var.server_side_encryption_configuration["rule"]["apply_server_side_encryption_by_default"], "kms_master_key_id", null)
      }
      bucket_key_enabled = lookup(var.server_side_encryption_configuration["rule"], "bucket_key_enabled", false)
    }
  }

  versioning {
    enabled = lookup(var.versioning, "enabled", true)
    mfa_delete = lookup(var.versioning, "mfa_delete", false)
  }

}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = lookup(var.public_access_block, "block_public_acls", true)
  ignore_public_acls      = lookup(var.public_access_block, "ignore_public_acls", true)
  block_public_policy     = lookup(var.public_access_block, "block_public_policy", true)
  restrict_public_buckets = lookup(var.public_access_block, "restrict_public_buckets", true)
}

resource "aws_s3_bucket_policy" "bucket" {
  depends_on = [aws_s3_bucket_public_access_block.bucket]
  bucket     = aws_s3_bucket.bucket.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression's result to valid JSON syntax.
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "S3BucketPolicy",
    "Statement" : concat([
      {
        "Sid" : "AllowSSLRequestsOnly",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          format("arn:aws:s3:::%s", aws_s3_bucket.bucket.id),
          format("arn:aws:s3:::%s/*", aws_s3_bucket.bucket.id)
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      }
    ],
    var.bucket_policy)
  })
}

#TODO: create default folders in S3 bucket - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object