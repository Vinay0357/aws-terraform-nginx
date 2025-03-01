provider "aws" {
  region = var.aws_region
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "rec-vpc"
  }
}

# Create subnets in different availability zones
resource "aws_subnet" "subnet_01" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "rec-subnet-01"
  }
}

resource "aws_subnet" "subnet_02" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "rec-subnet-02"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "rec-igw"
  }
}

# Create a route table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "rec-rt"
  }
}

# Associate subnets with the route table
resource "aws_route_table_association" "rta_01" {
  subnet_id      = aws_subnet.subnet_01.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rta_02" {
  subnet_id      = aws_subnet.subnet_02.id
  route_table_id = aws_route_table.rt.id
}

# Create security group for EC2 instances
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main.id
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
  tags = {
    Name = "rec-ec2-sg"
  }
}

# Create EC2 instances
resource "aws_instance" "recngx01" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet_01.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data = file("user_data.sh")
  associate_public_ip_address = true
  tags = {
    Name = "recngx01"
  }
}

resource "aws_instance" "recngx02" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet_02.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data = file("user_data.sh")
  associate_public_ip_address = true
  tags = {
    Name = "recngx02"
  }
}

# Create an Application Load Balancer (ALB)
resource "aws_lb" "rec_alb" {
  name               = "rec-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ec2_sg.id]
  subnets            = [aws_subnet.subnet_01.id, aws_subnet.subnet_02.id]
  tags = {
    Name = "rec-alb"
  }
}

# Create a target group for the ALB
resource "aws_lb_target_group" "rec_tg" {
  name     = "rec-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# Attach EC2 instances to the target group
resource "aws_lb_target_group_attachment" "rec_tg_attach_01" {
  target_group_arn = aws_lb_target_group.rec_tg.arn
  target_id        = aws_instance.recngx01.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "rec_tg_attach_02" {
  target_group_arn = aws_lb_target_group.rec_tg.arn
  target_id        = aws_instance.recngx02.id
  port             = 80
}

# Create an ALB listener
resource "aws_lb_listener" "rec_listener" {
  load_balancer_arn = aws_lb.rec_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rec_tg.arn
  }
}