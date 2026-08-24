locals {
    instance_type = {
        dev         = "t3.micro"
        stageing    = "t3.small"
        prod        = "t3.medium"
    }
}

resource "aws_instance" "demo" {
    ami = "Your AMI ID"
    instance_type = local.instance_type[terraform.workspace]
    
    tags = {
      Name          = "terraform-${terraform.workspace}"
      Environment   = terraform.workspace
    }   
}