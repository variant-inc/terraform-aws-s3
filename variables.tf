variable "bucket_prefix" {
  type        = string
  description = "Prefix of the s3 bucket"
}

variable "tags" {
  type        = map(string)
  description = "Tags for S3 bucket"
  default     = {}
}

variable "lifecycle_rule" {
  type        = list(any)
  description = "A configuration of object lifecycle management"
  default     = []
}

variable "force_destroy" {
  type        = bool
  description = "Force destroy true|false"
  default     = false
}

variable "bucket_policy" {
  type        = any
  description = "Additional bucket policy statements."
  default     = []
}