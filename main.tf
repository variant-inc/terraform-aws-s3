locals {
  # Adding resource ARN to custom policies
  # TODO: check IAM and policy update permissions, got access denied even with admin permission and via console
  policy = []
  # policy = [
  #   for i in var.bucket_policy: merge(i,  {"Resource" = [
  #         format("arn:aws:s3:::%s", aws_s3_bucket.bucket.id),
  #         format("arn:aws:s3:::%s/*", aws_s3_bucket.bucket.id)
  #       ]})
  #   ]
}
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "bucket" {
  #ts:skip=AWS.S3Bucket.LM.MEDIUM.0078 need to skip this rule

  bucket_prefix = var.bucket_prefix
  acl           = var.acl

  force_destroy = var.force_destroy

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rule
    content {
      enabled = lookup(lifecycle_rule.value, "enabled", null)

      prefix = lookup(lifecycle_rule.value, "prefix", null)

      abort_incomplete_multipart_upload_days = lookup(lifecycle_rule.value, "abort_incomplete_multipart_upload_days", null)

      dynamic expiration {
        for_each = lookup(lifecycle_rule.value, "expiration", {})
        iterator = expiration_rule
        content {
          days                          = lookup(expiration_rule.value, "days", null)
          expired_object_delete_marker  = lookup(expiration_rule.value, "days", null) != null ? false : lookup(expiration_rule.value, "expired_object_delete_marker", null)
        }
      }
      dynamic transition {
        for_each = lookup(lifecycle_rule.value, "transition_storage_class", {})
        iterator = transition_rule

        content {
          days          = lookup(transition_rule.value, "days", null)
          storage_class = lookup(transition_rule.value, "storage_class", "INTELLIGENT_TIERING")
        }
      }

      dynamic noncurrent_version_transition {
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

  dynamic "replication_configuration" {
    for_each = var.replication_configuration
    
    content {
      role = length(lookup(replication_configuration.value, "role", "")) == 0 ? format("arn:aws:iam::%s:role/service-role/%s",data.aws_caller_identity.current.account_id, format("%s-to-%s-replication-role", var.bucket_prefix, element(split(":", var.replication_configuration[0]["rules"]["destination"]["bucket"]), length(split(":", var.replication_configuration[0]["rules"]["destination"]["bucket"]))-1))) : lookup(replication_configuration.value, "role", "")
      rules {
        id = format("%s-replication-rule", var.bucket_prefix)
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
        kms_master_key_id = lookup(var.server_side_encryption_configuration["rule"]["apply_server_side_encryption_by_default"], "sse_algorythm", "AES256") != "AES256" ? lookup(var.server_side_encryption_configuration["rule"]["apply_server_side_encryption_by_default"], "kms_master_key_id", "aws/s3") : null
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
    local.policy)
  })
}

resource "aws_s3_bucket_object" "object_staging" {
  bucket = aws_s3_bucket.bucket.id
  key    = "staging/"
}

resource "aws_s3_bucket_object" "object_archive" {
  bucket = aws_s3_bucket.bucket.id
  key    = "archive/"
}

resource "aws_s3_bucket_object" "object_raw" {
  bucket = aws_s3_bucket.bucket.id
  key    = "raw/"
}

resource "aws_s3_bucket_object" "object_governed" {
  bucket = aws_s3_bucket.bucket.id
  key    = "governed/"
}

resource "aws_iam_role" "replication_role" {
  count = length(var.replication_configuration) == 1 && length(lookup(var.replication_configuration[0], "role", "")) == 0 ? 1 : 0
  name = format("%s-to-%s-replication-role", var.bucket_prefix, element(split(":", var.replication_configuration[0]["rules"]["destination"]["bucket"]), length(split(":", var.replication_configuration[0]["rules"]["destination"]["bucket"]))-1))
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name = "replication-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetReplicationConfiguration",
            "s3:ListBucket"
          ],
          Resource = [
            format("arn:aws:s3:::%s", aws_s3_bucket.bucket.id)
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "s3:GetObjectVersionForReplication",
            "s3:GetObjectVersionAcl",
            "s3:GetObjectVersionTagging"
          ]
          Resource = [
            format("arn:aws:s3:::%s/*", aws_s3_bucket.bucket.id)
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "s3:ReplicateObject",
            "s3:ReplicateDelete",
            "s3:ReplicateTags"
          ]
          Resource = format("%s/*", var.replication_configuration[0]["rules"]["destination"]["bucket"])
        }
      ]
    })
  }
}