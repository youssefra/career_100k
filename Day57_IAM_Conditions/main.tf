provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_key"
  secret_key                  = "mock_secret"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam = "http://localhost:4567"
    s3  = "http://localhost:4567"
    ec2 = "http://localhost:4567"
  }
}

# 1. Create a secure target bucket
resource "aws_s3_bucket" "secure_production_data" {
  bucket = "day57-least-privilege-bucket"
}

# 2. Create the EC2 Trust Role
resource "aws_iam_role" "restricted_ec2_role" {
  name = "restricted-ec2-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 3. Create and Attach a strict Least-Privilege Policy with a Condition
resource "aws_iam_role_policy" "s3_conditional_policy" {
  name = "s3-strict-conditions"
  role = aws_iam_role.restricted_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        # This explicitly restricts access ONLY to our specific bucket
        Resource = [
          "${aws_s3_bucket.secure_production_data.arn}",
          "${aws_s3_bucket.secure_production_data.arn}/*"
        ]
        # CONDITION BLOCK: Enforces that requests MUST use SSL/TLS (HTTPS)
        Condition = {
          Bool = {
            "aws:SecureTransport" = "true"
          }
        }
      }
    ]
  })
}

# 4. Create the Instance Profile
resource "aws_iam_instance_profile" "day57_profile" {
  name = "day57-ec2-instance-profile"
  role = aws_iam_role.restricted_ec2_role.name
}
