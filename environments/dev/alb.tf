# environments/dev/alb.tf

# =============================================================================
# APPLICATION LOAD BALANCER
# Internet-facing load balancer cho K8s ingress traffic
# =============================================================================

# Application Load Balancer
# Mục đích: Entry point cho web traffic đến K8s cluster
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name = "${local.name_prefix}-alb"

  # ALB configuration
  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets # Public subnets cho internet access
  security_groups    = [module.alb_sg.security_group_id]

  # Deletion protection - disable trong dev environment
  enable_deletion_protection = var.enable_deletion_protection

  # Access logs configuration
  access_logs = {
    bucket  = module.alb_logs_bucket.s3_bucket_id
    prefix  = "alb-access-logs"
    enabled = true # Enable cho monitoring và troubleshooting
  }

  # Target Groups cho K8s services
  target_groups = [
    {
      name     = "${local.name_prefix}-k8s-ingress-tg"
      port     = 30080 # NodePort cho ingress controller
      protocol = "HTTP"

      # Health check configuration
      health_check = {
        enabled             = true
        healthy_threshold   = 2          # 2 consecutive success
        unhealthy_threshold = 3          # 3 consecutive failures
        timeout             = 5          # 5 seconds timeout
        interval            = 30         # Check every 30 seconds
        path                = "/healthz" # Health check endpoint
        port                = "30080"
        protocol            = "HTTP"
        matcher             = "200" # Expected response code
      }

      # Target registration - worker nodes
      targets = {
        for i, instance in module.k8s_workers : "worker-${i}" => {
          target_id = instance.id
          port      = 30080
        }
      }
    }
  ]

}

# HTTP Listener - redirect to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = module.alb.arn
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

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-http-listener"
  })
}

# HTTPS Listener - conditional on SSL certificate
resource "aws_lb_listener" "https" {
  count             = var.ssl_certificate_arn != null ? 1 : 0
  load_balancer_arn = module.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = module.alb.target_groups["k8s_ingress"].arn
  }

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-https-listener"
  })
}
