terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"

  # ✅ Uses LOCAL state intentionally — this IS the bootstrap!
  # No backend block here
}

provider "aws" {
  region = var.aws_region
}

# ─── RANDOM SUFFIX ──────────────────────────────────────────
# Ensures globally unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# ─── S3 BUCKET ──────────────────────────────────────────────
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.state_bucket_name}-${random_id.bucket_suffix.hex}"

  # Prevent accidental deletion of state bucket!
  lifecycle {
    prevent_destroy = true
  }

  tags = merge(var.tags, {
    Name        = "Terraform State Bucket"
    Environment = var.environment
  })
}

# ─── S3 VERSIONING ──────────────────────────────────────────
# Keeps history of all state changes — critical for recovery!
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"       # ← ALWAYS enable for state bucket
  }
}

# ─── S3 ENCRYPTION ──────────────────────────────────────────
# Encrypts state files at rest — state contains sensitive data!
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"     # or "aws:kms" for KMS encryption
    }
    bucket_key_enabled = true
  }
}

# ─── BLOCK ALL PUBLIC ACCESS ────────────────────────────────
# State files MUST be private — they contain secrets!
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ─── S3 BUCKET POLICY ───────────────────────────────────────
# Only allow access via HTTPS — not HTTP
resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  # Must wait for public access block first
  depends_on = [aws_s3_bucket_public_access_block.terraform_state]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceHTTPS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# ─── DYNAMODB TABLE ─────────────────────────────────────────
# Handles state locking — prevents simultaneous applies!
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"   # No capacity planning needed
  hash_key     = "LockID"            # ← Required exact name for Terraform

  attribute {
    name = "LockID"                  # ← Must be exactly "LockID"
    type = "S"                       # S = String
  }

  # Protect lock table from accidental deletion
  lifecycle {
    prevent_destroy = true
  }

  tags = merge(var.tags, {
    Name        = "Terraform State Lock Table"
    Environment = var.environment
  })
}
