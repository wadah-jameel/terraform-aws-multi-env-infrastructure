# my-aws-project/backend.tf

terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state-a1b2c3d4"  # ← From output
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"                 # ← From output
    encrypt        = true
  }
}
