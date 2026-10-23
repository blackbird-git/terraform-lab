terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# Added AWS VPC

resource "aws_vpc" "lab" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name        = "terraform-lab"
    Project     = "cloud-platform-lab"
    Environment = "development"
    ManagedBy   = "terraform"
  }
}

# Added public and private subnets

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "terraform-public-a"
    Environment = "development"
    ManagedBy   = "terraform"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "terraform-public-b"
    Environment = "development"
    ManagedBy   = "terraform"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.lab.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name        = "terraform-private-a"
    Environment = "development"
    ManagedBy   = "terraform"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.lab.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name        = "terraform-private-b"
    Environment = "development"
    ManagedBy   = "terraform"
  }
}

# Added an AWS gateway

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id

  tags = {
    Name        = "terraform-lab-igw"
    Environment = "development"
    ManagedBy   = "terraform"
  }
}

# Added Routes and routing tables for subnets

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id

  tags = {
    Name        = "terraform-public-rt"
    Environment = "development"
    ManagedBy   = "terraform"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.lab.id
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Added Security Group

resource "aws_security_group" "web" {
  name        = "terraform-web-sg"
  description = "Security group for Terraform web server lab"
  vpc_id      = aws_vpc.lab.id

  tags = {
    Name        = "terraform-web-sg"
    Environment = "development"
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group" "alb" {
  name        = "terraform-alb-sg"
  description = "Security group for Amazon Load Balancer"
  vpc_id      = aws_vpc.lab.id

  tags = {
    Name        = "terraform-alb-sg"
    Environment = "development"
    ManagedBy   = "terraform"
  }
}

# Added outbound access

resource "aws_vpc_security_group_egress_rule" "web_all_outbound" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "alb_all_outbound" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Added Inbound access

resource "aws_vpc_security_group_ingress_rule" "allow_from_sg" {
  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"

  description = "Allow HTTP from the ALB SG"
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  description = "Allow HTTP from the Internet"
}

# Added data lookup for most recent Amazon Linux 2023 x86_44 AMI

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create AWS EC2 Instance using latest AMI referenced above. Bootstrap nginx install.

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.web.id]


  # The reason for the user_data_replace_on_change is because we are adding a bootstrap script for nginx install on an existing EC2. We need it to build a new instance to execute the script.

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y nginx
    systemctl enable nginx
    systemctl start nginx
  EOF


  tags = {
    Name        = "terraform-web"
    Environment = "development"
    ManagedBy   = "terraform"
  }
}

resource "aws_instance" "web_b" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_b.id
  vpc_security_group_ids = [aws_security_group.web.id]



  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y nginx
    systemctl enable nginx
    systemctl start nginx
  EOF


  tags = {
    Name        = "terraform-web-b"
    Environment = "development"
    ManagedBy   = "terraform"
  }
}

# Added output values

output "web_public_ip" {
  value       = aws_instance.web.public_ip
  description = "The public IP address of the main web server."
}

output "web_url" {
  value       = "http://${aws_instance.web.public_ip}"
  description = "The web url of the main web server."
}

output "web_b_url" {
  value       = "http://${aws_instance.web_b.public_ip}"
  description = "The web url of the main web server."
}

output "alb_url" {
  value       = "http://${aws_lb.web.dns_name}"
  description = "The web url of the load balancer."
}

# Created Load Balancer

resource "aws_lb" "web" {
  name               = "terraform-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  enable_deletion_protection = false

  tags = {
    Environment = "development"
    ManagedBy   = "terraform"
    Name        = "terraform-web-alb"
  }
}

resource "aws_lb_target_group" "web" {
  name        = "terraform-web-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.lab.id

  tags = {
    Environment = "development"
    ManagedBy   = "terraform"
    Name        = "terraform-web-tg"
  }
}

resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web_b" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web_b.id
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}



