variable "aws_region" {
  description = "AWS region for backend resources"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Name of S3 bucket for Terraform state"
  type        = string
  default     = "my-terraform-state-bucket"
  # ⚠️ S3 bucket names must be GLOBALLY unique!
  # Recommend: "mycompany-terraform-state-123456"
}

variable "dynamodb_table_name" {
  description = "Name of DynamoDB table for state locking"
  type        = string
  default     = "terraform-state-lock"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "shared"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    Project   = "terraform-backend"
    ManagedBy = "Terraform"
  }
}
