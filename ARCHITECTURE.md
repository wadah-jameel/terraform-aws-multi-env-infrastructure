## ✏️ ARCHITECTURE.md

```markdown
# 🏗️ Architecture Documentation

## Overview
Full architecture explanation of the infrastructure layers...

## Layer 1 — Bootstrap
## Layer 2 — S3 Backend & State
## Layer 3 — Workspaces
## Layer 4 — Root Module
## Layer 5 — VPC Module
## Layer 6 — EC2 Module
## Layer 7 — S3 Module
## Security Architecture
## Data Flow

```
Developer → Terraform Code → Workspaces → S3 Backend
                │
                ├── VPC Module    (Network Layer)
                ├── EC2 Module    (Compute Layer)
                └── S3  Module    (Storage Layer)
```

---

## 📦 Modules

| Module | Description | Resources |
|--------|-------------|-----------|
| `vpc`  | Network layer | VPC, Subnets, IGW, Route Tables |
| `ec2`  | Compute layer | EC2 Instances, Security Groups |
| `s3`   | Storage layer | S3 Bucket, Encryption, Versioning |

---

## 🌍 Environments

| Setting        | Dev        | Staging    | Prod       |
|----------------|------------|------------|------------|
| VPC CIDR       | 10.0.0.0/16| 10.1.0.0/16| 10.2.0.0/16|
| Instance Type  | t2.micro   | t2.small   | t2.large   |
| Instance Count | 1          | 2          | 4          |
| S3 Versioning  | ❌         | ✅         | ✅         |

---
