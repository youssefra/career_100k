provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_key"
  secret_key                  = "mock_secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://localhost:4567"
  }
}

# 1. Base VPC for our Self-Configuring Tier
resource "aws_vpc" "vois_bootstrap_vpc" {
  cidr_block           = "10.80.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "vOIS-Configuration-Management-VPC"
  }
}

# 2. Highly Available Subnet Tiers
resource "aws_subnet" "bootstrap_subnet_a" {
  vpc_id            = aws_vpc.vois_bootstrap_vpc.id
  cidr_block        = "10.80.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "vOIS-Bootstrap-Subnet-1A"
  }
}

resource "aws_subnet" "bootstrap_subnet_b" {
  vpc_id            = aws_vpc.vois_bootstrap_vpc.id
  cidr_block        = "10.80.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "vOIS-Bootstrap-Subnet-1B"
  }
}

# 3. Security Group for Web Traffic
resource "aws_security_group" "web_tier_sg" {
  name        = "vois-bootstrap-web-sg"
  description = "Allow inbound public HTTP access"
  vpc_id      = aws_vpc.vois_bootstrap_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# =====================================================================
# THE LAUNCH BLUEPRINT WITH AUTOMATED CONFIGURATION MANAGEMENT
# =====================================================================

# 4. THE LAUNCH TEMPLATE: Incorporating automated runtime user_data
resource "aws_launch_template" "golden_template" {
  name_prefix   = "vois-golden-template-"
  image_id      = "ami-df5db7cc" # Mock Ubuntu AMI
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.web_tier_sg.id]

  # AUTOMATED RUNTIME BOOTSTRAPPING (Base64 Encoded Shell Script)
  # When an instance starts, this script automatically updates dependencies,
  # installs an Nginx engine, and builds a custom corporate index asset!
  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Welcome to _VOIS Cloud Infrastructure Services - Cluster Node $(hostname -f)</h1>" > /var/www/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "vOIS-Automated-Bootstrap-Server"
    }
  }
}
