provider "aws" {
  region = "us-east-1"
  access_key = "test"
  secret_key = "test"
  skip_credentials_validation = true
  skip_metadata_api_check = true
  skip_requesting_account_id = true
  s3_use_path_style = true
  endpoints { s3 = "http://localhost:4566" }
}

resource "aws_s3_bucket" "app_storage" {
  bucket = var.my_bucket_name
}

resource "aws_s3_object" "data_file" {
  bucket  = aws_s3_bucket.app_storage.id
  key     = "info.txt"
  content = var.file_content
}
