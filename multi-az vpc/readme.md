**We build**

                         VPC
                    10.0.0.0/16
                         │
          ┌──────────────┴──────────────┐
          │                             │
        AZ-a                           AZ-b
          │                             │
   ┌──────┴──────┐               ┌──────┴──────┐
   │             │               │             │
Public         Private          Public        Private
Subnet         Subnet           Subnet        Subnet
   │             │               │             │
   │             └──────┐        │             │
   │                    │        │             │
   └──── Internet        │        └── Internet │
       Gateway           │            Gateway  │
                        NAT
                         │
                      Internet

**Project Structure**
terraform-multi-az/
├── main.tf
├── variables.tf
├── terraform.tfvars
└── outputs.tf

**Problem Statements**
- creating multiple subnets takes too much time and repeatitive blocks 
solution: 
use -->  for_each 

**Subnet architectue**
VPC
│
├── Public AZ-a
├── Public AZ-b
│
├── Private AZ-a
└── Private AZ-b

