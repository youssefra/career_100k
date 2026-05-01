variable "my_bucket_name" {
  description = "The name of our S3 bucket"
  type        = string
  default     = "separate-file-bucket-2026"
}

variable "file_content" {
  description = "The text inside our file"
  type        = string
  default     = "This content is now managed in a separate variables file!"
}
