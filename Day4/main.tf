    provider "aws" {
        region = "ap-south-1"
      
    }

    resource "aws_instance" "Vansh" {
        ami = "ami-0f918f7e67a3323f0"
        instance_type = "t3.micro"
      
    }

    resource "aws_s3_bucket" "s3_bucket" {
        bucket = "vansh-s3-demo-wxyz"
      
    }

    resource "aws_dynamodb_table" "terraform_lock" {
      name = "terraform-lock"
      billing_mode = "PAY_PER_REQUEST"
      hash_key = "LockID"

      attribute {
        name = "LockID"
        type = "S"
      }
    }

    output "public_ip_address" {
      value = aws_instance.Vansh.public_ip
    }