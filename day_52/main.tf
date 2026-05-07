provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true
  endpoints { s3 = "http://localhost:4566" }
}

resource "aws_s3_bucket" "multi_bucket" {
  # This tells Terraform to create 3 of these
  count  = 3 
  
  # We use the index (0, 1, 2) to make the names unique
  bucket = "my-scaling-bucket-${count.index}-2026"
}

output "all_bucket_names" {
  # The * (splat) operator tells Terraform to list all of them
  value = aws_s3_bucket.multi_bucket[*].bucket
}
