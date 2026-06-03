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
    autoscaling = "http://localhost:4567"
    ec2 = "http://localhost:4567"
  }
}

# 1. Base VPC for our Elastic Infrastructure
resource "aws_vpc" "vois_asg_vpc" {
  cidr_block           = "10.70.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "vOIS-ASG-Architecture-VPC"
  }
}

# 2. Subnet A - Availability Zone 1a
resource "aws_subnet" "asg_subnet_a" {
  vpc_id            = aws_vpc.vois_asg_vpc.id
  cidr_block        = "10.70.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "vOIS-ASG-Subnet-1A"
  }
}

# 3. Subnet B - Availability Zone 1b
resource "aws_subnet" "asg_subnet_b" {
  vpc_id            = aws_vpc.vois_asg_vpc.id
  cidr_block        = "10.70.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "vOIS-ASG-Subnet-1B"
  }
}

# 4. Security Group for the Auto Scaling Instances
resource "aws_security_group" "asg_instance_sg" {
  name        = "vois-asg-instance-sg"
  description = "Security group for elastic compute instances"
  vpc_id      = aws_vpc.vois_asg_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.70.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# =====================================================================
# THE ELASTIC COMPUTE POOL AUTOMATION
# =====================================================================

# 5. THE LAUNCH TEMPLATE: The golden blueprint describing the instances
resource "aws_launch_template" "asg_template" {
  name_prefix   = "vois-app-template-"
  image_id      = "ami-df5db7cc" # Mock Ubuntu AMI ID for LocalStack
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.asg_instance_sg.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "vOIS-Elastic-Pool-Server"
    }
  }
}

# 6. THE AUTO SCALING GROUP: The self-healing cluster controller
resource "aws_autoscaling_group" "app_asg" {
  count               = var.is_localstack ? 0 : 1
  name_prefix         = "vois-elastic-asg-"
  vpc_zone_identifier = [aws_subnet.asg_subnet_a.id, aws_subnet.asg_subnet_b.id] # Distribute over both AZ subnets

  desired_capacity = 2
  min_size         = 1
  max_size         = 4

  # Bind to our structural Launch Template blueprint
  launch_template {
    id      = aws_launch_template.asg_template.id
    version = "$Latest"
  }

  # Tag the ASG itself
  tag {
    key                 = "Name"
    value               = "vOIS-AutoScaling-Controller"
    propagate_at_launch = true
  }
}
