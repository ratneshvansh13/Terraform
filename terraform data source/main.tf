terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
    state = "available"
  
}

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"

    tags = {
      Name = "terraform-vpc"
    }
}

resource "aws_subnet" "public" {
    count = 2

    vpc_id = aws_vpc.main.id

    cidr_block = "10.0.${count.index + 1}.0/24"

    availability_zone = data.aws_availability_zones.available.names[count.index]

    tags = {
      Name = "public-${count.index + 1}"
    }

  
}