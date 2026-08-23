**Why Modules**
Your Project eventually has many resources and putting in a single main.tf becomes messy, Instead we organize it in modules. Think of a Terraform module like a function in programming.
```
- VPC
- Subnets
- NAT Gateway
- Security Groups
- ALB
- EC2
- RDS
- Route 53
- CloudFront
- S3
```
```
terraform-project/
│
├── main.tf
├── variables.tf
├── outputs.tf
│
└── modules/
    │
    ├── network/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── security/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── compute/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```
suppose your network module creates:
- VPC
- Public Subnets
- Private Subnets
- NAT Gateway
- Route Tables

module "network" {
  source = "./modules/network"
}

**Create the project**
terraform-modules/
│
├── main.tf
├── variables.tf
├── outputs.tf
│
└── modules/
    └── network/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf

**Module VS Resource**
Resource: creates an individual infrastrucutre component
resource "aws_vpc" "main" {
    ...
}
Module: Groups multiple resources together
module "network" {
    source = "./modules/network"
}

**Local module vs Registry module**

module "network" {
  source = "./modules/network"
}

Or use a public module:

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"


  ...
}

