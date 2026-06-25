provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_key"
  secret_key                  = "mock_secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3 = "http://localhost:4567"
  }
}

resource "aws_s3_bucket" "automation_test_bucket" {
  bucket = "vois-automation-pipeline-bucket"
  tags = {
    Name        = "vOIS-CI-CD-Test"
    Environment = "Automation"
  }
}
# FIX 1: Enforce Mandatory Server-Side Encryption (Remediates Trivy S3 Encryption check)
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_encryption" {
  bucket = aws_s3_bucket.automation_test_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# FIX 2: Enable Absolute Public Access Blocks (Remediates Trivy S3 Public Exposure check)
resource "aws_s3_bucket_public_access_block" "secure_perimeter" {
  bucket = aws_s3_bucket.automation_test_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
