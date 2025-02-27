provider "aws" {
  region = "us-west-2"
}

# Create a VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

# Create an Internet Gateway
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "example-igw"
  }
}

# Create a route table
resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }

  tags = {
    Name = "example-rt"
  }
}

# Create subnets
resource "aws_subnet" "subnet1" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.example.id
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "subnet2" {
  cidr_block = "10.0.2.0/24"
  vpc_id     = aws_vpc.example.id
  availability_zone = "us-west-2b"
}

# Associate route table with subnets
resource "aws_route_table_association" "subnet1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.example.id
}

resource "aws_route_table_association" "subnet2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.example.id
}

# Create security group for EC2 instances
resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

# Create EC2 instances
resource "aws_instance" "recngx01" {
  ami           = "ami-027951e78de46a00e" # Replace with a valid AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.example.id]
  key_name = "terraform-test"
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install docker -y
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo docker pull nginx
              sudo docker run -d --name nginx -p 80:80 nginx
              EOF

  tags = {
    Name = "recngx01"
  }
}

resource "aws_instance" "recngx02" {
  ami           = "ami-027951e78de46a00e" # Replace with a valid AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet2.id
  vpc_security_group_ids = [aws_security_group.example.id]
  key_name = "terraform-test"
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install docker -y
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo docker pull nginx
              sudo docker run -d --name nginx -p 80:80 nginx
              EOF

  tags = {
    Name = "recngx02"
  }
}

# Create Application Load Balancer
resource "aws_lb" "example" {
  name               = "example-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.example.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name = "example-alb"
  }
}

# Create target group
resource "aws_lb_target_group" "example" {
  name     = "example-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.example.id

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 3
    path                = "/"
    interval            = 30
  }
}

# Attach EC2 instances to target group
resource "aws_lb_target_group_attachment" "recngx01" {
  target_group_arn = aws_lb_target_group.example.arn
  target_id        = aws_instance.recngx01.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "recngx02" {
  target_group_arn = aws_lb_target_group.example.arn
  target_id        = aws_instance.recngx02.id
  port             = 80
}

# Create listener
resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.example.arn
    type             = "forward"
  }
}

