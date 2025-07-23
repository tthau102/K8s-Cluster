# shared-backed/main.tf 



resource "random_id" "bucket_suffix" {
  byte_length = 4
}


module "tf_state_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "${local.name_prefix}-tf-state-${random_id.bucket_suffix.hex}"

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
      bucket_key_enabled = true
    }
  }

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  force_destroy = true

  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureConnections"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "arn:aws:s3:::${local.name_prefix}-tf-state-${random_id.bucket_suffix.hex}",
          "arn:aws:s3:::${local.name_prefix}-tf-state-${random_id.bucket_suffix.hex}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}


resource "aws_dynamodb_table" "tf_locks" {
  name         = "${local.name_prefix}-tf-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }
}











