output "bucket_name" {
  value       = aws_s3_bucket.bucket.bucket
  description = "Name of the bucket name + prefix"
}

output "bucket_arn" {
  value       = aws_s3_bucket.bucket.arn
  description = "ARN of the bucket name + prefix"
}
