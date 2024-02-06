variable "bucket_prefix" {
  type        = string
  description = "Prefix for bucket name, AWS will append it with creation time and serial number"
}

variable "tags" {
  type        = map(string)
  description = "Tags for S3 bucket"
  default     = {}
}

variable "lifecycle_rule" {
  type        = any
  description = "Controlling bucket lifecycle rules, zero or more supported [doc](docs/lifecycle_rule.md)"
  default     = []
}

variable "force_destroy" {
  type        = bool
  description = "Allow force destruction of bucket, allows destroy even when bucket is not empty"
  default     = false
}

variable "bucket_policy" {
  type        = any
  description = "Additional bucket policy statements. Default policy allows only SSL requests"
  default     = []
}

variable "external_accounts" {
  type        = list(string)
  description = "List of external account for bucket read only access"
  default     = []
}

variable "default_expiration" {
  type        = any
  description = "Enable or disable default lifecycle policy for expiring objects and set days, enabled by default and expire objects after 180 days"
  default = {
    enabled = true
    days    = 180
  }
}
