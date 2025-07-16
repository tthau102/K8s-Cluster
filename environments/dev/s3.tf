# environments/dev/s3.tf

# =============================================================================
# S3 BUCKET FOR ALB ACCESS LOGS
# Store ALB access logs cho monitoring và troubleshooting
# =============================================================================

# S3 Bucket for ALB Access Logs
module "alb_logs_s3" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket = "${local.name_prefix}-alb-logs-${random_id.bucket_suffix.hex}"

  # Versioning
  versioning = {
    enabled = false # Không cần versioning cho logs
  }

  # Lifecycle configuration để tiết kiệm cost
  lifecycle_rule = [
    {
      id     = "alb_logs_lifecycle"
      status = "Enabled"

      # Transition to IA after 30 days
      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        }
      ]

      # Delete after retention period (must be > 30 days)
      expiration = {
        days = max(var.access_logs_retention_days, 31)
      }
    }
  ]

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
      bucket_key_enabled = true
    }
  }

  # Block all public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = merge(local.tags, {
    Name      = "${local.name_prefix}-alb-logs"
    Component = "storage"
    Type      = "logging"
    Purpose   = "alb-access-logs"
  })
}

# Bucket policy cho ALB service account
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = module.alb_logs_s3.s3_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ELBAccessLogsWrite"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::754344448648:root"
        }
        Action   = "s3:PutObject"
        Resource = "${module.alb_logs_s3.s3_bucket_arn}/alb-access-logs/*"
      },
      {
        Sid    = "ELBAccessLogsAclCheck"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::754344448648:root"
        }
        Action   = "s3:GetBucketAcl"
        Resource = module.alb_logs_s3.s3_bucket_arn
      }
    ]
  })

  depends_on = [module.alb_logs_s3]
}
