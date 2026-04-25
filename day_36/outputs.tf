output "bucket_arn" {
  description = "The Amazon Resource Name of the bucket"
  value       = aws_s3_bucket.success_bucket.arn
}

output "bucket_region" {
  value = aws_s3_bucket.success_bucket.region
}
