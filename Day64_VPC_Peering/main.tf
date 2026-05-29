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

# =====================================================================
# 1. NETWORK A: PRODUCTION APPLICATION VPC (CIDR: 10.100.0.0/16)
# =====================================================================
resource "aws_vpc" "prod_vpc" {
  cidr_block           = "10.100.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "vOIS-Production-VPC"
  }
}

resource "aws_subnet" "prod_subnet" {
  vpc_id            = aws_vpc.prod_vpc.id
  cidr_block        = "10.100.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "vOIS-Prod-Subnet"
  }
}

resource "aws_route_table" "prod_rt" {
  vpc_id = aws_vpc.prod_vpc.id

  tags = {
    Name = "vOIS-Prod-RouteTable"
  }
}

resource "aws_route_table_association" "prod_assoc" {
  subnet_id      = aws_subnet.prod_subnet.id
  route_table_id = aws_route_table.prod_rt.id
}

# =====================================================================
# 2. NETWORK B: SHARED SERVICES VPC (CIDR: 10.200.0.0/16)
# =====================================================================
resource "aws_vpc" "services_vpc" {
  cidr_block           = "10.200.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "vOIS-SharedServices-VPC"
  }
}

resource "aws_subnet" "services_subnet" {
  vpc_id            = aws_vpc.services_vpc.id
  cidr_block        = "10.200.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "vOIS-Services-Subnet"
  }
}

resource "aws_route_table" "services_rt" {
  vpc_id = aws_vpc.services_vpc.id

  tags = {
    Name = "vOIS-Services-RouteTable"
  }
}

resource "aws_route_table_association" "services_assoc" {
  subnet_id      = aws_subnet.services_subnet.id
  route_table_id = aws_route_table.services_rt.id
}

# =====================================================================
# 3. THE INTERCONNECTION: VPC PEERING TUNNEL
# =====================================================================
resource "aws_vpc_peering_connection" "prod_to_services" {
  peer_vpc_id = aws_vpc.services_vpc.id
  vpc_id      = aws_vpc.prod_vpc.id
  auto_accept = true # Since both VPCs are in our account, we auto-approve the link

  tags = {
    Name = "vOIS-Prod-to-Services-Peer"
  }
}

# =====================================================================
# 4. THE ROUTING LOGIC: CROSS-NETWORK ROUTE ENTRIES
# =====================================================================

# Route rule on Network A: Send any traffic destined for Network B (10.200.0.0/16) down the peering connection
resource "aws_route" "prod_to_services_edge" {
  route_table_id            = aws_route_table.prod_rt.id
  destination_cidr_block    = "10.200.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.prod_to_services.id
}

# Route rule on Network B: Send any traffic destined for Network A (10.100.0.0/16) back down the peering connection
resource "aws_route" "services_to_prod_edge" {
  route_table_id            = aws_route_table.services_rt.id
  destination_cidr_block    = "10.100.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.prod_to_services.id
}
