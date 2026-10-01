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
    Name    = "terraform-lab"
    Project = "cloud-platform-lab"
    Environment = "development"
    ManagedBy = "terraform"
  }
}