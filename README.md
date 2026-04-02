# terraform-aws-multi-env-infrastructure
Production-ready AWS infrastructure using Terraform modules, workspaces, and S3 remote state for dev/staging/prod environments

# 🏗️ Full Terraform Architecture

---

## 🗺️ The Big Picture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    COMPLETE TERRAFORM ARCHITECTURE                  │
│                                                                     │
│   👨‍💻 Developer                                                      │
│       │                                                             │
│       ▼                                                             │
│   Terraform Code                                                    │
│   ├── Bootstrap Project  ──▶  Creates Backend Infrastructure       │
│   └── Main Project                                                  │
│       ├── Root Module    ──▶  Orchestrates everything               │
│       ├── VPC Module     ──▶  Network Layer                        │
│       ├── EC2 Module     ──▶  Compute Layer                        │
│       └── S3 Module      ──▶  Storage Layer                        │
│               │                                                     │
│               ▼                                                     │
│       Workspaces                                                    │
│       ├── dev     ──▶  Small  infra  (t2.micro  / 1 instance)      │
│       ├── staging ──▶  Medium infra  (t2.small  / 2 instances)     │
│       └── prod    ──▶  Large  infra  (t2.large  / 4 instances)     │
│               │                                                     │
│               ▼                                                     │
│       S3 Backend                                                    │
│       ├── env:/dev/terraform.tfstate                                │
│       ├── env:/staging/terraform.tfstate                            │
│       └── env:/prod/terraform.tfstate                               │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📦 Layer 1 – Bootstrap Project

> **Purpose** → Creates the foundation that everything else depends on

```
┌─────────────────────────────────────────────────────────────────────┐
│                        BOOTSTRAP PROJECT                            │
│                                                                     │
│   terraform-backend-setup/                                          │
│   ├── main.tf           Creates S3 bucket + DynamoDB table         │
│   ├── variables.tf      Bucket name, region, table name            │
│   ├── outputs.tf        Outputs backend config to copy             │
│   └── terraform.tfvars  Your specific values                       │
│                                                                     │
│   Uses: LOCAL STATE  (intentional — bootstrapping)                  │
│                                                                     │
│   Creates:                                                          │
│   ┌─────────────────────┐   ┌──────────────────────────┐           │
│   │    S3 Bucket         │   │    DynamoDB Table         │           │
│   │  ✅ Versioning ON    │   │  HashKey  = "LockID"      │           │
│   │  ✅ Encryption ON    │   │  Billing  = PAY_PER_USE   │           │
│   │  ✅ Public Access OFF│   │  Purpose  = State Locking │           │
│   │  ✅ HTTPS Only       │   └──────────────────────────┘           │
│   └─────────────────────┘                                           │
└─────────────────────────────────────────────────────────────────────┘
```

### 🔑 Why Bootstrap Exists Separately?

```
The Chicken & Egg Problem:

❌ WRONG:  Use S3 backend to store state of the S3 bucket itself
             → S3 bucket doesn't exist yet when Terraform runs!

✅ RIGHT:  Use LOCAL state to create S3 bucket first
           Then point main project to that S3 bucket as backend
```

---

## 📦 Layer 2 – S3 Backend & State Management

> **Purpose** → Safely stores and locks Terraform state

```
┌─────────────────────────────────────────────────────────────────────┐
│                      S3 BACKEND LAYER                               │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────┐       │
│  │                    S3 BUCKET                             │       │
│  │                                                          │       │
│  │  env:/dev/terraform.tfstate      ← Dev environment       │       │
│  │  env:/staging/terraform.tfstate  ← Staging environment   │       │
│  │  env:/prod/terraform.tfstate     ← Prod environment      │       │
│  │                                                          │       │
│  │  Each tfstate file contains:                             │       │
│  │  ├── All resource IDs (vpc-xxx, i-xxx, sg-xxx)           │       │
│  │  ├── Resource attributes & metadata                      │       │
│  │  ├── Dependencies between resources                      │       │
│  │  └── Output values                                       │       │
│  └──────────────────────────────────────────────────────────┘       │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────┐       │
│  │                  DYNAMODB TABLE                          │       │
│  │                                                          │       │
│  │  When terraform apply runs:                              │       │
│  │  1️⃣  Terraform writes LockID to DynamoDB                 │       │
│  │  2️⃣  Other applies see lock → wait or fail               │       │
│  │  3️⃣  Apply completes → lock released from DynamoDB       │       │
│  │                                                          │       │
│  │  Prevents: Two people applying at the same time!        │       │
│  └──────────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────────┘
```

### 🔄 State File Lifecycle

```
terraform plan   →  Reads  state  (what exists now?)
terraform apply  →  Locks  state  (DynamoDB LockID written)
                 →  Updates state (new resources added)
                 →  Unlocks state (DynamoDB LockID deleted)
terraform destroy → Locks  state  (DynamoDB LockID written)
                  → Removes state (resources deleted)
                  → Unlocks state (DynamoDB LockID deleted)
```

---

## 📦 Layer 3 – Workspaces

> **Purpose** → Deploy same code to multiple environments with isolated state

```
┌─────────────────────────────────────────────────────────────────────┐
│                       WORKSPACE LAYER                               │
│                                                                     │
│  Same Terraform Code                                                │
│        │                                                            │
│        ├──▶ workspace: dev                                          │
│        │    ├── terraform.workspace = "dev"                         │
│        │    ├── Reads  local.env_config["dev"]                      │
│        │    ├── t2.micro / 1 instance / 10.0.0.0/16                 │
│        │    └── State: env:/dev/terraform.tfstate                   │
│        │                                                            │
│        ├──▶ workspace: staging                                      │
│        │    ├── terraform.workspace = "staging"                     │
│        │    ├── Reads  local.env_config["staging"]                  │
│        │    ├── t2.small / 2 instances / 10.1.0.0/16                │
│        │    └── State: env:/staging/terraform.tfstate               │
│        │                                                            │
│        └──▶ workspace: prod                                         │
│             ├── terraform.workspace = "prod"                        │
│             ├── Reads  local.env_config["prod"]                     │
│             ├── t2.large / 4 instances / 10.2.0.0/16               │
│             └── State: env:/prod/terraform.tfstate                  │
└─────────────────────────────────────────────────────────────────────┘
```

### 🔑 How locals.tf Drives Workspace Config

```
terraform.workspace          (built-in variable)
      │
      ▼
local.env = "dev"            (captured in locals.tf)
      │
      ▼
local.config = local.env_config["dev"]   (map lookup)
      │
      ▼
local.config.instance_type = "t2.micro"  (used in modules)
local.config.instance_count = 1
local.config.vpc_cidr = "10.0.0.0/16"
```

---

## 📦 Layer 4 – Root Module

> **Purpose** → Orchestrates all child modules and wires them together

```
┌─────────────────────────────────────────────────────────────────────┐
│                        ROOT MODULE                                  │
│                                                                     │
│   my-aws-project/                                                   │
│   │                                                                 │
│   ├── provider.tf    → Configures AWS provider + versions           │
│   ├── backend.tf     → Points to S3 bucket for state               │
│   ├── locals.tf      → Maps workspace → environment config         │
│   ├── variables.tf   → Declares input variables (region, env)      │
│   ├── main.tf        → Calls VPC, EC2, S3 modules                  │
│   ├── outputs.tf     → Exposes key values after apply              │
│   └── terraform.tfvars → Sets variable values                      │
│                                                                     │
│   Data Flow:                                                        │
│                                                                     │
│   terraform.tfvars                                                  │
│         │                                                           │
│         ▼                                                           │
│   variables.tf  +  locals.tf                                        │
│         │                 │                                         │
│         ▼                 ▼                                         │
│       main.tf  ──────────────────────────────────────              │
│       │           │              │              │                   │
│       ▼           ▼              ▼              ▼                   │
│   module.vpc  module.ec2    module.s3      outputs.tf              │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📦 Layer 5 – VPC Module

> **Purpose** → Creates the entire network layer

```
┌─────────────────────────────────────────────────────────────────────┐
│                         VPC MODULE                                  │
│                  modules/vpc/                                       │
│                                                                     │
│   INPUTS (variables.tf)          OUTPUTS (outputs.tf)               │
│   ├── environment                ├── vpc_id                         │
│   ├── vpc_cidr                   ├── vpc_cidr                       │
│   ├── public_subnet_cidrs        ├── public_subnet_ids              │
│   ├── private_subnet_cidrs       ├── private_subnet_ids             │
│   ├── availability_zones         └── internet_gateway_id            │
│   └── tags                                                          │
│                                                                     │
│   RESOURCES CREATED (main.tf)                                       │
│                                                                     │
│   aws_vpc                                                           │
│       │                                                             │
│       ├──▶ aws_internet_gateway                                     │
│       │         │                                                   │
│       │         └──▶ aws_route_table (public)                       │
│       │                   │                                         │
│       │                   └──▶ aws_route_table_association          │
│       │                                                             │
│       ├──▶ aws_subnet (public)  ×2  [us-east-1a, us-east-1b]       │
│       │                                                             │
│       └──▶ aws_subnet (private) ×2  [us-east-1a, us-east-1b]       │
│                                                                     │
│   Network Layout:                                                   │
│   VPC: 10.0.0.0/16 (dev)                                           │
│   ├── Public  Subnet 1: 10.0.1.0/24  (us-east-1a)                  │
│   ├── Public  Subnet 2: 10.0.2.0/24  (us-east-1b)                  │
│   ├── Private Subnet 1: 10.0.10.0/24 (us-east-1a)                  │
│   └── Private Subnet 2: 10.0.11.0/24 (us-east-1b)                  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📦 Layer 6 – EC2 Module

> **Purpose** → Creates compute layer inside the VPC

```
┌─────────────────────────────────────────────────────────────────────┐
│                         EC2 MODULE                                  │
│                  modules/ec2/                                       │
│                                                                     │
│   INPUTS (variables.tf)          OUTPUTS (outputs.tf)               │
│   ├── environment                ├── instance_ids                   │
│   ├── instance_type              ├── instance_public_ips            │
│   ├── ami_id                     ├── instance_private_ips           │
│   ├── instance_count             └── security_group_id              │
│   ├── subnet_ids  ◀── from VPC module output                        │
│   ├── vpc_id      ◀── from VPC module output                        │
│   └── tags                                                          │
│                                                                     │
│   RESOURCES CREATED (main.tf)                                       │
│                                                                     │
│   aws_security_group                                                │
│   ├── Inbound:  port 80  (HTTP)                                     │
│   ├── Inbound:  port 443 (HTTPS)                                    │
│   └── Outbound: all traffic                                         │
│         │                                                           │
│         └──▶ aws_instance ×N  (N = instance_count from locals)     │
│               ├── Distributed across public subnets                 │
│               ├── Attached to security group                        │
│               └── User data installs Apache httpd                   │
│                                                                     │
│   Per Environment:                                                  │
│   dev     → 1  instance (t2.micro)                                  │
│   staging → 2  instances (t2.small)                                 │
│   prod    → 4  instances (t2.large)                                 │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📦 Layer 7 – S3 Module

> **Purpose** → Creates application storage layer

```
┌─────────────────────────────────────────────────────────────────────┐
│                          S3 MODULE                                  │
│                   modules/s3/                                       │
│                                                                     │
│   INPUTS (variables.tf)          OUTPUTS (outputs.tf)               │
│   ├── environment                ├── bucket_id                      │
│   ├── bucket_name                ├── bucket_arn                     │
│   ├── enable_versioning          └── bucket_name                    │
│   └── tags                                                          │
│                                                                     │
│   RESOURCES CREATED (main.tf)                                       │
│                                                                     │
│   random_id (suffix)                                                │
│         │                                                           │
│         ▼                                                           │
│   aws_s3_bucket                                                     │
│   ├── aws_s3_bucket_versioning                                      │
│   │   └── Enabled in staging + prod                                 │
│   │   └── Disabled in dev                                           │
│   ├── aws_s3_bucket_server_side_encryption_configuration            │
│   │   └── AES256 encryption always on                               │
│   └── aws_s3_bucket_public_access_block                             │
│       └── All public access blocked                                 │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🔗 How All Layers Connect

```
┌─────────────────────────────────────────────────────────────────────┐
│                    COMPLETE DATA FLOW                               │
│                                                                     │
│  1️⃣  Developer runs:                                                │
│      terraform workspace select dev                                 │
│      terraform apply -var-file="environments/dev.tfvars"            │
│                │                                                    │
│                ▼                                                    │
│  2️⃣  Terraform reads backend.tf                                     │
│      → Connects to S3 bucket                                        │
│      → Reads env:/dev/terraform.tfstate                             │
│      → Writes LockID to DynamoDB                                    │
│                │                                                    │
│                ▼                                                    │
│  3️⃣  Terraform evaluates locals.tf                                  │
│      → terraform.workspace = "dev"                                  │
│      → local.config = env_config["dev"]                             │
│      → instance_type = "t2.micro"                                   │
│                │                                                    │
│                ▼                                                    │
│  4️⃣  Root main.tf calls modules                                     │
│      → module.vpc   gets local.config values                        │
│      → module.ec2   gets module.vpc outputs                         │
│      → module.s3    gets local.config values                        │
│                │                                                    │
│                ▼                                                    │
│  5️⃣  AWS Resources created in order                                 │
│      → VPC + Subnets + IGW + Route Tables                           │
│      → Security Group + EC2 Instances                               │
│      → S3 Bucket + Versioning + Encryption                          │
│                │                                                    │
│                ▼                                                    │
│  6️⃣  State updated + Lock released                                  │
│      → env:/dev/terraform.tfstate updated in S3                     │
│      → LockID removed from DynamoDB                                 │
│      → Outputs displayed to developer                               │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Complete File Reference

| File | Location | Purpose |
|---|---|---|
| `main.tf` | `bootstrap/` | Creates S3 + DynamoDB |
| `backend.tf` | `my-aws-project/` | Configures S3 backend |
| `locals.tf` | `my-aws-project/` | Workspace → env config map |
| `provider.tf` | `my-aws-project/` | AWS provider setup |
| `variables.tf` | `my-aws-project/` | Root variable declarations |
| `main.tf` | `my-aws-project/` | Calls all modules |
| `outputs.tf` | `my-aws-project/` | Exposes key values |
| `terraform.tfvars` | `my-aws-project/` | Variable values |
| `dev.tfvars` | `environments/` | Dev specific values |
| `staging.tfvars` | `environments/` | Staging specific values |
| `prod.tfvars` | `environments/` | Prod specific values |
| `main.tf` | `modules/vpc/` | VPC resources |
| `main.tf` | `modules/ec2/` | EC2 resources |
| `main.tf` | `modules/s3/` | S3 resources |

---

## 🔒 Security Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                      SECURITY LAYERS                                │
│                                                                     │
│  State Security                                                     │
│  ├── S3 bucket encryption      (AES256)                             │
│  ├── S3 versioning             (recovery from bad state)            │
│  ├── S3 HTTPS only policy      (no plain HTTP)                      │
│  ├── S3 public access blocked  (no public reads)                    │
│  └── DynamoDB state locking    (no concurrent applies)              │
│                                                                     │
│  Infrastructure Security                                            │
│  ├── Security groups           (least privilege ports)              │
│  ├── Private subnets           (EC2 not publicly exposed)           │
│  ├── S3 app bucket encrypted   (AES256)                             │
│  └── S3 app bucket private     (no public access)                   │
│                                                                     │
│  IAM Security                                                       │
│  ├── S3 state access policy    (get/put/delete/list)                │
│  └── DynamoDB lock policy      (get/put/delete/describe)            │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Environment Comparison

| Component | Dev | Staging | Prod |
|---|---|---|---|
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| Public Subnets | 2 | 2 | 2 |
| Private Subnets | 2 | 2 | 2 |
| Instance Type | t2.micro | t2.small | t2.large |
| Instance Count | 1 | 2 | 4 |
| S3 Versioning | ❌ | ✅ | ✅ |
| State Path | env:/dev/ | env:/staging/ | env:/prod/ |
| State Lock | ✅ | ✅ | ✅ |
| Encryption | ✅ | ✅ | ✅ |

---

## 🎯 Key Architecture Principles Applied

> 🔁 **DRY** → Don't Repeat Yourself — one codebase, three environments
>
> 🔒 **Isolation** → Each workspace has completely separate state
>
> 🧩 **Modularity** → VPC, EC2, S3 are independent reusable modules
>
> 📈 **Scalability** → Add new environment by adding to locals.tf map
>
> 🔐 **Security** → State encrypted, locked, private at every layer
>
> 💰 **Cost Aware** → Smaller resources in dev, full power in prod

---
