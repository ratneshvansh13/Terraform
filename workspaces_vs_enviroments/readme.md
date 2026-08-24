## Workspaces VS Environments:
---
#### What is a Terraform Workspace ?
A workspace allows the same terraform configuration to maintain multiple state files.

example:
```
Workspace
│
├── default
├── dev
├── staging
└── prod
```
**Each workspace has its own terraform state**
```
              Same Terraform Code
                      │
          ┌───────────┼───────────┐
          ▼           ▼           ▼
         dev       staging       prod
          │           │           │
          ▼           ▼           ▼
       State 1      State 2      State 3
```

```
terraform workspace show
terraform workspace list
terraform workspace new dev
terraform workspace select dev
```
**Each Workspace has separate State:**
terraform.workspace
returns current selected workspace.

#### Using Workspace in Resource Names
For example:
```
resource "aws_s3_bucket" "app" {
  bucket = "shopping-cart-${terraform.workspace}-bucket"
}
```
In dev:
```
shopping-cart-dev-bucket

In prod:
```
shopping-cart-prod-bucket

#### A Better Approch: Workspace + Map
```
locals {
  environment_config = {
    dev = {
      instance_type = "t3.micro"
      instance_count = 1
    }

    staging = {
      instance_type = "t3.small"
      instance_count = 2
    }

    prod = {
      instance_type = "t3.medium"
      instance_count = 3
    }
  }
}
```
then
```
resource "aws_instance" "app" {

  count = local.environment_config[terraform.workspace].instance_count

  instance_type = local.environment_config[
    terraform.workspace
  ].instance_type

}
```
#### Don't Put ${terraform.workspace} in Backend Configuration

This is a common beginner mistake. Backend configuration is initialized before Terraform evaluates normal configuration expressions.

---
Workspace Approach

You could have:
```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
└── providers.tf
```
and:
```
workspaces:
    dev
    staging
    prod
```
Advantages:
```
✅ Less duplicated code
✅ Easy to switch environments
✅ Separate state
✅ Good for simple environments
```
##### Separate Directory Approach

Another common approach:
```
terraform/
│
├── modules/
│
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── backend.tf
│   │   └── terraform.tfvars
│   │
│   ├── staging/
│   │   ├── main.tf
│   │   ├── backend.tf
│   │   └── terraform.tfvars
│   │
│   └── prod/
│       ├── main.tf
│       ├── backend.tf
│       └── terraform.tfvars
│
└── modules/
    ├── vpc/
    ├── alb/
    ├── asg/
    └── rds/
```

Terraform Architechture 
```
Terraform
│
├── Providers
├── Resources
├── Variables
├── Outputs
├── Locals
├── Data Sources
├── Dependencies
├── Expressions
├── Functions
├── for_each
├── count
├── Modules
│
├── State
│   ├── Local
│   └── Remote
│
├── S3 Backend
│   ├── Encryption
│   ├── Versioning
│   └── Locking
│
├── State Operations
│   ├── import
│   ├── mv
│   ├── rm
│   └── show
│
└── Workspaces
```