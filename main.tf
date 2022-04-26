locals {
  # Adding resource ARN to custom policies
  policy = [
    for i in var.bucket_policy : merge(i, { "Resource" = [
      format("arn:aws:s3:::%s", aws_s3_bucket.bucket.id),
      format("arn:aws:s3:::%s/*", aws_s3_bucket.bucket.id)
    ] })
  ]

  external_accounts = [
    for a in var.external_accounts : format("arn:aws:iam::%s:root", a)
  ]
}

resource "aws_s3_bucket" "bucket" {
  #ts:skip=AWS.S3Bucket.LM.MEDIUM.0078 need to skip this rule

  bucket_prefix = var.bucket_prefix
  tags          = var.tags
  acl           = "private"

  lifecycle {
    ignore_changes = [
      replication_configuration
    ]
  }

  force_destroy = var.force_destroy

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rule
    content {
      enabled = lookup(lifecycle_rule.value, "enabled", null)

      prefix = lookup(lifecycle_rule.value, "prefix", null)

      abort_incomplete_multipart_upload_days = lookup(lifecycle_rule.value, "abort_incomplete_multipart_upload_days", null)

      dynamic "expiration" {
        for_each = lookup(lifecycle_rule.value, "expiration", {})
        iterator = expiration_rule
        content {
          days                         = lookup(expiration_rule.value, "days", null)
          expired_object_delete_marker = lookup(expiration_rule.value, "days", null) != null ? false : lookup(expiration_rule.value, "expired_object_delete_marker", null)
        }
      }
      dynamic "transition" {
        for_each = lookup(lifecycle_rule.value, "transition_storage_class", {})
        iterator = transition_rule

        content {
          days          = lookup(transition_rule.value, "days", null)
          storage_class = lookup(transition_rule.value, "storage_class", "INTELLIGENT_TIERING")
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = lookup(lifecycle_rule.value, "noncurrent_version_transition", {})
        iterator = nc_transition_rule

        content {
          days          = lookup(nc_transition_rule.value, "days", null)
          storage_class = lookup(nc_transition_rule.value, "storage_class", "INTELLIGENT_TIERING")
        }
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
  depends_on = [aws_s3_bucket_public_access_block.bucket]
  bucket     = aws_s3_bucket.bucket.id

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
      },
      ],
      length(local.external_accounts) == 0 ? [] : [{
        "Sid" : "ReadOnlyExternalAccounts",
        "Effect" : "Allow",
        "Principal" : {
          "AWS": local.external_accounts
        },
        "Action" : "s3:GetObject*",
        "Resource" : [
          format("arn:aws:s3:::%s/*", aws_s3_bucket.bucket.id)
        ]
      }],
    local.policy)
  })
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket      = aws_s3_bucket.bucket.id
  eventbridge = true
}
