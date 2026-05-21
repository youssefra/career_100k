provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_key"
  secret_key                  = "mock_secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam = "http://localhost:4567"
  }
}

# 1. THE BOUNDARY: This defines the MAXIMUM ceiling (Only S3 and EC2 allowed)
resource "aws_iam_policy" "boundary_policy" {
  name        = "vOIS-developer-boundary"
  description = "The absolute maximum permissions ceiling for developers"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "ec2:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# 2. THE USER ROLE: We apply the boundary right here
resource "aws_iam_role" "restricted_developer" {
  name                 = "vois-developer-role"
  permissions_boundary = aws_iam_policy.boundary_policy.arn

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

# 3. THE PERMISSION ATTACHMENT: We try to give them broad Administrator Access
resource "aws_iam_role_policy_attachment" "admin_attach" {
  role       = aws_iam_role.restricted_developer.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

