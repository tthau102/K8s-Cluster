# modules/alb/main.tf

# S3 Bucket for ALB Access Logs
resource "aws_s3_bucket" "alb_logs" {
  bucket        = "${local.name_prefix}-alb-logs-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = merge(var.additional_tags, {
    Name      = "${local.name_prefix}-alb-logs"
    Component = "load-balancer"
    Purpose   = "access-logs"
  })
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Bucket Policy for ALB Access Logs
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.current.id}:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.alb_logs.arn
      }
    ]
  })
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# S3 Bucket Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "log_retention"
    status = "Enabled"

    expiration {
      days = var.access_logs_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = true
  enable_http2                     = true
  enable_waf_fail_open             = false

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "alb-access-logs"
    enabled = var.enable_access_logs
  }

  tags = merge(var.additional_tags, {
    Name      = "${local.name_prefix}-alb"
    Component = "load-balancer"
    Type      = "application"
  })
}

# Default Target Group (for health checks)
resource "aws_lb_target_group" "default" {
  name     = "${local.name_prefix}-default-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = merge(var.additional_tags, {
    Name      = "${local.name_prefix}-default-tg"
    Component = "load-balancer"
    Purpose   = "default"
  })
}

# HTTP Listener (redirect to HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(var.additional_tags, {
    Name = "${local.name_prefix}-http-listener"
  })
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  count             = var.ssl_certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default.arn
  }

  tags = merge(var.additional_tags, {
    Name = "${local.name_prefix}-https-listener"
  })
}

# K8s Ingress Target Group
resource "aws_lb_target_group" "k8s_ingress" {
  name     = "${local.name_prefix}-k8s-ingress-tg"
  port     = 30080 # NodePort for ingress controller
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/healthz"
    matcher             = "200"
    port                = "30080"
    protocol            = "HTTP"
  }

  tags = merge(var.additional_tags, {
    Name      = "${local.name_prefix}-k8s-ingress-tg"
    Component = "load-balancer"
    Purpose   = "k8s-ingress"
  })
}

# Attach worker nodes to K8s Ingress Target Group
resource "aws_lb_target_group_attachment" "k8s_ingress" {
  count            = length(var.worker_instance_ids)
  target_group_arn = aws_lb_target_group.k8s_ingress.arn
  target_id        = var.worker_instance_ids[count.index]
  port             = 30080
}

# Listener Rule for K8s Ingress (when using HTTPS)
resource "aws_lb_listener_rule" "k8s_ingress" {
  count        = var.ssl_certificate_arn != null ? 1 : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_ingress.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  tags = merge(var.additional_tags, {
    Name = "${local.name_prefix}-k8s-ingress-rule"
  })
}

# Additional Target Group for API Server (if needed)
resource "aws_lb_target_group" "k8s_api" {
  count    = var.expose_api_server ? 1 : 0
  name     = "${local.name_prefix}-k8s-api-tg"
  port     = 6443
  protocol = "HTTPS"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/healthz"
    matcher             = "200"
    port                = "6443"
    protocol            = "HTTPS"
  }

  tags = merge(var.additional_tags, {
    Name      = "${local.name_prefix}-k8s-api-tg"
    Component = "load-balancer"
    Purpose   = "k8s-api"
  })
}

# Attach master nodes to API Target Group
resource "aws_lb_target_group_attachment" "k8s_api" {
  count            = var.expose_api_server ? length(var.master_instance_ids) : 0
  target_group_arn = aws_lb_target_group.k8s_api[0].arn
  target_id        = var.master_instance_ids[count.index]
  port             = 6443
}

# Data sources
data "aws_elb_service_account" "current" {}

data "aws_region" "current" {}
