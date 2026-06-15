provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_key"
  secret_key                  = "mock_secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true # Keep local DNS routing fix

  endpoints {
    s3  = "http://localhost:4567"
    kms = "http://localhost:4567"
  }
}

# 1. Dedicated Customer Managed Key (CMK) for Storage Encryption
resource "aws_kms_key" "vois_storage_key" {
  description             = "KMS Key for hardening vOIS production storage data lakes"
  deletion_window_in_days = 7
  enable_key_rotation     = true # Enterprise best-practice: automatically rotate the key yearly

  tags = {
    Name        = "vOIS-Storage-Encryption-Key"
    Environment = "Production"
  }
}

# 2. The Hardened S3 Data Bucket
resource "aws_s3_bucket" "vois_encrypted_bucket" {
  bucket = "vois-encrypted-compliance-vault"

  tags = {
    Name        = "vOIS-Encrypted-Compliance-Vault"
    Environment = "Production"
  }
}

# 3. ENFORCING ENCRYPTION RULESET: Binds our KMS key to the bucket container
resource "aws_s3_bucket_server_side_encryption_configuration" "sse_config" {
  bucket = aws_s3_bucket.vois_encrypted_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.vois_storage_key.arn
      sse_algorithm     = "aws:kms" # Explicitly use SSE-KMS instead of default SSE-S3
    }
    bucket_key_enabled = true # Reduces KMS API costs by caching data keys at the S3 bucket layer
  }
}
