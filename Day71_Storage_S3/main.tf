provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_key"
  secret_key                  = "mock_secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  s3_use_path_style           = true
  skip_requesting_account_id  = true

  endpoints {
    s3 = "http://localhost:4567"
  }
}

# 1. The Core Enterprise S3 Bucket
resource "aws_s3_bucket" "vois_data_bucket" {
  bucket = "vois-enterprise-global-data-lake"

  tags = {
    Name        = "vOIS-Enterprise-Data-Lake"
    Environment = "Production"
    Pillar      = "Data-Engineering"
  }
}

# 2. Enable Bucket Versioning (Protects against accidental deletions/overwrites)
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.vois_data_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. Explicit Public Access Block (Security baseline to prevent data leaks)
resource "aws_s3_bucket_public_access_block" "public_block" {
  bucket = aws_s3_bucket.vois_data_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
