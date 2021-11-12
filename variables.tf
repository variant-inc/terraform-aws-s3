variable "bucket_prefix" {
  type        = string
  description = "Prefix of the s3 bucket"
}

variable "lifecycle_rule" {
  type = list(any)
  description = "A configuration of object lifecycle management"
  default     = []
}

variable "replication_configuration" {
  type = list(any)
  description = "Optional configuration for replication"
  default = []
}

variable "versioning" {
  type = object({
    enabled = bool
    mfa_delete = bool
  })
  description = "Configuration for versioning"
  default = {
    enabled = true
    mfa_delete = false
  }
}

variable "server_side_encryption_configuration" {
  type = object({
    rule = object({
      apply_server_side_encryption_by_default = any
      bucket_key_enabled = bool
    })
  })
  description = "SSE configuration. Enabled with S3 managed key by default."
  default = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorythm = "AES256"
      }
      bucket_key_enabled = false
    }
  }
}

variable "force_destroy" {
  type        = bool
  description = "Force destroy true|false"
  default = false
}

variable "acl" {
  type = string
  description = "Canned ACL of a bucket https://docs.aws.amazon.com/AmazonS3/latest/userguide/acl-overview.html#canned-acl. Defaults to private."
  default = "private"
}

variable "public_access_block" {
  type = object({
    block_public_acls       = bool
    ignore_public_acls      = bool
    block_public_policy     = bool
    restrict_public_buckets = bool
  })
  description = "Set public access blocking."
  default = {
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
  }
}

variable "bucket_policy" {
  type = list(any)
  description = "Additional bucket policy statements."
  default = []
}