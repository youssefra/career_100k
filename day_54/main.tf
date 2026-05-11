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

# THE LOCALS BLOCK
# We use this to combine multiple things into one clean name
locals {
  service_name = "payment-processor"
  owner        = "youssef"
  # We combine them here so we don't have to type this long string everywhere
  common_name  = "${local.owner}-${local.service_name}-2026"
}

resource "aws_s3_bucket" "local_demo" {
  bucket = local.common_name # Much cleaner than typing the whole string!
}

resource "aws_s3_object" "status_file" {
  bucket  = aws_s3_bucket.local_demo.id
  key     = "status.txt"
  content = "Managed by ${local.owner} for the ${local.service_name} service."
}
