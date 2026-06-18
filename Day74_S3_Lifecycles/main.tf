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

# 1. The Core Enterprise Archival Bucket
resource "aws_s3_bucket" "vois_logging_bucket" {
  bucket = "vois-global-application-logs"

  tags = {
    Name        = "vOIS-Global-Application-Logs"
    Environment = "Production"
  }
}

# 2. AUTOMATED LIFECYCLE MANAGEMENT REVOLUTION
resource "aws_s3_bucket_lifecycle_configuration" "log_lifecycle" {
  bucket = aws_s3_bucket.vois_logging_bucket.id

  rule {
    id     = "auto-archive-and-cleanup-lifecycle"
    status = "Enabled"

    # Rule applies to any object uploaded under the "logs/" virtual folder prefix path
    filter {
      prefix = "logs/"
    }

    # Transition Phase 1: Move objects to Infrequent Access after 30 days of inactivity
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transition Phase 2: Demote objects to Glacier Deep Archive after 90 days for long-term storage
    transition {
      days          = 90
      storage_class = "DEEP_ARCHIVE"
    }

    # Expiration Phase: Permanently delete logs after 365 days for cost engineering and GDPR compliance
    expiration {
      days = 365
    }
  }
timeouts {
    create = "5m"
    update = "5m"
  }
}
