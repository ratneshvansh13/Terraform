## What is the Terraform Lifecycle ?
```
Create 
Update
Destroy
```
---
#### Create_before_destroy
```
Old EC2
   ↓
DESTROY
   ↓
New EC2
   ↓
CREATE
```

```
lifecycle {
  create_before_destroy = true
}
```

