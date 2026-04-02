aws_region          = "us-east-1"
state_bucket_name   = "mycompany-terraform-state"
dynamodb_table_name = "terraform-state-lock"
environment         = "shared"

tags = {
  Project   = "terraform-backend"
  ManagedBy = "Terraform"
  Owner     = "YourName"
}
