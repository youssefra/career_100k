# 1. Define the Provider (Who are we talking to?)
provider "aws" {
  region = "us-east-1"
}

# 2. Define the Resource (What are we building?)
resource "aws_instance" "my_first_server" {
  ami           = "ami-0c55b159cbfafe1f0" # An Amazon Linux image
  instance_type = "t2.micro"             # The free tier size

  tags = {
    Name = "Youssef-Automated-Server"
  }
}
