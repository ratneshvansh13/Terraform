# Terraform State & Remote Backend

> A practical guide to understanding Terraform state, why local state becomes a problem, and how to build a reliable remote backend with Amazon S3.

---

## 📌 Why this topic matters

When you start learning Terraform, it is easy to think that Terraform is simply:

```text
Terraform Code → AWS
```

But there is another important piece in the middle: **Terraform State**.

```text
Terraform Configuration
          │
          ▼
       Terraform
          │
          ├──────────────► AWS Infrastructure
          │
          ▼
     Terraform State
```

Terraform uses state to remember the infrastructure it manages.

This becomes especially important when:

- multiple developers work on the same infrastructure
- Terraform runs through Jenkins or another CI/CD system
- infrastructure is deployed across multiple environments
- infrastructure needs to be recovered after an incident
- multiple Terraform operations could run at the same time

For a personal learning project, local state is usually enough.

For a team or production environment, **remote state is the better approach**.

---

# 1. What is Terraform State?

Suppose we create an EC2 instance:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-xxxxxxxx"
  instance_type = "t3.micro"
}
```

Terraform sends the request to AWS and AWS creates an instance such as:

```text
i-0123456789abcdef
```

Terraform needs to remember:

```text
aws_instance.web
        ↓
i-0123456789abcdef
```

That information is stored in the Terraform state.

The default local state file is:

```text
terraform.tfstate
```

A simplified view is:

```text
Terraform configuration
        │
        ▼
   Desired state
        │
        ▼
     Terraform
        │
        ▼
 terraform.tfstate
        │
        ▼
 Actual AWS resources
```

The real state file contains much more information than a simple resource ID, including resource attributes and information Terraform needs to manage the infrastructure.

---

# 2. Why Does Terraform Need State?

Imagine we initially create:

```hcl
resource "aws_instance" "web" {
  instance_type = "t3.micro"
}
```

Later we change it to:

```hcl
resource "aws_instance" "web" {
  instance_type = "t3.small"
}
```

Terraform needs to answer:

> Which EC2 instance should I update?

State provides the relationship between the Terraform resource and the real AWS resource.

Without state, Terraform would not have the same reliable tracking mechanism for the resources it manages.

---

# 3. The Local State Problem

By default, Terraform stores state locally:

```text
terraform-project/
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfstate
```

This works well while learning Terraform on one machine.

The problems start when the infrastructure is shared.

---

# 4. Problem #1 — Team Collaboration

Imagine two developers:

```text
Developer A
    │
    └── Laptop A
         └── terraform.tfstate

Developer B
    │
    └── Laptop B
         └── terraform.tfstate
```

Now both developers have their own copy of the state.

Developer A might create:

```text
VPC
EC2
RDS
```

while Developer B's state still represents an older version of the infrastructure.

This can lead to:

- inconsistent state
- unexpected plans
- duplicate resources
- difficult troubleshooting
- accidental infrastructure changes

### ✅ Solution: Remote State

Instead of keeping state on individual machines, store it centrally.

```text
Developer A ─────┐
                 │
Developer B ─────┼────► S3
                 │       │
Jenkins ─────────┘       └── terraform.tfstate
```

Now everyone works against the same state.

---

# 5. Problem #2 — Jenkins and CI/CD

Suppose Jenkins runs:

```bash
terraform plan
terraform apply
```

If the state exists only inside the Jenkins workspace:

```text
Jenkins
   │
   └── workspace
        └── terraform.tfstate
```

there is a problem.

What happens if:

- Jenkins is rebuilt?
- The workspace is deleted?
- A different Jenkins agent runs the pipeline?
- Two builds run simultaneously?
- The Jenkins server fails?

The infrastructure may still exist in AWS, but the state stored on that machine may not be available.

### ✅ Solution: Remote State

Use a centralized backend:

```text
Jenkins
   │
   ▼
Terraform
   │
   ▼
Amazon S3
   │
   └── terraform.tfstate
```

Now the state isn't tied to one Jenkins workspace.

---

# 6. Problem #3 — Losing the State File

Imagine your Terraform state exists only on your laptop:

```text
Laptop
└── terraform.tfstate
```

Then the laptop is:

- lost
- damaged
- reformatted
- accidentally cleaned

Your AWS infrastructure can still be running, but Terraform has lost the state information it was using to track those resources.

### ✅ Solution: Store State Remotely

Amazon S3 gives us durable centralized storage for Terraform state.

```text
Local Machine
      │
      ▼
 Terraform
      │
      ▼
     S3
      │
      └── terraform.tfstate
```

---

# 7. Problem #4 — Two Terraform Operations at the Same Time

This is particularly important for CI/CD.

Imagine:

```text
Jenkins Build #101
       │
       └── terraform apply
              │
              ▼
             S3
              │
       terraform.tfstate


Jenkins Build #102
       │
       └── terraform apply
              │
              ▼
             S3
```

Both builds are trying to work with the same state.

That is dangerous because Terraform operations can interfere with each other.

### ✅ Solution: State Locking

Terraform supports locking with the S3 backend using:

```hcl
use_lockfile = true
```

Conceptually:

```text
              S3
               │
       terraform.tfstate
               │
    terraform.tfstate.tflock
               │
        ┌──────┴──────┐
        │             │
   Jenkins #101   Jenkins #102
        │             │
      LOCKED         WAIT
```

The lock helps prevent concurrent Terraform operations from modifying the same state at the same time.

---

# 8. Why Amazon S3?

For AWS-based Terraform projects, S3 is a natural choice for remote state.

It gives us:

- centralized storage
- durability
- IAM integration
- encryption
- versioning
- S3-based state locking
- easy integration with AWS CI/CD environments

A basic backend configuration looks like this:

```hcl
terraform {
  backend "s3" {
    bucket       = "my-terraform-state-bucket"
    key          = "dev/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

---

# 9. Understanding the S3 Backend Configuration

## `bucket`

```hcl
bucket = "my-terraform-state-bucket"
```

The S3 bucket where Terraform stores the state.

S3 bucket names must be globally unique.

---

## `key`

```hcl
key = "dev/terraform.tfstate"
```

This is the location of the state object inside the bucket.

For example:

```text
terraform-state-bucket/
└── dev/
    └── terraform.tfstate
```

You can separate environments:

```text
terraform-state-bucket/
├── dev/
│   └── terraform.tfstate
├── staging/
│   └── terraform.tfstate
└── prod/
    └── terraform.tfstate
```

---

## `region`

```hcl
region = "ap-south-1"
```

The AWS region where the S3 bucket exists.

---

## `encrypt`

```hcl
encrypt = true
```

This tells Terraform to use encrypted state storage.

State should always be treated as sensitive infrastructure data.

---

## `use_lockfile`

```hcl
use_lockfile = true
```

This enables S3-based state locking.

---

# 10. Problem #5 — Accidental State Changes

Terraform state is important.

If the state is accidentally overwritten or deleted, recovering the exact previous state can be difficult if there is no backup.

### ✅ Solution: S3 Versioning

Enable versioning:

```hcl
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

Now S3 can keep previous versions:

```text
terraform.tfstate

Version 1
Version 2
Version 3
Version 4
```

This gives you an additional recovery option.

---

# 11. Problem #6 — Sensitive Information in State

Terraform state can contain sensitive infrastructure information.

Depending on the resources being managed, this may include things such as:

- database configuration
- connection information
- resource attributes
- generated credentials or secret values

So this is an important rule:

> 🔐 Treat Terraform state as sensitive data.

Even if an output is marked:

```hcl
sensitive = true
```

that does not mean the underlying value is necessarily absent from state.

### Better approach

For application secrets, consider using services such as:

```text
AWS Secrets Manager
AWS Systems Manager Parameter Store
```

And protect the Terraform state itself using:

- encryption
- IAM
- S3 public-access blocking
- least privilege
- versioning

---

# 12. Protect the S3 Bucket

Your Terraform state bucket should never be public.

Example:

```hcl
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

This provides protection against common accidental public-access configurations.

---

# 13. Encrypt the State

Example:

```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

For more advanced environments, AWS KMS can be used for encryption-key management and stronger access controls.

---

# 14. IAM and State Access

Not every AWS user should be able to modify Terraform state.

Use IAM and follow the principle of least privilege.

A simple model:

```text
Developer
    │
    └── Appropriate state access

Jenkins
    │
    └── Appropriate state access

Unauthorized user
    │
    └── No state access
```

Avoid giving unrestricted administrator permissions just because Terraform is being used.

---

# 15. Problem #7 — Backend Bucket Does Not Exist

A common beginner mistake is writing:

```hcl
terraform {
  backend "s3" {
    bucket = "terraform-state"
  }
}
```

and then running:

```bash
terraform init
```

before the bucket exists.

Terraform can't use an S3 backend that hasn't been created.

### ✅ Solution: Bootstrap the Backend

Create the S3 state bucket separately.

For example:

```text
bootstrap/
├── main.tf
└── outputs.tf
```

The bootstrap configuration creates:

```text
S3 bucket
├── Versioning
├── Encryption
└── Public access block
```

Then the main infrastructure project uses that bucket.

---

# 16. Why Can't Terraform Create Its Own Backend?

It may seem logical to write:

```hcl
terraform {
  backend "s3" {
    bucket = aws_s3_bucket.terraform_state.id
  }
}
```

But this doesn't work.

Terraform initializes the backend before it creates normal resources.

The order is effectively:

```text
Backend must exist
        ↓
terraform init
        ↓
Terraform loads state
        ↓
Terraform plans resources
        ↓
Terraform creates resources
```

Therefore, the backend bucket normally needs to exist before Terraform can initialize against it.

---

# 17. Recommended Bootstrap Architecture

A clean approach is:

```text
terraform/
│
├── bootstrap/
│   ├── main.tf
│   └── outputs.tf
│
└── infrastructure/
    ├── backend.tf
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

The bootstrap project creates the state infrastructure.

The infrastructure project uses it.

---

# 18. Migrating Local State to S3

Suppose your project currently uses:

```text
terraform.tfstate
```

locally.

You then add:

```hcl
terraform {
  backend "s3" {
    bucket       = "my-terraform-state-bucket"
    key          = "dev/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

Run:

```bash
terraform init
```

Terraform detects that the backend configuration has changed.

If Terraform asks whether to migrate the existing state, confirm the migration when that is the intended operation.

The architecture changes from:

```text
Laptop
└── terraform.tfstate
```

to:

```text
Laptop
    │
    ▼
Terraform
    │
    ▼
S3
└── dev/terraform.tfstate
```

---

# 19. Verify the Migration

After migration, don't immediately assume everything is correct.

Run:

```bash
terraform state list
```

Then:

```bash
terraform plan
```

A healthy migration should not suddenly propose destroying and recreating your entire infrastructure.

If the plan looks unexpected, stop and investigate before applying.

---

# 20. Terraform State Commands

Terraform provides useful state commands for troubleshooting.

### List resources

```bash
terraform state list
```

Example:

```text
aws_vpc.main
aws_subnet.public["az1"]
aws_subnet.public["az2"]
```

---

### Inspect a resource

```bash
terraform state show aws_vpc.main
```

This is very useful when debugging resource IDs and attributes.

---

### Move a resource

```bash
terraform state mv \
  aws_instance.web \
  aws_instance.application
```

This changes the Terraform resource address in state.

---

### Remove a resource from state

```bash
terraform state rm aws_instance.web
```

⚠️ Important:

`terraform state rm` removes Terraform's tracking relationship.

It is **not the same thing as deleting the AWS resource**.

The AWS resource can remain running.

---

# 21. Problem #8 — AWS Resource Exists but Terraform Doesn't Manage It

Imagine someone manually creates:

```text
AWS Console
     │
     ▼
EC2
i-0123456789
```

Terraform doesn't automatically start managing that resource.

### ✅ Solution: `terraform import`

First define the resource:

```hcl
resource "aws_instance" "existing" {
  # configuration matching the existing instance
}
```

Then:

```bash
terraform import aws_instance.existing i-0123456789
```

Now Terraform knows that:

```text
aws_instance.existing
        ↓
i-0123456789
```

---

# 22. Important Import Detail

`terraform import` does not automatically create a complete `.tf` configuration for the resource.

You still need to make your Terraform configuration match the actual infrastructure.

After importing:

```bash
terraform plan
```

If Terraform proposes unexpected changes, compare:

```text
Terraform configuration
        vs
Imported resource
```

and update the configuration carefully.

---

# 23. What Happens If Someone Changes AWS Manually?

Terraform might manage:

```text
EC2
instance_type = t3.micro
```

Someone changes it manually in the AWS Console:

```text
t3.micro
    ↓
t3.small
```

Now the actual infrastructure differs from the Terraform configuration.

Run:

```bash
terraform plan
```

Terraform can detect that the infrastructure and desired configuration no longer match.

This is commonly referred to as **configuration drift**.

---

# 24. State vs Configuration vs Infrastructure

This distinction is extremely important.

### Terraform configuration

```text
*.tf
```

describes:

> What I want.

### Terraform state

```text
terraform.tfstate
```

describes:

> What Terraform knows and tracks.

### AWS

AWS contains:

> What actually exists.

Think of it like:

```text
        Terraform Code
        "What I want"
              │
              ▼
          Terraform
              │
       ┌──────┴──────┐
       │             │
       ▼             ▼
     State           AWS
"What I track"   "What exists"
```

Terraform compares these pieces to determine what changes are required.

---

# 25. Terraform State and Git

Your Git repository should contain your Terraform configuration:

```text
main.tf
variables.tf
outputs.tf
backend.tf
modules/
README.md
```

But don't commit:

```text
terraform.tfstate
terraform.tfstate.*
.terraform/
```

A useful `.gitignore` is:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
*.tfvars.json
crash.log
crash.*.log
```

If you need to share example variables, create:

```text
terraform.tfvars.example
```

and make sure it contains no real credentials.

---

# 26. Why `.terraform/` Shouldn't Be Committed

After:

```bash
terraform init
```

Terraform creates:

```text
.terraform/
```

This directory contains local Terraform working data, including downloaded providers and modules.

It should normally be excluded from Git:

```gitignore
.terraform/
```

Anyone cloning the repository can run:

```bash
terraform init
```

to recreate the required local working data.

---

# 27. Local State vs Remote State

| Feature | Local State | S3 Remote State |
|---|---|---|
| Easy to start | ✅ | Requires setup |
| Good for learning | ✅ | ✅ |
| Team collaboration | ❌ | ✅ |
| CI/CD | Risky | ✅ |
| Centralized state | ❌ | ✅ |
| Durable storage | Depends on machine | ✅ |
| Versioning | ❌ | ✅ with S3 versioning |
| State locking | Not suitable for shared workflows | ✅ |
| IAM access control | Limited | ✅ |
| Production use | Usually not preferred | ✅ |

---

# 28. Recommended Production Setup

For a production-style AWS Terraform project:

```text
                         AWS ACCOUNT
                              │
                ┌─────────────┴─────────────┐
                │                           │
                ▼                           ▼
         Terraform State              Infrastructure
              S3                           │
                │                           │
                ├── terraform.tfstate      │
                ├── Versioning              │
                ├── Encryption              │
                ├── Locking                 │
                └── IAM Controls            │
                                            │
                                            ▼
                                      AWS Resources
```

The state bucket should have:

- ✅ Versioning
- ✅ Encryption
- ✅ Public access blocked
- ✅ Least-privilege IAM
- ✅ State locking
- ✅ Appropriate backup/recovery controls

---

# 29. Jenkins + Terraform + Remote State

For a DevOps project, a typical workflow looks like:

```text
Developer
    │
    ▼
 GitHub
    │
    ▼
 Jenkins
    │
    ├── terraform fmt -check
    ├── terraform init
    ├── terraform validate
    ├── terraform plan
    │
    ▼
Approval
    │
    ▼
terraform apply
    │
    ▼
   AWS
```

The state stays centralized:

```text
                  S3
                   │
           terraform.tfstate
                   │
        ┌──────────┴──────────┐
        │                     │
     Jenkins              Developer
        │                     │
        └──────────┬──────────┘
                   ▼
                  AWS
```

This is much safer than storing the state only inside a Jenkins workspace.

---

# 30. Common Problems and Solutions

| Problem | Why it happens | Solution |
|---|---|---|
| State only exists on a laptop | Local backend | Use S3 remote state |
| Jenkins loses state | State stored in workspace | Use remote state |
| Two pipelines run together | No state locking | Enable S3 lockfile |
| State is accidentally overwritten | No version history | Enable S3 versioning |
| State is exposed publicly | Incorrect S3 permissions | Block public access |
| Sensitive values are exposed | State can contain sensitive data | Protect state and use Secrets Manager/SSM where appropriate |
| Backend initialization fails | Bucket doesn't exist | Bootstrap the backend first |
| Existing resource isn't managed | Resource was created manually | Use `terraform import` |
| Terraform wants to recreate everything | State/configuration mismatch | Inspect state and run `terraform plan` carefully |
| Terraform state was removed accidentally | Manual state operation | Restore/recover state or import the resource |

---

# 31. Best Practices

### 1. Use remote state for shared environments

For:

```text
dev
staging
prod
```

use centralized remote state.

### 2. Enable S3 versioning

This gives you historical versions of the state object.

### 3. Encrypt state

Treat state as sensitive infrastructure data.

### 4. Block public access

Terraform state should never be publicly accessible.

### 5. Use least-privilege IAM

Only the people and CI/CD roles that need state access should have it.

### 6. Use state locking

Avoid concurrent Terraform operations against the same state.

### 7. Never edit `terraform.tfstate` manually

Use Terraform state commands when state manipulation is required.

### 8. Don't commit state to Git

Use:

```gitignore
*.tfstate
*.tfstate.*
```

### 9. Keep application secrets outside Terraform where practical

Use:

```text
AWS Secrets Manager
AWS Systems Manager Parameter Store
```

for application secrets.

Remember that Terraform-managed secret values can still end up in state, so protecting state remains important.

### 10. Always review `terraform plan`

Especially before:

```bash
terraform apply
```

and always be extra careful with production infrastructure.

---

# 32. Recommended Project Structure

A larger Terraform project can use:

```text
terraform/
│
├── bootstrap/
│   ├── main.tf
│   └── outputs.tf
│
├── environments/
│   ├── dev/
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── prod/
│       ├── backend.tf
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── modules/
    ├── network/
    ├── compute/
    ├── database/
    └── load-balancer/
```

This gives a clean separation:

```text
Bootstrap
   │
   └── Creates remote state infrastructure

Environments
   │
   └── Defines environment-specific infrastructure

Modules
   │
   └── Provides reusable Terraform components
```

---

# 33. A Simple Mental Model

If you remember only one diagram from this lesson, remember this:

```text
                    GitHub
                       │
                       │ Terraform Code
                       ▼
                  ┌──────────┐
                  │ Terraform│
                  └────┬─────┘
                       │
              ┌────────┴────────┐
              │                 │
              ▼                 ▼
         Remote State         AWS API
              │                 │
              ▼                 ▼
              S3            Infrastructure
              │
      ┌───────┼────────┐
      │       │        │
  Versioning Encryption Locking
              │
              ▼
          IAM Access
```

Think of the three main pieces as:

> **Configuration = what I want**

> **State = what Terraform tracks**

> **AWS = what actually exists**

---

# 34. Quick Revision

### What is Terraform state?

A record Terraform uses to track the infrastructure it manages.

### Why use remote state?

To provide centralized, durable state for teams and CI/CD systems.

### Why use S3?

Because it integrates naturally with AWS and supports durable storage, IAM, encryption, versioning, and state locking.

### Why use state locking?

To prevent concurrent Terraform operations from modifying the same state at the same time.

### Why enable S3 versioning?

To retain previous state versions and provide an additional recovery mechanism.

### Should Terraform state be committed to Git?

**No.** It can contain sensitive infrastructure information and should be protected separately.

### What does `terraform import` do?

It associates an existing infrastructure resource with a Terraform resource in state.

### What does `terraform state rm` do?

It removes a resource from Terraform state. It is not the same as deleting the actual AWS resource.

---

# 35. Final Architecture

For the AWS DevOps projects I'm building with Terraform, the target architecture is:

```text
                          GitHub
                             │
                             ▼
                          Jenkins
                             │
                  ┌──────────┴──────────┐
                  │                     │
             Terraform                S3
                  │                     │
        ┌─────────┼─────────┐          │
        │         │         │          │
       fmt     validate    plan        │
        │         │         │          │
        └─────────┴────┬────┘          │
                       │               │
                       ▼               │
                  Approval             │
                       │               │
                       ▼               │
                 terraform apply       │
                       │               │
                       └───────┬───────┘
                               │
                               ▼
                         AWS Infrastructure

                         S3 State
                            │
                  ┌─────────┼─────────┐
                  │         │         │
              Versioning Encryption Locking
                            │
                            ▼
                       IAM Controls
```

This is the foundation for moving from a simple Terraform learning project to a **team-ready and CI/CD-friendly infrastructure setup**.

---

## 🚀 What's Next?

Now that remote state is understood, the next Terraform topic is **Lifecycle Rules & Advanced Resource Management**.

We'll cover:

```text
lifecycle
├── create_before_destroy
├── prevent_destroy
└── ignore_changes

depends_on

count vs for_each

resource replacement

dependency management
```

These concepts become especially useful when managing production resources such as:

- EC2
- ALB
- ASG
- RDS
- VPC
- Route 53

and will prepare us for building a complete production-style AWS infrastructure with Terraform.
