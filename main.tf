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

#tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "bucket" {
  #checkov:skip=CKV_AWS_145:Ignore Cross Replication
  #checkov:skip=CKV_AWS_144:Ignore Cross Replication
  #checkov:skip=CKV_AWS_18:Ignore Bucket Logging

  bucket_prefix = var.bucket_prefix
  tags          = var.tags

  lifecycle {
    ignore_changes = [
      replication_configuration
    ]
  }

  force_destroy = var.force_destroy
}

#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  #checkov:skip=CKV2_AWS_67: Ignore CMK encryption
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = var.versioning_status
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
          "AWS" : local.external_accounts
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

resource "aws_s3_bucket_lifecycle_configuration" "bucket" {
  count  = length(var.lifecycle_rule) != 0 || try(var.default_expiration.enabled, false) ? 1 : 0
  bucket = aws_s3_bucket.bucket.id

  rule {
    id     = "default-expiration"
    status = try(var.default_expiration.enabled, false) ? "Enabled" : "Disabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }

    expiration {
      days = try(var.default_expiration.days, 180)
    }

    noncurrent_version_expiration {
      noncurrent_days = 10
    }
  }

  rule {
    id     = "default-delete-expired"
    status = "Enabled"

    expiration {
      expired_object_delete_marker = true
    }
  }

  dynamic "rule" {
    for_each = var.lifecycle_rule
    iterator = lifecycle_rule
    content {
      id     = "rule-${lifecycle_rule.key}"
      status = lookup(lifecycle_rule.value, "enabled", null) ? "Enabled" : "Disabled"

      filter {
        prefix = lookup(lifecycle_rule.value, "prefix", null)
      }

      dynamic "abort_incomplete_multipart_upload" {
        for_each = lookup(lifecycle_rule.value, "abort_incomplete_multipart_upload_days", {}) != {} ? { dummy = "dummy" } : {}
        content {
          days_after_initiation = lookup(lifecycle_rule.value, "abort_incomplete_multipart_upload_days", null)
        }
      }

      dynamic "expiration" {
        for_each = lookup(lifecycle_rule.value, "expiration_days", {}) != {} ? { dummy = "dummy" } : {}
        content {
          days = lookup(lifecycle_rule.value, "expiration_days", 0)
        }
      }

      dynamic "transition" {
        for_each = lookup(lifecycle_rule.value, "transition_storage_class", {})
        content {
          days          = lookup(transition.value, "days", null)
          storage_class = lookup(transition.value, "storage_class", "INTELLIGENT_TIERING")
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = lookup(lifecycle_rule.value, "noncurrent_version_transition", {})
        content {
          noncurrent_days = lookup(noncurrent_version_transition.value, "days", null)
          storage_class   = lookup(noncurrent_version_transition.value, "storage_class", "INTELLIGENT_TIERING")
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = lookup(lifecycle_rule.value, "noncurrent_version_expiration_days", {}) != {} ? { dummy = "dummy" } : {}
        content {
          noncurrent_days = lookup(lifecycle_rule.value, "noncurrent_version_expiration_days", null)
        }
      }
    }
  }
}
