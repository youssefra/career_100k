
variable "is_localstack" {
  type        = bool
  default     = true
  description = "Set to true to skip advanced AWS Pro features not supported by free LocalStack"
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
    elbv2 = "http://localhost:4567" # LocalStack maps ELBv2 onto the same unified endpoint engine
  }
}

# 1. Base VPC for our Routed Architecture
resource "aws_vpc" "vois_elb_vpc" {
  cidr_block           = "10.60.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "vOIS-ELB-Architecture-VPC"
  }
}

# 2. Public Subnet A (Zone 1A)
resource "aws_subnet" "pub_subnet_a" {
  vpc_id            = aws_vpc.vois_elb_vpc.id
  cidr_block        = "10.60.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "vOIS-Public-Subnet-1A"
  }
}

# 3. Public Subnet B (Zone 1B - ALBs require at least 2 AZs for high availability!)
resource "aws_subnet" "pub_subnet_b" {
  vpc_id            = aws_vpc.vois_elb_vpc.id
  cidr_block        = "10.60.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "vOIS-Public-Subnet-1B"
  }
}

# 4. Security Group for the Load Balancer (Public facing)
resource "aws_security_group" "alb_sg" {
  name        = "vois-public-alb-sg"
  vpc_id      = aws_vpc.vois_elb_vpc.id

  ingress {
    description = "Allow public HTTP traffic"
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
# THE LOAD BALANCING INFRASTRUCTURE COMPONENT INFRASTRUCTURE
# =====================================================================

# 5. The Core Application Load Balancer
resource "aws_lb" "app_alb" {
  count              = var.is_localstack ? 0 : 1
  name               = "vois-prod-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.pub_subnet_a.id, aws_subnet.pub_subnet_b.id]

  tags = {
    Name = "vOIS-Production-ALB"
  }
}

# 6. The Logical Target Group with Automated Health Checks
resource "aws_lb_target_group" "app_tg" {
  count              = var.is_localstack ? 0 : 1
  name     = "vois-app-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vois_elb_vpc.id

  health_check {
    enabled             = true
    path                = "/"
    port                = "80"
    protocol            = "HTTP"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# 7. The Frontend HTTP Listener directing traffic to our Target Group
resource "aws_lb_listener" "alb_listener" {
  count              = var.is_localstack ? 0 : 1
  load_balancer_arn = aws_lb.app_alb[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg[0].arn
  }
}
