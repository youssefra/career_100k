variable "is_localstack" {
  type        = bool
  default     = true
  description = "Set to true to skip resources not supported by free LocalStack"
}


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
resource "aws_vpc" "vois_prod_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "vOIS-Prod-VPC"
  }
}

# 2. Create a Public Subnet inside the VPC
resource "aws_subnet" "public_tier_a" {
  vpc_id            = aws_vpc.vois_prod_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "vOIS-Public-Subnet-1A"
  }
}

# 3. Create the Internet Gateway (The public exit/entry door)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vois_prod_vpc.id

  tags = {
    Name = "vOIS-Prod-IGW"
  }
}

# 4. Create a Custom Route Table for public traffic
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vois_prod_vpc.id

  # ROUTE RULE: Send ALL out-of-network traffic (0.0.0.0/0) straight to the IGW
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "vOIS-Public-RouteTable"
  }
}

# 5. Explicitly associate our Subnet to our Route Table
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_tier_a.id
  route_table_id = aws_route_table.public_rt.id
}
# --- DAY 62 EXTENSIONS: PRIVATE TIER & SECURE EGRESS ---

# 1. Create a Secure Private Subnet (Fully supported by LocalStack)
resource "aws_subnet" "private_tier_a" {
  vpc_id            = aws_vpc.vois_prod_vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "vOIS-Private-Subnet-1A"
  }
}

# 2. Allocate a Static Public IP (Elastic IP) for our NAT Gateway
resource "aws_eip" "nat_eip" {
  count      = var.is_localstack ? 0 : 1
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "vOIS-NAT-StaticIP"
  }
}

# 3. Deploy the NAT Gateway inside the PUBLIC Subnet
resource "aws_nat_gateway" "nat_gw" {
  count         = var.is_localstack ? 0 : 1
  allocation_id = aws_eip.nat_eip[0].id
  subnet_id     = aws_subnet.public_tier_a.id

  tags = {
    Name = "vOIS-Prod-NAT-Gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

# 4. Create a Dedicated Route Table for the Private Subnet
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vois_prod_vpc.id

  # If localstack, it creates a private route table without internet egress.
  # If production, it correctly routes traffic out via the NAT Gateway.
  dynamic "route" {
    for_each = var.is_localstack ? [] : [1]
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.nat_gw[0].id
    }
  }

  tags = {
    Name = "vOIS-Private-RouteTable"
  }
}

# 5. Explicitly associate the Private Subnet to the Private Route Table
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_tier_a.id
  route_table_id = aws_route_table.private_rt.id
}
