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

# 1. Base VPC for our HA Architecture
resource "aws_vpc" "vois_ha_vpc" {
  cidr_block           = "10.50.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "vOIS-HA-Infrastructure-VPC"
  }
}

# 2. Subnet A - Placed in Availability Zone 1a
resource "aws_subnet" "ha_subnet_az1" {
  vpc_id            = aws_vpc.vois_ha_vpc.id
  cidr_block        = "10.50.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "vOIS-HA-Subnet-1A"
  }
}

# 3. Subnet B - Placed in Availability Zone 1b (Physical Isolation)
resource "aws_subnet" "ha_subnet_az2" {
  vpc_id            = aws_vpc.vois_ha_vpc.id
  cidr_block        = "10.50.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "vOIS-HA-Subnet-1B"
  }
}

# 4. Security Group allowing standard internal web access
resource "aws_security_group" "ha_app_sg" {
  name        = "vois-ha-app-sg"
  description = "Allow internal app communication"
  vpc_id      = aws_vpc.vois_ha_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.50.0.0/16"] # Restricted strictly to internal VPC space
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# =====================================================================
# HIGH AVAILABILITY COMPUTE DISTRIBUTED PLACEMENT
# =====================================================================

# Server 1 - Running in Data Center 1A
resource "aws_instance" "app_server_az1" {
  ami           = "ami-df5db7cc" # Mock Ubuntu AMI ID for LocalStack
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.ha_subnet_az1.id
  vpc_security_group_ids = [aws_security_group.ha_app_sg.id]

  tags = {
    Name = "vOIS-HA-AppServer-ZoneA"
  }
}

# Server 2 - Running in Data Center 1B
resource "aws_instance" "app_server_az2" {
  ami           = "ami-df5db7cc" 
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.ha_subnet_az2.id
  vpc_security_group_ids = [aws_security_group.ha_app_sg.id]

  tags = {
    Name = "vOIS-HA-AppServer-ZoneB"
  }
}
