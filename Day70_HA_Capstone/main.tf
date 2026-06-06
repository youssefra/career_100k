variable "is_localstack" {
  type        = bool
  default     = true
  description = "Set to true to bypass Pro features (ALB & ASG core engine emulation) on local free tier"
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_key"
  secret_key                  = "mock_secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2         = "http://localhost:4567"
    elbv2       = "http://localhost:4567"
    autoscaling = "http://localhost:4567"
  }
}

# 1. Production Capstone VPC Network
resource "aws_vpc" "vois_capstone_vpc" {
  cidr_block           = "10.100.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "vOIS-Capstone-HA-VPC"
  }
}

# 2. Multi-AZ Subnets for High Availability
resource "aws_subnet" "capstone_pub_1a" {
  vpc_id            = aws_vpc.vois_capstone_vpc.id
  cidr_block        = "10.100.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "vOIS-Capstone-Subnet-1A"
  }
}

resource "aws_subnet" "capstone_pub_1b" {
  vpc_id            = aws_vpc.vois_capstone_vpc.id
  cidr_block        = "10.100.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "vOIS-Capstone-Subnet-1B"
  }
}

# 3. Security Group for Public Facing Load Balancer
resource "aws_security_group" "capstone_alb_sg" {
  name        = "vois-capstone-alb-sg"
  vpc_id      = aws_vpc.vois_capstone_vpc.id

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

# 4. Security Group for Web Instances (Strictly allowing ingress from ALB)
resource "aws_security_group" "capstone_instance_sg" {
  name        = "vois-capstone-instance-sg"
  vpc_id      = aws_vpc.vois_capstone_vpc.id

  ingress {
    description     = "Allow HTTP traffic strictly from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.capstone_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 5. Core Application Load Balancer Blueprint
resource "aws_lb" "capstone_alb" {
  count              = var.is_localstack ? 0 : 1
  name               = "vois-capstone-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.capstone_alb_sg.id]
  subnets            = [aws_subnet.capstone_pub_1a.id, aws_subnet.capstone_pub_1b.id]
}

# 6. Target Group with Health Checks for Dynamic Routing
resource "aws_lb_target_group" "capstone_tg" {
  count    = var.is_localstack ? 0 : 1
  name     = "vois-capstone-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vois_capstone_vpc.id

  health_check {
    path                = "/"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# 7. ALB Listener Blueprint
resource "aws_lb_listener" "capstone_listener" {
  count             = var.is_localstack ? 0 : 1
  load_balancer_arn = aws_lb.capstone_alb[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.capstone_tg[0].arn
  }
}

# 8. Golden Launch Template with Runtime Bootstrapping
resource "aws_launch_template" "capstone_template" {
  name_prefix   = "vois-capstone-template-"
  image_id      = "ami-df5db7cc"
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.capstone_instance_sg.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>_VOIS Capstone Node: System Healthy</h1>" > /var/www/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "vOIS-Capstone-Cluster-Node"
    }
  }
}

# 9. Self-Healing Auto Scaling Group Blueprint Connected to Target Group
resource "aws_autoscaling_group" "capstone_asg" {
  count               = var.is_localstack ? 0 : 1
  name_prefix         = "vois-capstone-asg-"
  vpc_zone_identifier = [aws_subnet.capstone_pub_1a.id, aws_subnet.capstone_pub_1b.id]
  
  desired_capacity = 2
  min_size         = 1
  max_size         = 4

  # This binds the ASG straight to the Load Balancer's target lifecycle!
  target_group_arns = [aws_lb_target_group.capstone_tg[0].arn]

  launch_template {
    id      = aws_launch_template.capstone_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "vOIS-Capstone-ASG-Server"
    propagate_at_launch = true
  }
}
