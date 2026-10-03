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

resource "aws_vpc" "lab" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name        = "terraform-lab"
    Project     = "cloud-platform-lab"
    Environment = "development"
    ManagedBy   = "terraform"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.lab.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name        = "terraform-public-a"
    Environment = "development"
    ManagedBy   = "terraform"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.lab.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"

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

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id

  tags = {
    Name        = "terraform-lab-igw"
    Environment = "development"
    ManagedBy   = "terraform"
  }
}