variable "bucket_prefix" {
  type        = string
  description = "Prefix of the s3 bucket"
}

variable "lifecycle_rule" {
  type = list(object({
    prefix                                 = string
    enabled                                = bool
    abort_incomplete_multipart_upload_days = number
    transition_storage_class = object({
      days          = number
      storage_class = string
    })
    noncurrent_version_transition = object({
      days          = number
      storage_class = string
    })
    noncurrent_version_expiration_days = number
  }))
  description = "A configuration of object lifecycle management"
  default     = []
}

variable "force_destroy" {
  type        = bool
  description = "Force destroy true|false"
}
