provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam = "http://localhost:4567"
  }
}

locals {
  user_name = "junior-developer"
  env       = "dev"
}

resource "aws_iam_user" "new_dev" {
  name = "${local.user_name}-${local.env}"
}

resource "aws_iam_policy" "read_only_policy" {
  name        = "S3ReadOnlyAccess"
  description = "Allows viewing S3 but nothing else"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:Get*", "s3:List*"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "test-attach" {
  user       = aws_iam_user.new_dev.name
  policy_arn = aws_iam_policy.read_only_policy.arn
}
