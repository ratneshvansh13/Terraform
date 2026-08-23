#**Provider Block**
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

#Create the VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
}

#defined Public&Private Subnets 
locals {
  public_subnets = {
    az1 = {
      cidr = "10.0.1.0/24"
      az   = "ap-south-1a"
    }

    az2 = {
      cidr = "10.0.2.0/24"
      az   = "ap-south-1b"
    }
  }

  private_subnets = {
    az1 = {
      cidr = "10.0.11.0/24"
      az   = "ap-south-1a"
    }

    az2 = {
      cidr = "10.0.12.0/24"
      az   = "ap-south-1b"
    }
  }
}

#create public subnet
resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id = aws_vpc.main.id

  cidr_block = each.value.cidr

  availability_zone = each.value.az

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${each.key}"
  }
}

#create private subnets
resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id = aws_vpc.main.id

  cidr_block = each.value.cidr

  availability_zone = each.value.az

  tags = {
    Name = "${var.project_name}-private-${each.key}"
  }
}

#IGW
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

#Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

#Associate both public subnets
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id = each.value.id

  route_table_id = aws_route_table.public.id
}

#NAT E_IP
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id

  subnet_id = aws_subnet.public["az1"].id

  tags = {
    Name = "${var.project_name}-nat"
  }

  depends_on = [
    aws_internet_gateway.main
  ]
}

# Private Route Table 
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# Associate private subnets
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id = each.value.id

  route_table_id = aws_route_table.private.id
}