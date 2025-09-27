variable "domain_name" {
  description = "Custom domain for the site (e.g. www.example.com)"
  type        = string
  default     = "torotech.dev"
}

variable "s3_bucket" {
  description = "The name of the existing S3 bucket"
  type        = string
  default     = "torotech.dev"
}
