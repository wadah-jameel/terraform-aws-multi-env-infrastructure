
## ✏️ Step 2: GETTING_STARTED.md

> 💡 This is your **complete step-by-step guide**

```markdown
# 🚀 Getting Started Guide

Complete step-by-step guide to deploy this infrastructure on AWS.

---

## ✅ Prerequisites

Before you begin ensure you have:

- [ ] AWS Account with admin permissions
- [ ] AWS CLI installed and configured
- [ ] Terraform >= 1.5.0 installed
- [ ] Git installed

### Verify Prerequisites

```bash
# Check AWS CLI
aws --version
aws sts get-caller-identity

# Check Terraform
terraform --version

# Check Git
git --version
```

---

## 📥 Step 1 — Clone the Repository

```bash
git clone https://github.com/wadah-jameel/terraform-aws-multi-env-infrastructure.git

cd terraform-aws-multi-env-infrastructure
```

---

## 🪣 Step 2 — Create S3 Backend (Bootstrap)

> ⚠️ Must complete this BEFORE deploying main project

```bash
# Navigate to bootstrap folder
cd terraform-backend-setup

# Copy example vars
cp example.tfvars terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
aws_region          = "us-east-1"
state_bucket_name   = "yourcompany-terraform-state"
dynamodb_table_name = "terraform-state-lock"
```

```bash
# Initialize Terraform
terraform init

# Preview resources
terraform plan

# Create S3 bucket + DynamoDB table
terraform apply

# NOTE the output — you need the bucket name!
# state_bucket_name = "yourcompany-terraform-state-a1b2c3d4"
```

---

## ⚙️ Step 3 — Configure Backend

```bash
# Navigate to main project
cd ../my-aws-project

# Edit backend.tf with your bucket name from Step 2
nano backend.tf
```

Update `backend.tf`:
```hcl
terraform {
  backend "s3" {
    bucket         = "yourcompany-terraform-state-a1b2c3d4"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

---

## 🔧 Step 4 — Initialize Main Project

```bash
terraform init
```

Expected output:
```
Initializing the backend...
Successfully configured the backend "s3"!

Initializing modules...
- ec2 in modules/ec2
- s3 in modules/s3
- vpc in modules/vpc

Terraform has been successfully initialized!
```

---

## 🌍 Step 5 — Create Workspaces

```bash
# Create all three workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Verify workspaces created
terraform workspace list

# Expected output:
#   default
# * dev
#   staging
#   prod
```

---

## 🚀 Step 6 — Deploy Dev Environment

```bash
# Select dev workspace
terraform workspace select dev

# Preview changes
terraform plan -var-file="environments/dev.tfvars"

# Deploy
terraform apply -var-file="environments/dev.tfvars"

# View outputs
terraform output
```

---

## 🚀 Step 7 — Deploy Staging Environment

```bash
terraform workspace select staging
terraform plan  -var-file="environments/staging.tfvars"
terraform apply -var-file="environments/staging.tfvars"
terraform output
```

---

## 🚀 Step 8 — Deploy Prod Environment

```bash
terraform workspace select prod
terraform plan  -var-file="environments/prod.tfvars"
terraform apply -var-file="environments/prod.tfvars"
terraform output
```

---

## ✅ Step 9 — Verify Deployment

```bash
# Check state files in S3
aws s3 ls s3://your-bucket-name/ --recursive

# Expected:
# env:/dev/terraform.tfstate
# env:/staging/terraform.tfstate
# env:/prod/terraform.tfstate

# List resources per workspace
terraform workspace select dev
terraform state list

terraform workspace select prod
terraform state list
```

---

## 🗑️ Step 10 — Cleanup (When Done)

```bash
# Destroy dev first
terraform workspace select dev
terraform destroy -var-file="environments/dev.tfvars"

# Destroy staging
terraform workspace select staging
terraform destroy -var-file="environments/staging.tfvars"

# Destroy prod
terraform workspace select prod
terraform destroy -var-file="environments/prod.tfvars"
```

> ⚠️ Bootstrap resources (S3 + DynamoDB) have 
> `prevent_destroy = true`
> Remove lifecycle block before destroying bootstrap!

---

## 🔧 Troubleshooting

| Issue | Solution |
|-------|----------|
| Backend init fails | Verify S3 bucket exists and IAM permissions |
| State lock error | Check DynamoDB table exists with LockID key |
| AMI not found | Update ami_id in locals.tf for your region |
| Workspace not found | Run terraform workspace new <name> first |

---

## 📚 Next Steps

- 🏭 Set up CI/CD with GitHub Actions
- 🧪 Add Terratest automated testing
- 🔐 Integrate AWS Secrets Manager
```

---
- 🏭 **GitHub Actions** – Automate `terraform plan` on Pull Requests
- 📊 **GitHub Wiki** – Extended documentation hub
- 🔐 **GitHub Secrets** – Store AWS credentials for CI/CD
