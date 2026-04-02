variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "bucket_name" {
  description = "Base name for S3 bucket"
  type        = string
}

variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
