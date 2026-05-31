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

# 1. Create our isolated Enterprise VPC
resource "aws_vpc" "vois_endpoint_vpc" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "vOIS-Endpoint-Optimized-VPC"
  }
}

# 2. Create an isolated App Subnet (No NAT Gateway, No Internet Gateway)
resource "aws_subnet" "isolated_app_tier" {
  vpc_id            = aws_vpc.vois_endpoint_vpc.id
  cidr_block        = "172.16.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "vOIS-Isolated-App-Subnet"
  }
}

# 3. Create a dedicated Private Route Table
resource "aws_route_table" "isolated_rt" {
  vpc_id = aws_vpc.vois_endpoint_vpc.id

  tags = {
    Name = "vOIS-Isolated-RouteTable"
  }
}

# 4. Bind our subnet to the isolated Route Table
resource "aws_route_table_association" "isolated_assoc" {
  subnet_id      = aws_subnet.isolated_app_tier.id
  route_table_id = aws_route_table.isolated_rt.id
}

# 5. COST OPTIMIZATION: Provision the S3 Gateway Endpoint
# This injects a private routing target directly linking our VPC to S3 storage over private fiber!
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.vois_endpoint_vpc.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"

  # Automatically inject the S3 routing rule directly into our isolated route table
  route_table_ids = [aws_route_table.isolated_rt.id]

  tags = {
    Name = "vOIS-S3-Gateway-Endpoint"
  }
}
