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

# 1. Create a Secure S3 Bucket
resource "aws_s3_bucket" "app_data" {
  bucket = "day56-secure-app-data-bucket"
}

# 2. Create the IAM Role Trust Policy (Allows EC2 to assume this role)
resource "aws_iam_role" "ec2_s3_readonly" {
  name = "ec2-s3-readonly-role"

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

# 3. Attach a Managed Policy to the Role
resource "aws_iam_role_policy_attachment" "s3_readonly_attach" {
  role       = aws_iam_role.ec2_s3_readonly.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# 4. Create the Instance Profile required by EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-s3-readonly-instance-profile"
  role = aws_iam_role.ec2_s3_readonly.name
}

# 5. Launch the EC2 Instance with the Profile attached
resource "aws_instance" "web_server" {
  ami                  = "ami-0c55b159cbfafe1f0" 
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "Day56-Secure-Web-Server"
  }
}
