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

resource "aws_s3_bucket" "project_buckets" {
  # We define a set of unique names
  for_each = toset(["frontend", "backend", "logs"])

  # each.value refers to the current name in the loop
  bucket   = "company-${each.value}-storage-2026"
}

output "bucket_map" {
  # This shows the mapping of name to bucket ID
  value = { for k, v in aws_s3_bucket.project_buckets : k => v.id }
}
