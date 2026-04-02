output "instance_ids" {
  description = "List of EC2 instance IDs"
  value       = aws_instance.this[*].id
}

output "instance_public_ips" {
  description = "Public IPs of EC2 instances"
  value       = aws_instance.this[*].public_ip
}

output "instance_private_ips" {
  description = "Private IPs of EC2 instances"
  value       = aws_instance.this[*].private_ip
}

output "security_group_id" {
  description = "EC2 Security Group ID"
  value       = aws_security_group.this.id
}
