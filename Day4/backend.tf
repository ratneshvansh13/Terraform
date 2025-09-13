terraform {
  backend "s3" {
    bucket = "vansh-s3-demo-wxyz"
    region = "ap-south-1"
    key = "vansh/terraform.tfstate"
    dynamodb_table = "terraform-lock"

    
  }
}