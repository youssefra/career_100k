output "bucket_id" {
  description = "The unique ID of the bucket we created"
  value       = aws_s3_bucket.app_storage.id
}

output "bucket_arn" {
  description = "The Amazon Resource Name (ARN) for security policies"
  value       = aws_s3_bucket.app_storage.arn
}
