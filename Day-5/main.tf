provider "aws" {
    region = "ap-south-1"
  
}

variable "cidr" {
    default = "10.0.0.0/16"
  
}