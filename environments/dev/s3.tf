# environments/dev/s3.tf

# =============================================================================
# S3 BUCKET FOR ALB ACCESS LOGS
# Centralized logging cho load balancer monitoring và troubleshooting
# =============================================================================

# Random suffix cho bucket name uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Bucket Module cho ALB access logs
# Mục đích: Store và retain ALB access logs cho security và performance analysis
module "alb_logs_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  # Bucket naming với random suffix
  bucket        = "${local.name_prefix}-alb-logs-${random_id.bucket_suffix.hex}"
  force_destroy = true # Allow deletion với objects (dev environment)

  # ELB service access permissions
  # attach_elb_log_delivery_policy: Cho phép ELB write logs
  # attach_lb_log_delivery_policy: Cho phép ALB write logs  
  attach_elb_log_delivery_policy = true
  attach_lb_log_delivery_policy  = true

  # Versioning configuration
  versioning = {
    status = "Enabled"
  }

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
      bucket_key_enabled = true
    }
  }

  # Public access block - security best practice
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Lifecycle configuration cho cost optimization
  lifecycle_rule = [
    {
      id     = "log_retention"
      status = "Enabled"

      # Filter để apply rule cho ALB logs
      filter = {
        prefix = "alb-access-logs/"
      }

      # Delete logs sau 30 ngày
      expiration = {
        days = var.access_logs_retention_days
      }

      # Delete old versions sau 7 ngày
      noncurrent_version_expiration = {
        noncurrent_days = 7
      }

      # Move to IA storage sau 30 ngày (cost optimization)
      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
    }
  ]

  tags = merge(local.tags, {
    Name      = "${local.name_prefix}-alb-logs"
    Component = "storage"
    Purpose   = "access-logs"
    Tier      = "logging"
  })
}
