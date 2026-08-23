terraform {
  backend "s3" {
    bucket       = "my-terraform-state-bkt-ratnesh"
    key          = "dev/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
    encrypt      = true
  }
}