locals {
  # Current workspace name
  env = terraform.workspace

  # ─── ENVIRONMENT CONFIGURATIONS ─────────────────────────
  env_config = {
    dev = {
      # Networking
      vpc_cidr             = "10.0.0.0/16"
      public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
      private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
      availability_zones   = ["us-east-1a", "us-east-1b"]

      # Compute
      instance_type  = "t2.micro"     # Smallest — save cost
      instance_count = 1
      ami_id         = "ami-0c02fb55956c7d316"

      # Storage
      enable_versioning = false        # Not needed in dev

      # Tags
      tags = {
        Environment = "dev"
        CostCenter  = "engineering"
        Project     = "terraform-learning"
        ManagedBy   = "Terraform"
      }
    }

    staging = {
      # Networking
      vpc_cidr             = "10.1.0.0/16"   # Different CIDR!
      public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
      private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24"]
      availability_zones   = ["us-east-1a", "us-east-1b"]

      # Compute
      instance_type  = "t2.small"     # Medium size
      instance_count = 2
      ami_id         = "ami-0c02fb55956c7d316"

      # Storage
      enable_versioning = true

      # Tags
      tags = {
        Environment = "staging"
        CostCenter  = "engineering"
        Project     = "terraform-learning"
        ManagedBy   = "Terraform"
      }
    }

    prod = {
      # Networking
      vpc_cidr             = "10.2.0.0/16"   # Different CIDR!
      public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24"]
      private_subnet_cidrs = ["10.2.10.0/24", "10.2.11.0/24"]
      availability_zones   = ["us-east-1a", "us-east-1b"]

      # Compute
      instance_type  = "t2.large"     # Largest — full power
      instance_count = 4
      ami_id         = "ami-0c02fb55956c7d316"

      # Storage
      enable_versioning = true

      # Tags
      tags = {
        Environment = "prod"
        CostCenter  = "operations"
        Project     = "terraform-learning"
        ManagedBy   = "Terraform"
      }
    }
  }

  # ─── ACTIVE CONFIG ──────────────────────────────────────
  # Pulls the right config based on current workspace
  config = local.env_config[local.env]
}
