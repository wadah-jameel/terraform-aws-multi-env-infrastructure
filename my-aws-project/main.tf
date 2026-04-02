# ─── VPC MODULE ─────────────────────────────────────────────
module "vpc" {
  source = "./modules/vpc"

  environment          = local.env                              # ← From workspace
  vpc_cidr             = local.config.vpc_cidr                  # ← From locals
  public_subnet_cidrs  = local.config.public_subnet_cidrs       # ← From locals
  private_subnet_cidrs = local.config.private_subnet_cidrs      # ← From locals
  availability_zones   = local.config.availability_zones        # ← From locals
  tags                 = local.config.tags                      # ← From locals
}

# ─── EC2 MODULE ─────────────────────────────────────────────
module "ec2" {
  source = "./modules/ec2"

  environment    = local.env                                    # ← From workspace
  instance_type  = local.config.instance_type                   # ← From locals
  ami_id         = local.config.ami_id                          # ← From locals
  instance_count = local.config.instance_count                  # ← From locals
  subnet_ids     = module.vpc.public_subnet_ids                 # ← From VPC module
  vpc_id         = module.vpc.vpc_id                            # ← From VPC module
  tags           = local.config.tags                            # ← From locals
}

# ─── S3 MODULE ──────────────────────────────────────────────
module "s3" {
  source = "./modules/s3"

  environment       = local.env                                 # ← From workspace
  bucket_name       = "app-assets"
  enable_versioning = local.config.enable_versioning            # ← From locals
  tags              = local.config.tags                         # ← From locals
}
