output "bucket_name" {
  value       = module.aws_s3.bucket_name
  description = "Name of the bucket name + prefix"
}

output "bucket_arn" {
  value       = module.aws_s3.bucket_arn
  description = "ARN of the bucket name + prefix"
}