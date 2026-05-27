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

# 1. Create a custom production VPC
resource "aws_vpc" "vois_secure_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "vOIS-Secure-VPC"
  }
}

# 2. Create a Web Subnet
resource "aws_subnet" "web_tier" {
  vpc_id            = aws_vpc.vois_secure_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "vOIS-Web-Subnet"
  }
}

# 3. STATEFUL FIREWALL: Security Group for Web Servers
resource "aws_security_group" "web_sg" {
  name        = "vois-web-sg"
  description = "Stateful firewall allowing HTTP public ingress"
  vpc_id      = aws_vpc.vois_secure_vpc.id

  # Inbound Rule: Allow public web browsers on Port 80
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Rule: Stateful nature means responses are tracked automatically,
  # but servers still need access to the outbound web for system components.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vOIS-Web-SecurityGroup"
  }
}

# 4. STATELESS FIREWALL: Custom Subnet Network ACL (NACL)
resource "aws_network_acl" "web_nacl" {
  vpc_id     = aws_vpc.vois_secure_vpc.id
  subnet_ids = [aws_subnet.web_tier.id]

  # Rule 100: Allow HTTP web traffic inbound
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Rule 110: CRITICAL STATELESS MECHANISM - Allow return traffic from ephemeral ports
  # When a client connects from the web, their browser listens on a random high port (1024-65535).
  # Because NACLs are stateless, we must explicitly allow the server's reply packet to leave!
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "vOIS-Subnet-NACL"
  }
}
