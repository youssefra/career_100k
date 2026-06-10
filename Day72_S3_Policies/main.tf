provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_key"
  secret_key                  = "mock_secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true # Maintain our local DNS path addressing fix

  endpoints {
    s3 = "http://localhost:4567"
  }
}

# 1. The Core Production S3 Bucket
resource "aws_s3_bucket" "vois_secure_bucket" {
  bucket = "vois-secure-compliance-data"

  tags = {
    Name        = "vOIS-Secure-Compliance-Bucket"
    Environment = "Production"
  }
}

# 2. Baseline Public Access Block
resource "aws_s3_bucket_public_access_block" "public_block" {
  bucket = aws_s3_bucket.vois_secure_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. THE S3 BUCKET POLICY: Attaching an explicit access control layer directly to the bucket
resource "aws_s3_bucket_policy" "allow_read_access" {
  bucket = aws_s3_bucket.vois_secure_bucket.id

  # We use jsonencode to write standard, native AWS IAM JSON syntax directly inside HCL
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSpecificRoleReadOnly"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::111122223333:role/vois-analytics-app-role" # The specific target workload principal
        }
        Action = [
          "s3:GetObject",  # Granting permission to read individual objects
          "s3:ListBucket"  # Granting permission to look inside the bucket prefix path
        ]
        Resource = [
          "arn:aws:s3:::vois-secure-compliance-data",    # Target the bucket container itself (required for listing)
          "arn:aws:s3:::vois-secure-compliance-data/*"  # Target everything INSIDE the bucket container (required for getting objects)
        ]
      }
    ]
  })
}
