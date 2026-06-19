variable "is_localstack" {
  type        = bool
  default     = true
  description = "Set to true to bypass complex multi-region replication engine emulation on local free tier"
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_key"
  secret_key                  = "mock_secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3  = "http://localhost:4567"
    iam = "http://localhost:4567"
  }
}

# 1. IAM Role allowing S3 to assume the replication identity
resource "aws_iam_role" "replication_role" {
  name = "vois-storage-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
      }
    ]
  })
}

# 2. IAM Policy granting read/write cross-region capabilities
resource "aws_iam_policy" "replication_policy" {
  name = "vois-storage-replication-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::vois-primary-production-vault"
      },
      {
        Action   = ["s3:GetObjectVersionForReplication", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::vois-primary-production-vault/*"
      },
      {
        Action   = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::vois-dr-disaster-recovery-vault/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "replication_attach" {
  role       = aws_iam_role.replication_role.name
  policy_arn = aws_iam_policy.replication_policy.arn
}

# 3. Primary Production Source Bucket (US-EAST-1)
resource "aws_s3_bucket" "primary_vault" {
  bucket = "vois-primary-production-vault"
  tags   = { Name = "vOIS-Primary-Vault", Environment = "Production" }
}

resource "aws_s3_bucket_versioning" "primary_versioning" {
  bucket = aws_s3_bucket.primary_vault.id
  versioning_configuration { status = "Enabled" }
}

# 4. Secondary Disaster Recovery Destination Bucket (US-WEST-2 simulation)
resource "aws_s3_bucket" "dr_vault" {
  bucket = "vois-dr-disaster-recovery-vault"
  tags   = { Name = "vOIS-DR-Vault", Environment = "Disaster-Recovery" }
}

resource "aws_s3_bucket_versioning" "dr_versioning" {
  bucket = aws_s3_bucket.dr_vault.id
  versioning_configuration { status = "Enabled" }
}

# 5. Cross-Region Replication Engine Mapping
resource "aws_s3_bucket_replication_configuration" "replication_engine" {
  # We use our variable framework to bypass local free-tier engine constraints cleanly
  count = var.is_localstack ? 0 : 1

  depends_on = [aws_s3_bucket_versioning.primary_versioning, aws_s3_bucket_versioning.dr_versioning]

  role   = aws_iam_role.replication_role.arn
  bucket = aws_s3_bucket.primary_vault.id

  rule {
    id     = "cross-region-dr-sync"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.dr_vault.arn
      storage_class = "STANDARD"
    }
  }
}
