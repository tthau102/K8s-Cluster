# backend/main.tf
provider "aws" {
  region = var.region
  default_tags {
    tags = local.tags
  }
}

resource "aws_s3_bucket" "tf_state" {
  bucket        = "${var.project}-tf-state"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "tf_locks" {
  name         = "${var.project}-tf-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}
