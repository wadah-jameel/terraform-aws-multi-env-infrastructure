# ─── WORKSPACE INFO ─────────────────────────────────────────
output "current_workspace" {
  description = "Active Terraform workspace"
  value       = terraform.workspace
}

output "environment_config" {
  description = "Active environment configuration"
  value = {
    environment    = local.env
    instance_type  = local.config.instance_type
    instance_count = local.config.instance_count
    vpc_cidr       = local.config.vpc_cidr
  }
}

# ─── VPC OUTPUTS ────────────────────────────────────────────
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = module.vpc.public_subnet_ids
}

# ─── EC2 OUTPUTS ────────────────────────────────────────────
output "web_server_public_ips" {
  description = "Web Server Public IPs"
  value       = module.ec2.instance_public_ips
}

output "web_server_ids" {
  description = "Web Server Instance IDs"
  value       = module.ec2.instance_ids
}

# ─── S3 OUTPUTS ─────────────────────────────────────────────
output "s3_bucket_name" {
  description = "S3 Bucket Name"
  value       = module.s3.bucket_name
}
