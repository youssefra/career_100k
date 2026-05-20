provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_key"
  secret_key                  = "mock_secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam = "http://localhost:4567"
    sts = "http://localhost:4567"
  }
}

# 1. Create the Cross-Account IAM Role
resource "aws_iam_role" "cross_account_audit_role" {
  name = "CrossAccountAuditRole"

  # The Trust Policy: This tells AWS WHO is allowed to assume this role.
  # Here, we are stating that a specific external AWS Account (123456789012) has permission.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccountAToAssume"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# 2. Attach Read-Only Permissions to the Cross-Account Role
resource "aws_iam_role_policy_attachment" "audit_readonly_attach" {
  role       = aws_iam_role.cross_account_audit_role.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
