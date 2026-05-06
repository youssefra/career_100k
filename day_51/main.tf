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

# 1. THE DATA SOURCE (Looking for existing info)
data "aws_s3_bucket" "found_bucket" {
  bucket = "external-bucket-2026"
}

# 2. USING THE DATA (Creating a file in that "found" bucket)
resource "aws_s3_object" "data_log" {
  bucket  = data.aws_s3_bucket.found_bucket.id
  key     = "found_you.txt"
  content = "Terraform found this bucket using a Data Source!"
}

# 3. OUTPUT THE INFO
output "existing_bucket_arn" {
  value = data.aws_s3_bucket.found_bucket.arn
}
