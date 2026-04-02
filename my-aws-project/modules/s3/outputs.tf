output "bucket_id" {
  description = "S3 Bucket ID"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "S3 Bucket ARN"
  value       = aws_s3_bucket.this.arn
}

output "bucket_name" {
  description = "S3 Bucket Name"
  value       = aws_s3_bucket.this.bucket
}
